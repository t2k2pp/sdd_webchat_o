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
            const _SectionHeader('Search'),
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
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final value = await _showTextEditDialog(
                  context,
                  title: 'SearXNG Base URL',
                  initialValue: settings.searxngBaseUrl,
                );
                if (value != null && value.trim().isNotEmpty) {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .updateSearxngBaseUrl(value.trim());
                }
              },
            ),
            ListTile(
              title: const Text('Agentic Search Policy'),
              subtitle: Text(
                'max=${settings.maxSearchIterations}, confidence=${settings.confidenceThreshold.toStringAsFixed(2)}, '
                'time=${settings.searchTimeRange}, safesearch=${settings.searchSafeSearch}',
              ),
              trailing: const Icon(Icons.tune),
              onTap: () async {
                final result = await _showSearchPolicyDialog(context, settings);
                if (result != null) {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .updateSearchPolicy(
                        maxIterations: result.maxIterations,
                        confidenceThreshold: result.confidenceThreshold,
                        timeRange: result.timeRange,
                        safeSearch: result.safeSearch,
                      );
                }
              },
            ),

            const _SectionHeader('System Prompt'),
            ListTile(
              title: const Text('Global System Prompt'),
              subtitle: Text(
                settings.systemPrompt.trim().isEmpty
                    ? '(未設定)'
                    : settings.systemPrompt,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.edit_note),
              onTap: () async {
                final value = await _showTextEditDialog(
                  context,
                  title: 'Global System Prompt',
                  initialValue: settings.systemPrompt,
                  minLines: 6,
                  maxLines: 14,
                );
                if (value != null) {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .updateSystemPrompt(value);
                }
              },
            ),

            const _SectionHeader('Model Endpoints'),
            ListTile(
              title: const Text('モデル接続先一覧'),
              subtitle: const Text('複数登録して1つを選択して利用'),
              trailing: IconButton(
                onPressed: () async {
                  final endpoint = await _showEndpointDialog(context);
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
                  '${endpoint.provider.label} | ${endpoint.model}\n'
                  'temp=${endpoint.temperature}, maxTokens=${endpoint.maxTokens}\n'
                  '${endpoint.baseUrl}',
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
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '編集',
                      onPressed: () async {
                        final edited = await _showEndpointDialog(
                          context,
                          initial: endpoint,
                        );
                        if (edited != null) {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .updateEndpoint(edited.copyWith(id: endpoint.id));
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        selected ? Icons.check_circle : Icons.delete_outline,
                        color: selected ? Colors.teal : null,
                      ),
                      tooltip: selected ? '選択中' : '削除',
                      onPressed: selected || settings.modelEndpoints.length <= 1
                          ? null
                          : () {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .removeEndpoint(endpoint.id);
                            },
                    ),
                  ],
                ),
                onTap: () {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .selectEndpoint(endpoint.id);
                },
              );
            }),

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SearchPolicyDraft {
  const _SearchPolicyDraft({
    required this.maxIterations,
    required this.confidenceThreshold,
    required this.timeRange,
    required this.safeSearch,
  });

  final int maxIterations;
  final double confidenceThreshold;
  final String timeRange;
  final int safeSearch;
}

Future<String?> _showTextEditDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  int minLines = 1,
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

Future<_SearchPolicyDraft?> _showSearchPolicyDialog(
  BuildContext context,
  AppSettings settings,
) async {
  final maxController = TextEditingController(
    text: settings.maxSearchIterations.toString(),
  );
  final thresholdController = TextEditingController(
    text: settings.confidenceThreshold.toString(),
  );
  var timeRange = settings.searchTimeRange;
  var safeSearch = settings.searchSafeSearch;

  final result = await showDialog<_SearchPolicyDraft>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Agentic Search Policy'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Iterations',
                    ),
                  ),
                  TextField(
                    controller: thresholdController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Confidence Threshold (0.0-1.0)',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: timeRange,
                    decoration: const InputDecoration(labelText: 'Time Range'),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('day')),
                      DropdownMenuItem(value: 'month', child: Text('month')),
                      DropdownMenuItem(value: 'year', child: Text('year')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          timeRange = value;
                        });
                      }
                    },
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: safeSearch,
                    decoration: const InputDecoration(labelText: 'Safesearch'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('0 (off)')),
                      DropdownMenuItem(value: 1, child: Text('1 (moderate)')),
                      DropdownMenuItem(value: 2, child: Text('2 (strict)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          safeSearch = value;
                        });
                      }
                    },
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
                  final maxValue = int.tryParse(maxController.text.trim()) ?? 3;
                  final thresholdValue =
                      double.tryParse(thresholdController.text.trim()) ?? 0.75;
                  final clampedThreshold = thresholdValue.clamp(0.0, 1.0);
                  Navigator.of(context).pop(
                    _SearchPolicyDraft(
                      maxIterations: maxValue,
                      confidenceThreshold: clampedThreshold,
                      timeRange: timeRange,
                      safeSearch: safeSearch,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  maxController.dispose();
  thresholdController.dispose();
  return result;
}

Future<ModelEndpoint?> _showEndpointDialog(
  BuildContext context, {
  ModelEndpoint? initial,
}) async {
  final isEdit = initial != null;
  final nameController = TextEditingController(text: initial?.name ?? '');
  final baseUrlController = TextEditingController(text: initial?.baseUrl ?? '');
  final modelController = TextEditingController(text: initial?.model ?? '');
  final apiKeyController = TextEditingController(text: initial?.apiKey ?? '');
  final apiVersionController = TextEditingController(
    text: initial?.apiVersion ?? '2024-06-01',
  );
  final temperatureController = TextEditingController(
    text: (initial?.temperature ?? 0.4).toString(),
  );
  final maxTokensController = TextEditingController(
    text: (initial?.maxTokens ?? 2048).toString(),
  );
  var provider = initial?.provider ?? LlmProviderType.ollama;

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

  if (!isEdit) {
    baseUrlController.text = suggestBaseUrl(provider);
    modelController.text = suggestModel(provider);
  }

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
            title: Text(isEdit ? 'モデル接続先を編集' : 'モデル接続先を追加'),
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
                        if (!isEdit) {
                          baseUrlController.text = suggestBaseUrl(value);
                          modelController.text = suggestModel(value);
                        }
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
                  TextField(
                    controller: temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Temperature'),
                  ),
                  TextField(
                    controller: maxTokensController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Tokens'),
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
                      initial?.id ??
                      '${provider.id}-${DateTime.now().microsecondsSinceEpoch}';
                  final endpoint = ModelEndpoint(
                    id: id,
                    name: nameController.text.trim().isEmpty
                        ? provider.label
                        : nameController.text.trim(),
                    provider: provider,
                    baseUrl: baseUrlController.text.trim(),
                    model: modelController.text.trim(),
                    temperature:
                        double.tryParse(temperatureController.text.trim()) ??
                        0.4,
                    maxTokens:
                        int.tryParse(maxTokensController.text.trim()) ?? 2048,
                    apiKey: apiKeyController.text.trim(),
                    apiVersion: apiVersionController.text.trim().isEmpty
                        ? '2024-06-01'
                        : apiVersionController.text.trim(),
                  );
                  Navigator.of(context).pop(endpoint);
                },
                child: Text(isEdit ? 'Save' : 'Add'),
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
  temperatureController.dispose();
  maxTokensController.dispose();

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
