import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/conversation_thread.dart';
import 'conversation_repository.dart';

class SqliteConversationRepository implements ConversationRepository {
  SqliteConversationRepository();

  Database? _database;

  @override
  Future<List<ConversationThread>> list() async {
    final db = await _openDatabase();
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(ConversationThread thread) async {
    final db = await _openDatabase();
    await db.insert('conversations', {
      'id': thread.id,
      'title': thread.title,
      'updated_at': thread.updatedAt.toIso8601String(),
      'messages_json': jsonEncode(thread.toJson()['messages'] as List<dynamic>),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<ConversationThread?> getById(String id) async {
    final db = await _openDatabase();
    final rows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _openDatabase();
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'app.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            messages_json TEXT NOT NULL
          )
        ''');
      },
    );

    await _migrateLegacyJsonIfNeeded(db, dir);
    _database = db;
    return db;
  }

  Future<void> _migrateLegacyJsonIfNeeded(Database db, Directory dir) async {
    final countRow = await db.rawQuery(
      'SELECT COUNT(*) as c FROM conversations',
    );
    final count = (countRow.first['c'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      return;
    }

    final legacyPath = p.join(dir.path, 'conversations.json');
    final legacyFile = File(legacyPath);
    if (!await legacyFile.exists()) {
      return;
    }

    try {
      final raw = await legacyFile.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      final threads = decoded
          .map((e) => ConversationThread.fromJson(e as Map<String, dynamic>))
          .toList();

      final batch = db.batch();
      for (final thread in threads) {
        batch.insert('conversations', {
          'id': thread.id,
          'title': thread.title,
          'updated_at': thread.updatedAt.toIso8601String(),
          'messages_json': jsonEncode(
            thread.toJson()['messages'] as List<dynamic>,
          ),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      if (threads.isNotEmpty) {
        final backupPath = p.join(
          dir.path,
          'conversations.migrated.${DateTime.now().millisecondsSinceEpoch}.json',
        );
        await legacyFile.rename(backupPath);
      }
    } catch (e, s) {
      AppLogger.warning('Failed to migrate legacy conversations.json', e, s);
      // Keep legacy data untouched if migration fails.
    }
  }

  ConversationThread _fromRow(Map<String, Object?> row) {
    final rawMessages = row['messages_json'] as String? ?? '[]';
    final decodedMessages = jsonDecode(rawMessages) as List<dynamic>;
    return ConversationThread.fromJson({
      'id': row['id'] as String? ?? '',
      'title': row['title'] as String? ?? 'Conversation',
      'updatedAt':
          row['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      'messages': decodedMessages,
    });
  }
}
