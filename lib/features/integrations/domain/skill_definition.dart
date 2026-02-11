class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.content,
    this.sourceUrl = '',
    this.enabled = true,
  });

  final String id;
  final String name;
  final String content;
  final String sourceUrl;
  final bool enabled;

  SkillDefinition copyWith({
    String? id,
    String? name,
    String? content,
    String? sourceUrl,
    bool? enabled,
  }) {
    return SkillDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'sourceUrl': sourceUrl,
      'enabled': enabled,
    };
  }

  static SkillDefinition fromJson(Map<String, dynamic> json) {
    return SkillDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Skill',
      content: json['content'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
