import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class OpenAiCompatibleClient implements LlmProviderClient {
  OpenAiCompatibleClient({
    required Dio dio,
    required String model,
    required this.temperature,
    required this.maxTokens,
    this.apiKey = '',
  }) : _dio = dio,
       _model = model;

  final Dio _dio;
  final String _model;
  final double temperature;
  final int maxTokens;
  final String apiKey;

  @override
  Future<ChatCompletionResult> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/chat/completions',
      data: {
        'model': _model,
        'messages': messages.map((e) => e.toOllamaJson()).toList(),
        'temperature': temperature,
        'max_tokens': maxTokens,
      },
      options: Options(
        headers: {
          if (apiKey.trim().isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    final data = response.data;
    if (data == null) {
      throw StateError('OpenAI-compatible response is empty');
    }

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            final usage = data['usage'] as Map<String, dynamic>?;
            final inputTokens = (usage?['prompt_tokens'] as num?)?.toInt() ?? 0;
            final outputTokens =
                (usage?['completion_tokens'] as num?)?.toInt() ?? 0;
            return ChatCompletionResult(
              content: content,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            );
          }
        }
      }
    }

    throw StateError('OpenAI-compatible response format is invalid');
  }
}
