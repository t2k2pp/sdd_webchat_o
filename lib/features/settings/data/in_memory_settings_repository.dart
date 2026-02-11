import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
  }
}
