import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/usage_event.dart';
import 'usage_report_repository.dart';

class FileUsageReportRepository implements UsageReportRepository {
  File? _file;

  @override
  Future<List<UsageEvent>> listEvents() async {
    final file = await _resolveFile();
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    final events = decoded
        .map((e) => UsageEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  @override
  Future<void> addEvent(UsageEvent event) async {
    final all = await listEvents();
    all.add(event);
    await _writeAll(all);
  }

  @override
  Future<void> clear() async {
    await _writeAll(const []);
  }

  Future<File> _resolveFile() async {
    if (_file != null) {
      return _file!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'usage_events.json'));
    if (!await file.exists()) {
      await file.writeAsString('[]');
    }
    _file = file;
    return file;
  }

  Future<void> _writeAll(List<UsageEvent> events) async {
    final file = await _resolveFile();
    await file.writeAsString(
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }
}
