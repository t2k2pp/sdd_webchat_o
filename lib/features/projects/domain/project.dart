import 'project_attachment.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.additionalSystemPrompt,
    required this.attachments,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String additionalSystemPrompt;
  final List<ProjectAttachment> attachments;
  final DateTime updatedAt;

  Project copyWith({
    String? id,
    String? name,
    String? additionalSystemPrompt,
    List<ProjectAttachment>? attachments,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      additionalSystemPrompt:
          additionalSystemPrompt ?? this.additionalSystemPrompt,
      attachments: attachments ?? this.attachments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'additionalSystemPrompt': additionalSystemPrompt,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Project fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? const [];
    return Project(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Project',
      additionalSystemPrompt: json['additionalSystemPrompt'] as String? ?? '',
      attachments: rawAttachments
          .map((e) => ProjectAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
