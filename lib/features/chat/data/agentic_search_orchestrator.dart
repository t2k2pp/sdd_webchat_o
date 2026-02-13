import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

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
    var query = originalQuestion;
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
検索スニペットに根拠がない情報は断定しないこと。
今日より未来の日付の出来事は、スニペットに明示根拠がある場合のみ記述すること。
根拠が弱い場合は「未確認」または「確認できません」と明記すること。

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

  Future<_SearchBundle> _search(String query, AppSettings settings) async {
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
    } catch (_) {
      // fall through to html fallback
    }

    try {
      final html = await _dio.get<String>(
        '/search',
        queryParameters: {'q': query, 'time_range': settings.searchTimeRange},
      );
      final text = (html.data ?? '')
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
      final end = min(text.length, 1400);
      return _SearchBundle(
        snippets: text.substring(0, end),
        hitCount: 0,
        urls: const [],
        failed: false,
      );
    } catch (_) {
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
      lines.add(
        '- Step ${i + 1}: query="${t.query}" hits=${t.hitCount}${t.failed ? " (failed/weak)" : ""}',
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
    required this.query,
    required this.hitCount,
    required this.urls,
    required this.failed,
  });

  final String query;
  final int hitCount;
  final List<String> urls;
  final bool failed;
}
