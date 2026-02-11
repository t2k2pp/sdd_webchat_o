class McpServerDefinition {
  const McpServerDefinition({
    required this.id,
    required this.name,
    required this.command,
    this.args = const [],
    this.env = const {},
    this.enabled = true,
  });

  final String id;
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String> env;
  final bool enabled;

  McpServerDefinition copyWith({
    String? id,
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    bool? enabled,
  }) {
    return McpServerDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'args': args,
      'env': env,
      'enabled': enabled,
    };
  }

  static McpServerDefinition fromJson(Map<String, dynamic> json) {
    final rawArgs = json['args'] as List<dynamic>? ?? const [];
    final rawEnv = json['env'] as Map<String, dynamic>? ?? const {};
    return McpServerDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'MCP',
      command: json['command'] as String? ?? '',
      args: rawArgs.map((e) => e.toString()).toList(),
      env: rawEnv.map((k, v) => MapEntry(k, v.toString())),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
