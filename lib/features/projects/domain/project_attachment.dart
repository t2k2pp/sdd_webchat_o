class ProjectAttachment {
  const ProjectAttachment({
    required this.id,
    required this.path,
    required this.name,
  });

  final String id;
  final String path;
  final String name;

  Map<String, dynamic> toJson() {
    return {'id': id, 'path': path, 'name': name};
  }

  static ProjectAttachment fromJson(Map<String, dynamic> json) {
    return ProjectAttachment(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
