import '../domain/project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> list();
  Future<void> upsert(Project project);
  Future<void> delete(String id);
  Future<Project?> getById(String id);
  Future<String?> getActiveProjectId();
  Future<void> setActiveProjectId(String? id);
}
