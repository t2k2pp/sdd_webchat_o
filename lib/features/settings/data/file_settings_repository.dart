import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/app_settings.dart';
import '../domain/model_endpoint.dart';
import '../domain/settings_repository.dart';

class FileSettingsRepository implements SettingsRepository {
  FileSettingsRepository({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  File? _settingsFile;

  @override
  Future<AppSettings> load() async {
    final file = await _resolveFile();
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      var settings = AppSettings.fromJson(decoded);

      final endpoints = <ModelEndpoint>[];
      for (final endpoint in settings.modelEndpoints) {
        final secureKey = _secureKey(endpoint.id);
        final apiKey = await _secureStorage.read(key: secureKey);
        endpoints.add(
          endpoint.copyWith(apiKey: (apiKey ?? endpoint.apiKey).trim()),
        );
      }
      settings = settings.copyWith(modelEndpoints: endpoints);
      return settings;
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final file = await _resolveFile();

    for (final endpoint in settings.modelEndpoints) {
      await _secureStorage.write(
        key: _secureKey(endpoint.id),
        value: endpoint.apiKey,
      );
    }

    final sanitized = settings.copyWith(
      modelEndpoints: settings.modelEndpoints
          .map((e) => e.copyWith(apiKey: ''))
          .toList(),
    );
    await file.writeAsString(jsonEncode(sanitized.toJson()));
  }

  Future<File> _resolveFile() async {
    if (_settingsFile != null) {
      return _settingsFile!;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app_settings.json'));
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode(const AppSettings().toJson()));
    }
    _settingsFile = file;
    return file;
  }

  String _secureKey(String endpointId) => 'settings.api_key.$endpointId';
}
