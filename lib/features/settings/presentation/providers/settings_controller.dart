import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/in_memory_settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/model_endpoint.dart';
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

  Future<void> selectEndpoint(String endpointId) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(selectedEndpointId: endpointId));
  }

  Future<void> addEndpoint(ModelEndpoint endpoint) async {
    final current = state.value ?? const AppSettings();
    final nextEndpoints = [...current.modelEndpoints, endpoint];
    await saveSettings(
      current.copyWith(
        modelEndpoints: nextEndpoints,
        selectedEndpointId: endpoint.id,
      ),
    );
  }

  Future<void> removeEndpoint(String endpointId) async {
    final current = state.value ?? const AppSettings();
    final nextEndpoints = current.modelEndpoints
        .where((endpoint) => endpoint.id != endpointId)
        .toList();
    if (nextEndpoints.isEmpty) {
      return;
    }
    final nextSelected = current.selectedEndpointId == endpointId
        ? nextEndpoints.first.id
        : current.selectedEndpointId;
    await saveSettings(
      current.copyWith(
        modelEndpoints: nextEndpoints,
        selectedEndpointId: nextSelected,
      ),
    );
  }

  Future<void> updateSearxngBaseUrl(String baseUrl) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(searxngBaseUrl: baseUrl));
  }

  Future<void> updateSearchPolicy({
    required int maxIterations,
    required double confidenceThreshold,
    required String timeRange,
    required int safeSearch,
  }) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(
      current.copyWith(
        maxSearchIterations: maxIterations,
        confidenceThreshold: confidenceThreshold,
        searchTimeRange: timeRange,
        searchSafeSearch: safeSearch,
      ),
    );
  }

  Future<void> updateSystemPrompt(String prompt) async {
    final current = state.value ?? const AppSettings();
    await saveSettings(current.copyWith(systemPrompt: prompt));
  }

  Future<void> updateEndpoint(ModelEndpoint endpoint) async {
    final current = state.value ?? const AppSettings();
    final nextEndpoints = current.modelEndpoints.map((e) {
      return e.id == endpoint.id ? endpoint : e;
    }).toList();
    await saveSettings(current.copyWith(modelEndpoints: nextEndpoints));
  }
}
