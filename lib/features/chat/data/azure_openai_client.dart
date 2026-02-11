import 'package:dio/dio.dart';

import '../domain/chat_message.dart';
import '../domain/llm_provider_client.dart';

class AzureOpenAiClient implements LlmProviderClient {
  AzureOpenAiClient({
    required Dio dio,
    required String deployment,
    required String apiKey,
    required String apiVersion,
  }) : _dio = dio,
       _deployment = deployment,
       _apiKey = apiKey,
       _apiVersion = apiVersion;

  final Dio _dio;
  final String _deployment;
  final String _apiKey;
  final String _apiVersion;

  @override
  Future<String> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw StateError('Azure OpenAI api-key is empty');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/openai/deployments/$_deployment/chat/completions',
      queryParameters: {'api-version': _apiVersion},
      options: Options(headers: {'api-key': _apiKey}),
      data: {
        'messages': messages.map((e) => e.toOllamaJson()).toList(),
        'temperature': 0.4,
      },
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Azure OpenAI response is empty');
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

    throw StateError('Azure OpenAI response format is invalid');
  }
}
