import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class GeminiClient implements LlmProviderClient {
  GeminiClient({
    required Dio dio,
    required String model,
    required String apiKey,
    required double temperature,
    required int maxTokens,
  }) : _dio = dio,
       _model = model,
       _apiKey = apiKey,
       _temperature = temperature,
       _maxTokens = maxTokens;

  final Dio _dio;
  final String _model;
  final String _apiKey;
  final double _temperature;
  final int _maxTokens;

  @override
  Future<ChatCompletionResult> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw StateError('Gemini API key is empty');
    }

    final prompt = messages
        .map((m) => '${m.role.toUpperCase()}: ${m.content}')
        .join('\n\n');

    final response = await _dio.post<Map<String, dynamic>>(
      '/v1beta/models/$_model:generateContent',
      queryParameters: {'key': _apiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': _temperature,
          'maxOutputTokens': _maxTokens,
        },
      },
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Gemini response is empty');
    }

    final candidates = data['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map<String, dynamic>) {
        final content = first['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final firstPart = parts.first;
            if (firstPart is Map<String, dynamic>) {
              final text = firstPart['text'];
              if (text is String && text.trim().isNotEmpty) {
                final usage = data['usageMetadata'] as Map<String, dynamic>?;
                final inputTokens =
                    (usage?['promptTokenCount'] as num?)?.toInt() ?? 0;
                final outputTokens =
                    (usage?['candidatesTokenCount'] as num?)?.toInt() ?? 0;
                return ChatCompletionResult(
                  content: text,
                  inputTokens: inputTokens,
                  outputTokens: outputTokens,
                );
              }
            }
          }
        }
      }
    }

    throw StateError('Gemini response format is invalid');
  }
}
