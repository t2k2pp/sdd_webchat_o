import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class OllamaClient implements LlmProviderClient {
  OllamaClient({
    required Dio dio,
    required String model,
    required double temperature,
    required int maxTokens,
  }) : _dio = dio,
       _model = model,
       _temperature = temperature,
       _maxTokens = maxTokens;

  final Dio _dio;
  final String _model;
  final double _temperature;
  final int _maxTokens;

  @override
  Future<ChatCompletionResult> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/chat',
      data: {
        'model': _model,
        'stream': false,
        'messages': messages.map((e) => e.toOllamaJson()).toList(),
        'options': {'temperature': _temperature, 'num_predict': _maxTokens},
      },
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Ollama response is empty');
    }

    final message = data['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) {
        final inputTokens = (data['prompt_eval_count'] as num?)?.toInt() ?? 0;
        final outputTokens = (data['eval_count'] as num?)?.toInt() ?? 0;
        return ChatCompletionResult(
          content: content,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
      }
    }

    throw StateError('Ollama response format is invalid');
  }
}
