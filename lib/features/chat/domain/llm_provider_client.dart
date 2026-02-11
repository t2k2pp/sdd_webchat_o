import 'chat_message.dart';

class ChatCompletionResult {
  const ChatCompletionResult({
    required this.content,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final String content;
  final int inputTokens;
  final int outputTokens;
}

abstract interface class LlmProviderClient {
  Future<ChatCompletionResult> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  });
}
