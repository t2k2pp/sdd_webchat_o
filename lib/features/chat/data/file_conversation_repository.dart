import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/conversation_thread.dart';
import 'conversation_repository.dart';

class FileConversationRepository implements ConversationRepository {
  FileConversationRepository();

  File? _file;

  @override
  Future<List<ConversationThread>> list() async {
    final items = await _readAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<void> upsert(ConversationThread thread) async {
    final items = await _readAll();
    final idx = items.indexWhere((e) => e.id == thread.id);
    if (idx >= 0) {
      items[idx] = thread;
    } else {
      items.add(thread);
    }
    await _writeAll(items);
  }

  @override
  Future<ConversationThread?> getById(String id) async {
    final items = await _readAll();
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> delete(String id) async {
    final items = await _readAll();
    items.removeWhere((e) => e.id == id);
    await _writeAll(items);
  }

  Future<File> _resolveFile() async {
    if (_file != null) {
      return _file!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'conversations.json'));
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
    _file = file;
    return file;
  }

  Future<List<ConversationThread>> _readAll() async {
    final file = await _resolveFile();
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ConversationThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<ConversationThread> items) async {
    final file = await _resolveFile();
    final payload = items.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(payload));
  }
}
