import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class OpenAiCompatibleClient implements LlmProviderClient {
  OpenAiCompatibleClient({
    required Dio dio,
    required String model,
    this.apiKey = '',
  }) : _dio = dio,
       _model = model;

  final Dio _dio;
  final String _model;
  final String apiKey;

  @override
  Future<String> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/chat/completions',
      data: {
        'model': _model,
        'messages': messages.map((e) => e.toOllamaJson()).toList(),
        'temperature': 0.4,
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
            return content;
          }
        }
      }
    }

    throw StateError('OpenAI-compatible response format is invalid');
  }
}
