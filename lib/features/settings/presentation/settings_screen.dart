import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/app_drawer.dart';
import '../domain/app_settings.dart';
import '../domain/model_endpoint.dart';
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
            const Divider(height: 1),
            ListTile(
              title: const Text('モデル接続先'),
              subtitle: const Text('複数登録して1つを選択して利用'),
              trailing: IconButton(
                onPressed: () async {
                  final endpoint = await _showAddEndpointDialog(context);
                  if (endpoint != null) {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .addEndpoint(endpoint);
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '追加',
              ),
            ),
            ...settings.modelEndpoints.map((endpoint) {
              final selected = endpoint.id == settings.selectedEndpointId;
              return ListTile(
                title: Text(endpoint.name),
                subtitle: Text(
                  '${endpoint.provider.label} | ${endpoint.model}\n${endpoint.baseUrl}',
                ),
                isThreeLine: true,
                leading: IconButton(
                  onPressed: () {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .selectEndpoint(endpoint.id);
                  },
                  icon: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: Colors.teal)
                    : IconButton(
                        onPressed: settings.modelEndpoints.length <= 1
                            ? null
                            : () {
                                ref
                                    .read(settingsControllerProvider.notifier)
                                    .removeEndpoint(endpoint.id);
                              },
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                      ),
                onTap: () {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .selectEndpoint(endpoint.id);
                },
              );
            }),
            const Divider(height: 1),
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
                child: const Text('接続確認 (選択モデル / SearXNG)'),
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

Future<ModelEndpoint?> _showAddEndpointDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final baseUrlController = TextEditingController();
  final modelController = TextEditingController();
  final apiKeyController = TextEditingController();
  final apiVersionController = TextEditingController(text: '2024-06-01');
  var provider = LlmProviderType.ollama;

  String suggestBaseUrl(LlmProviderType type) {
    return switch (type) {
      LlmProviderType.ollama => 'http://192.168.1.40:11434',
      LlmProviderType.lmStudio => 'http://192.168.1.40:1234',
      LlmProviderType.llamaCpp => 'http://192.168.1.40:8081',
      LlmProviderType.gemini => 'https://generativelanguage.googleapis.com',
      LlmProviderType.azureOpenAi => 'https://your-resource.openai.azure.com',
    };
  }

  String suggestModel(LlmProviderType type) {
    return switch (type) {
      LlmProviderType.ollama => 'qwen3-coder-next',
      LlmProviderType.lmStudio => 'gpt-4o-mini',
      LlmProviderType.llamaCpp => 'qwen3-coder-next',
      LlmProviderType.gemini => 'gemini-1.5-flash',
      LlmProviderType.azureOpenAi => 'gpt-4o-mini',
    };
  }

  baseUrlController.text = suggestBaseUrl(provider);
  modelController.text = suggestModel(provider);

  final result = await showDialog<ModelEndpoint>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final needsApiKey =
              provider == LlmProviderType.gemini ||
              provider == LlmProviderType.azureOpenAi ||
              provider == LlmProviderType.lmStudio ||
              provider == LlmProviderType.llamaCpp;
          final needsApiVersion = provider == LlmProviderType.azureOpenAi;

          return AlertDialog(
            title: const Text('モデル接続先を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<LlmProviderType>(
                    initialValue: provider,
                    items: LlmProviderType.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        provider = value;
                        baseUrlController.text = suggestBaseUrl(value);
                        modelController.text = suggestModel(value);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Provider'),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '表示名'),
                  ),
                  TextField(
                    controller: baseUrlController,
                    decoration: const InputDecoration(labelText: 'Base URL'),
                  ),
                  TextField(
                    controller: modelController,
                    decoration: InputDecoration(
                      labelText: provider == LlmProviderType.azureOpenAi
                          ? 'Deployment Name'
                          : 'Model',
                    ),
                  ),
                  if (needsApiKey)
                    TextField(
                      controller: apiKeyController,
                      decoration: const InputDecoration(labelText: 'API Key'),
                    ),
                  if (needsApiVersion)
                    TextField(
                      controller: apiVersionController,
                      decoration: const InputDecoration(
                        labelText: 'Azure API Version',
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final id =
                      '${provider.id}-${DateTime.now().microsecondsSinceEpoch}';
                  final endpoint = ModelEndpoint(
                    id: id,
                    name: nameController.text.trim().isEmpty
                        ? provider.label
                        : nameController.text.trim(),
                    provider: provider,
                    baseUrl: baseUrlController.text.trim(),
                    model: modelController.text.trim(),
                    apiKey: apiKeyController.text.trim(),
                    apiVersion: apiVersionController.text.trim().isEmpty
                        ? '2024-06-01'
                        : apiVersionController.text.trim(),
                  );
                  Navigator.of(context).pop(endpoint);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  baseUrlController.dispose();
  modelController.dispose();
  apiKeyController.dispose();
  apiVersionController.dispose();

  return result;
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
    } catch (_) {
      return '$name: NG';
    }
  }

  final selected = settings.selectedEndpoint;
  final modelResult = selected == null
      ? 'Model: none'
      : await check(
          selected.name,
          selected.baseUrl,
          switch (selected.provider) {
            LlmProviderType.ollama => '/api/tags',
            LlmProviderType.lmStudio => '/v1/models',
            LlmProviderType.llamaCpp => '/v1/models',
            LlmProviderType.gemini => '/v1beta/models?key=${selected.apiKey}',
            LlmProviderType.azureOpenAi =>
              '/openai/deployments?api-version=${selected.apiVersion}',
          },
        );

  final searxng = await check(
    'SearXNG',
    settings.searxngBaseUrl,
    '/search?q=healthcheck',
  );
  return '$modelResult / $searxng';
}
