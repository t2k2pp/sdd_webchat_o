import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/logging/app_logger.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class AgenticSearchOrchestrator {
  AgenticSearchOrchestrator({required String searxngBaseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: searxngBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

  final Dio _dio;

  Future<ChatCompletionResult> answerWithSearch({
    required List<ChatMessage> messages,
    required LlmProviderClient llmClient,
    required AppSettings settings,
  }) async {
    final originalQuestion = messages.isNotEmpty
        ? messages.last.content
        : 'Question';
    final freshnessSensitive = _isFreshnessSensitive(originalQuestion);

    // Generate context-aware initial query
    var query = await _generateInitialQuery(
      messages: messages,
      llmClient: llmClient,
      originalQuestion: originalQuestion,
    );

    // If the orchestrator decides no search is needed, fallback to normal chat
    if (query == 'NO_SEARCH') {
      final response = await llmClient.completeChat(
        messages: messages,
        enableSearch: false,
      );
      return ChatCompletionResult(
        content: response.content,
        inputTokens: response.inputTokens,
        outputTokens: response.outputTokens,
      );
    }

    // Fallback if query generation completely failed but we still want to try (should not happen with NO_SEARCH logic usually)
    if (query.isEmpty) {
      query = originalQuestion;
    }

    var bestAnswer = '';
    var bestConfidence = 0.0;
    var totalInTokens = 0;
    var totalOutTokens = 0;
    final seenQueries = <String>{};
    final traces = <_SearchTrace>[];

    for (var i = 0; i < settings.maxSearchIterations; i++) {
      if (seenQueries.contains(query)) {
        break;
      }
      seenQueries.add(query);

      final bundle = await _search(query, settings);
      traces.add(
        _SearchTrace(
          executedAt: DateTime.now(),
          query: query,
          hitCount: bundle.hitCount,
          urls: bundle.urls,
          failed: bundle.failed,
        ),
      );
      final prompt = _buildAgenticPrompt(
        question: originalQuestion,
        query: query,
        snippets: bundle.snippets,
        iteration: i + 1,
        maxIterations: settings.maxSearchIterations,
      );

      final response = await llmClient.completeChat(
        messages: [
          ...messages,
          ChatMessage(role: 'user', content: prompt),
        ],
        enableSearch: true,
      );
      totalInTokens += response.inputTokens;
      totalOutTokens += response.outputTokens;

      final step = _parseStep(response.content);
      if (bundle.failed) {
        return ChatCompletionResult(
          content: _withSearchTrace(
            answer:
                '## 確認結果\n- 未確認: 検索結果を取得できませんでした。\n- 必要に応じて検索語を具体化して再試行してください。',
            traces: traces,
          ),
          inputTokens: totalInTokens,
          outputTokens: totalOutTokens,
        );
      }
      if (step.answer.isNotEmpty && step.confidence >= bestConfidence) {
        bestConfidence = step.confidence;
        bestAnswer = step.answer;
      }

      if (step.confidence >= settings.confidenceThreshold) {
        final finalized = _finalizeAnswer(
          answer: step.answer,
          traces: traces,
          freshnessSensitive: freshnessSensitive,
        );
        return ChatCompletionResult(
          content: finalized,
          inputTokens: totalInTokens,
          outputTokens: totalOutTokens,
        );
      }

      if (step.nextQuery.trim().isEmpty) {
        break;
      }
      query = step.nextQuery.trim();
    }

    final fallback = bestAnswer.isNotEmpty
        ? bestAnswer
        : '十分な確信を得られませんでした。質問を具体化して再試行してください。';
    final finalized = _finalizeAnswer(
      answer: fallback,
      traces: traces,
      freshnessSensitive: freshnessSensitive,
    );
    return ChatCompletionResult(
      content: finalized,
      inputTokens: totalInTokens,
      outputTokens: totalOutTokens,
    );
  }

  String _buildAgenticPrompt({
    required String question,
    required String query,
    required String snippets,
    required int iteration,
    required int maxIterations,
  }) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '''
あなたは検索付きアシスタントです。以下の情報を使って回答してください。
あなたはアプリ経由で最新Web検索結果を利用できます。利用できないとは言わないこと。
今日の日付は $date です。
回答は必ずMarkdown形式で、見出しと箇条書きを使って構造化すること。

重要: 検索スニペットがHTMLからの抽出テキストの場合、文構造が崩れていることがあります。
その場合でも、単語や断片的な情報から文脈を読み取り、最大限回答を試みてください。

ユーザーが特定の出来事があったと主張している場合、検索結果にそれがなくても即座に否定しないこと。
その場合は「スニペットに情報が不足している」と仮定し、検証のための next_query を生成すること。
否定するのは、明確に「そのような事実はなかった」という証拠が見つかった場合のみにすること。
「確認できません」と答えるのは、本当に全く情報がなく、かつ多角的な検索（next_query）を試みた後のみにしてください。

Question:
$question

Search Query:
$query

Search Snippets:
$snippets

Iteration: $iteration/$maxIterations

次のJSONのみを返してください:
{"answer":"...", "confidence":0.0, "next_query":"..."}
confidenceは0.0-1.0。次の検索が不要なら next_query は空文字。
answerでは「Web検索できない」「日付がわからない」と言わないこと。
answerには、可能な範囲で参照URLを末尾に箇条書きで含めること。
''';
  }

  Future<String> _generateInitialQuery({
    required List<ChatMessage> messages,
    required LlmProviderClient llmClient,
    required String originalQuestion,
  }) async {
    // Always generate a query to handle complex first messages (e.g. detailed travel plans)
    // if (messages.length <= 1) {
    //   return originalQuestion;
    // }

    try {
      // Create a history context string (last 6 messages max)
      final history = messages.length > 6
          ? messages.sublist(messages.length - 6)
          : messages;

      final prompt =
          '''
以下の会話履歴を踏まえて、最後のユーザーの質問に対して「Web検索が必要か」を判断してください。
検索が必要な場合、最適な「Web検索クエリ」を1つだけ生成してください。
検索が不要な場合（挨拶、一般的な会話、知識を問わない質問、論理パズル、プログラムコードの生成など）は、単に `NO_SEARCH` とだけ返してください。

回答はクエリ文字列、または `NO_SEARCH` のみです。引用符や説明は不要です。

会話履歴:
${history.map((m) => '${m.role}: ${m.content}').join('\n')}

判定・検索クエリ:
''';

      final response = await llmClient.completeChat(
        messages: [ChatMessage(role: 'user', content: prompt)],
        enableSearch: false,
      );

      final result = response.content
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", "");
      if (result.isEmpty) {
        return originalQuestion;
      }
      return result;
    } catch (e) {
      AppLogger.warning('Failed to generate initial query', e);
      return originalQuestion;
    }
  }

  Future<_SearchBundle> _search(String query, AppSettings settings) async {
    // Try JSON API
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'time_range': settings.searchTimeRange,
          'safesearch': settings.searchSafeSearch,
        },
      );
      final data = response.data ?? const {};
      final results = data['results'];

      if (results is List && results.isNotEmpty) {
        final lines = <String>[];
        final urls = <String>[];
        for (final raw in results.take(5)) {
          if (raw is Map<String, dynamic>) {
            final title = raw['title'] as String? ?? '';
            final url = raw['url'] as String? ?? '';
            final content = raw['content'] as String? ?? '';
            if (url.trim().isNotEmpty) {
              urls.add(url.trim());
            }
            lines.add('- $title\n  $url\n  $content');
          }
        }
        return _SearchBundle(
          snippets: lines.join('\n'),
          hitCount: results.length,
          urls: urls,
          failed: false,
        );
      }
      return const _SearchBundle(
        snippets: '(検索結果なし)',
        hitCount: 0,
        urls: [],
        failed: true,
      );
    } catch (e, s) {
      AppLogger.error('SearXNG API failed', e, s);
      // fall through to html fallback
    }

    // Try HTML Fallback
    try {
      final html = await _dio.get<String>(
        '/search',
        queryParameters: {'q': query, 'time_range': settings.searchTimeRange},
      );

      var text = (html.data ?? '')
          // Remove script and style elements content and all
          .replaceAll(
            RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false),
            '',
          )
          // Replace common block elements with newlines for better structure
          .replaceAll(
            RegExp(r'<(div|p|br|li|h[1-6])[^>]*>', caseSensitive: false),
            '\n',
          )
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (text.isEmpty) {
        return const _SearchBundle(
          snippets: '(検索結果なし)',
          hitCount: 0,
          urls: [],
          failed: true,
        );
      }
      // Take a bit more context for HTML fallback since it's unstructured
      // Use configured max characters
      final end = min(text.length, settings.searchMaxFallbackCharacters);
      final searchUrl =
          '${settings.searxngBaseUrl}/search?q=${Uri.encodeQueryComponent(query)}&time_range=${settings.searchTimeRange}';
      return _SearchBundle(
        snippets: text.substring(0, end),
        hitCount: 1,
        urls: [searchUrl],
        failed: false,
      );
    } catch (e, s) {
      AppLogger.error('SearXNG HTML fallback failed', e, s);
      return const _SearchBundle(
        snippets: '(検索失敗)',
        hitCount: 0,
        urls: [],
        failed: true,
      );
    }
  }

  String _withSearchTrace({
    required String answer,
    required List<_SearchTrace> traces,
  }) {
    if (traces.isEmpty) {
      return answer;
    }
    final lines = <String>[];
    lines.add('## Search Trace');
    for (var i = 0; i < traces.length; i++) {
      final t = traces[i];
      final stamp =
          '${t.executedAt.year}-${t.executedAt.month.toString().padLeft(2, '0')}-${t.executedAt.day.toString().padLeft(2, '0')} '
          '${t.executedAt.hour.toString().padLeft(2, '0')}:${t.executedAt.minute.toString().padLeft(2, '0')}:${t.executedAt.second.toString().padLeft(2, '0')}';
      lines.add(
        '- Step ${i + 1}: [$stamp] query="${t.query}" hits=${t.hitCount}${t.failed ? " (failed/weak)" : ""}',
      );
      for (final url in t.urls.take(3)) {
        lines.add('  - $url');
      }
    }
    return '${answer.trim()}\n\n${lines.join('\n')}';
  }

  String _finalizeAnswer({
    required String answer,
    required List<_SearchTrace> traces,
    required bool freshnessSensitive,
  }) {
    final hasUrlEvidence = traces.any((t) => t.urls.isNotEmpty);
    if (freshnessSensitive && !hasUrlEvidence) {
      const guarded =
          '## 確認結果\n'
          '- 未確認: 時系列依存の質問ですが、根拠URL付き検索結果を得られませんでした。\n'
          '- SearXNG設定・検索語を調整して再実行してください。';
      return _withSearchTrace(answer: guarded, traces: traces);
    }
    return _withSearchTrace(answer: answer, traces: traces);
  }

  bool _isFreshnessSensitive(String text) {
    final t = text.toLowerCase();
    const keys = [
      'today',
      'latest',
      'current',
      'news',
      'recent',
      '昨日',
      '今日',
      '明日',
      '最新',
      'ニュース',
      '現在',
      '直近',
      '速報',
      '日付',
    ];
    for (final key in keys) {
      if (t.contains(key)) {
        return true;
      }
    }
    return false;
  }

  _AgenticStep _parseStep(String text) {
    final matched = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (matched == null) {
      return _AgenticStep(answer: text.trim(), confidence: 0.3, nextQuery: '');
    }
    try {
      final decoded = jsonDecode(matched.group(0)!) as Map<String, dynamic>;
      final answer = decoded['answer'] as String? ?? text.trim();
      final confidence = (decoded['confidence'] as num?)?.toDouble() ?? 0.3;
      final nextQuery = decoded['next_query'] as String? ?? '';
      return _AgenticStep(
        answer: answer,
        confidence: confidence.clamp(0.0, 1.0),
        nextQuery: nextQuery,
      );
    } catch (_) {
      return _AgenticStep(answer: text.trim(), confidence: 0.3, nextQuery: '');
    }
  }
}

class _AgenticStep {
  const _AgenticStep({
    required this.answer,
    required this.confidence,
    required this.nextQuery,
  });

  final String answer;
  final double confidence;
  final String nextQuery;
}

class _SearchBundle {
  const _SearchBundle({
    required this.snippets,
    required this.hitCount,
    required this.urls,
    required this.failed,
  });

  final String snippets;
  final int hitCount;
  final List<String> urls;
  final bool failed;
}

class _SearchTrace {
  const _SearchTrace({
    required this.executedAt,
    required this.query,
    required this.hitCount,
    required this.urls,
    required this.failed,
  });

  final DateTime executedAt;
  final String query;
  final int hitCount;
  final List<String> urls;
  final bool failed;
}
