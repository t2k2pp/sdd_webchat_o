import 'chat_message.dart';

abstract interface class LlmProviderClient {
  Future<String> completeChat({
    required List<ChatMessage> messages,
    required bool enableSearch,
  });
}
