import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/in_memory_settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return InMemorySettingsRepository();
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.read(settingsRepositoryProvider).load();
  }

  Future<void> saveSettings(AppSettings next) async {
    final repository = ref.read(settingsRepositoryProvider);
    state = const AsyncLoading();
    await repository.save(next);
    state = AsyncData(next);
  }

  Future<void> toggleDefaultSearxng(bool enabled) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(searxngEnabledByDefault: enabled));
  }
}
