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
    var query = originalQuestion;
    var bestAnswer = '';
    var bestConfidence = 0.0;
    var totalInTokens = 0;
    var totalOutTokens = 0;
    final seenQueries = <String>{};

    for (var i = 0; i < settings.maxSearchIterations; i++) {
      if (seenQueries.contains(query)) {
        break;
      }
      seenQueries.add(query);

      final snippets = await _search(query, settings);
      final prompt = _buildAgenticPrompt(
        question: originalQuestion,
        query: query,
        snippets: snippets,
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
      if (step.answer.isNotEmpty && step.confidence >= bestConfidence) {
        bestConfidence = step.confidence;
        bestAnswer = step.answer;
      }

      if (step.confidence >= settings.confidenceThreshold) {
        return ChatCompletionResult(
          content: step.answer,
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
    return ChatCompletionResult(
      content: fallback,
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
    return '''
あなたは検索付きアシスタントです。以下の情報を使って回答してください。

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
''';
  }

  Future<String> _search(String query, AppSettings settings) async {
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
        for (final raw in results.take(5)) {
          if (raw is Map<String, dynamic>) {
            final title = raw['title'] as String? ?? '';
            final url = raw['url'] as String? ?? '';
            final content = raw['content'] as String? ?? '';
            lines.add('- $title\n  $url\n  $content');
          }
        }
        return lines.join('\n');
      }
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
        return '(検索結果なし)';
      }
      final end = min(text.length, 1400);
      return text.substring(0, end);
    } catch (_) {
      return '(検索失敗)';
    }
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
