import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/app_drawer.dart';
import '../domain/app_settings.dart';
import 'providers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      drawer: const AppDrawer(currentPath: '/settings'),
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            SwitchListTile(
              title: const Text('SearXNG default ON'),
              subtitle: const Text('チャット開始時の既定値'),
              value: settings.searxngEnabledByDefault,
              onChanged: (value) {
                ref
                    .read(settingsControllerProvider.notifier)
                    .toggleDefaultSearxng(value);
              },
            ),
            ListTile(
              title: const Text('SearXNG Base URL'),
              subtitle: Text(settings.searxngBaseUrl),
            ),
            ListTile(
              title: const Text('Ollama Base URL'),
              subtitle: Text(settings.ollamaBaseUrl),
            ),
            ListTile(
              title: const Text('Ollama Model'),
              subtitle: Text(settings.ollamaModel),
            ),
            ListTile(
              title: const Text('LM Studio Base URL'),
              subtitle: Text(settings.lmStudioBaseUrl),
            ),
            ListTile(
              title: const Text('llama.cpp Base URL'),
              subtitle: Text(settings.llamaCppBaseUrl),
            ),
            ListTile(
              title: const Text('Agentic max iterations'),
              subtitle: Text('${settings.maxSearchIterations}'),
            ),
            ListTile(
              title: const Text('Agentic confidence threshold'),
              subtitle: Text(settings.confidenceThreshold.toStringAsFixed(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await _checkConnections(settings);
                  messenger.showSnackBar(SnackBar(content: Text(result)));
                },
                child: const Text('接続確認 (Ollama / SearXNG)'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('設定読み込み失敗: $error')),
      ),
    );
  }
}

Future<String> _checkConnections(AppSettings settings) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<String> check(String name, String url, String path) async {
    try {
      final response = await dio.getUri(Uri.parse('$url$path'));
      return '$name: ${response.statusCode}';
    } catch (error) {
      return '$name: NG';
    }
  }

  final ollama = await check('Ollama', settings.ollamaBaseUrl, '/api/tags');
  final searxng = await check(
    'SearXNG',
    settings.searxngBaseUrl,
    '/search?q=healthcheck',
  );
  return '$ollama / $searxng';
}
