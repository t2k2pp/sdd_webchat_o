class ChatMessage {
  ChatMessage({required this.role, required this.content, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  final String role;
  final String content;
  final DateTime createdAt;

  Map<String, String> toOllamaJson() => {'role': role, 'content': content};
}
