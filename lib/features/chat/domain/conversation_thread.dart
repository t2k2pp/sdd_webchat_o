import 'chat_message.dart';

class ConversationThread {
  const ConversationThread({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages
          .map(
            (m) => {
              'role': m.role,
              'content': m.content,
              'artifactHtml': m.artifactHtml,
              'createdAt': m.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  static ConversationThread fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    final messages = rawMessages.map((raw) {
      final item = raw as Map<String, dynamic>;
      return ChatMessage(
        role: item['role'] as String? ?? 'assistant',
        content: item['content'] as String? ?? '',
        artifactHtml: item['artifactHtml'] as String?,
        createdAt: DateTime.tryParse(item['createdAt'] as String? ?? ''),
      );
    }).toList();

    return ConversationThread(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Conversation',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      messages: messages,
    );
  }
}
