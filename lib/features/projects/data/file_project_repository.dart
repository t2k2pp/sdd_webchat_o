import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/project.dart';
import 'project_repository.dart';

class FileProjectRepository implements ProjectRepository {
  File? _projectsFile;
  File? _activeFile;

  @override
  Future<List<Project>> list() async {
    final items = await _readAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<void> upsert(Project project) async {
    final items = await _readAll();
    final idx = items.indexWhere((e) => e.id == project.id);
    if (idx >= 0) {
      items[idx] = project;
    } else {
      items.add(project);
    }
    await _writeAll(items);
  }

  @override
  Future<void> delete(String id) async {
    final items = await _readAll();
    items.removeWhere((e) => e.id == id);
    await _writeAll(items);
    final active = await getActiveProjectId();
    if (active == id) {
      await setActiveProjectId(null);
    }
  }

  @override
  Future<Project?> getById(String id) async {
    final items = await _readAll();
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<String?> getActiveProjectId() async {
    final file = await _resolveActiveFile();
    final raw = await file.readAsString();
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> setActiveProjectId(String? id) async {
    final file = await _resolveActiveFile();
    await file.writeAsString(id ?? '');
  }

  Future<File> _resolveProjectsFile() async {
    if (_projectsFile != null) {
      return _projectsFile!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'projects.json'));
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
    _projectsFile = file;
    return file;
  }

  Future<File> _resolveActiveFile() async {
    if (_activeFile != null) {
      return _activeFile!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'active_project.txt'));
    if (!await file.exists()) {
      await file.writeAsString('');
    }
    _activeFile = file;
    return file;
  }

  Future<List<Project>> _readAll() async {
    final file = await _resolveProjectsFile();
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<Project> items) async {
    final file = await _resolveProjectsFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
