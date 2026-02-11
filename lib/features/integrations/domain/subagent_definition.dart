class SubAgentDefinition {
  const SubAgentDefinition({
    required this.id,
    required this.name,
    required this.instruction,
    this.sourceUrl = '',
    this.enabled = true,
  });

  final String id;
  final String name;
  final String instruction;
  final String sourceUrl;
  final bool enabled;

  SubAgentDefinition copyWith({
    String? id,
    String? name,
    String? instruction,
    String? sourceUrl,
    bool? enabled,
  }) {
    return SubAgentDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      instruction: instruction ?? this.instruction,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instruction': instruction,
      'sourceUrl': sourceUrl,
      'enabled': enabled,
    };
  }

  static SubAgentDefinition fromJson(Map<String, dynamic> json) {
    return SubAgentDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'SubAgent',
      instruction: json['instruction'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
