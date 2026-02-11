import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/file_project_repository.dart';
import '../../data/project_repository.dart';
import '../../domain/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return FileProjectRepository();
});

final projectListProvider = FutureProvider<List<Project>>((ref) async {
  return ref.read(projectRepositoryProvider).list();
});

final activeProjectIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(projectRepositoryProvider).getActiveProjectId();
});
