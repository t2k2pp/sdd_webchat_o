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
            const _SectionHeader('Sections'),
            ListTile(
              leading: const Icon(Icons.travel_explore_outlined),
              title: const Text('Search'),
              subtitle: Text(
                'SearXNG URL / max=${settings.maxSearchIterations} / '
                'confidence=${settings.confidenceThreshold.toStringAsFixed(2)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _SearchSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('System Prompt'),
              subtitle: Text(
                settings.systemPrompt.trim().isEmpty
                    ? '(未設定)'
                    : settings.systemPrompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _SystemPromptSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Model Endpoints'),
              subtitle: Text(
                '登録数: ${settings.modelEndpoints.length} / '
                '選択: ${settings.selectedEndpoint?.name ?? '-'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _ModelEndpointsPage(),
                  ),
                );
              },
            ),
            const Divider(height: 20),
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

class _SearchSettingsPage extends ConsumerWidget {
  const _SearchSettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search Settings')),
      body: ListView(
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final value = await _pushTextEditPage(
                context,
                title: 'SearXNG Base URL',
                label: 'Base URL',
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await _pushSearchPolicyPage(context, settings);
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
        ],
      ),
    );
  }
}

class _SystemPromptSettingsPage extends ConsumerWidget {
  const _SystemPromptSettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('System Prompt')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Global System Prompt'),
            subtitle: Text(
              settings.systemPrompt.trim().isEmpty
                  ? '(未設定)'
                  : settings.systemPrompt,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final value = await _pushTextEditPage(
                context,
                title: 'Global System Prompt',
                label: 'System Prompt',
                initialValue: settings.systemPrompt,
                minLines: 10,
                maxLines: 20,
              );
              if (value != null) {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .updateSystemPrompt(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ModelEndpointsPage extends ConsumerWidget {
  const _ModelEndpointsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Endpoints'),
        actions: [
          IconButton(
            onPressed: () async {
              final endpoint = await _pushEndpointPage(context);
              if (endpoint != null) {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .addEndpoint(endpoint);
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '追加',
          ),
        ],
      ),
      body: ListView(
        children: [
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
                      final edited = await _pushEndpointPage(
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
        ],
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

Future<String?> _pushTextEditPage(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  int minLines = 1,
  int maxLines = 1,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => _TextEditPage(
        title: title,
        label: label,
        initialValue: initialValue,
        minLines: minLines,
        maxLines: maxLines,
      ),
    ),
  );
}

class _TextEditPage extends StatefulWidget {
  const _TextEditPage({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.minLines,
    required this.maxLines,
  });

  final String title;
  final String label;
  final String initialValue;
  final int minLines;
  final int maxLines;

  @override
  State<_TextEditPage> createState() => _TextEditPageState();
}

class _TextEditPageState extends State<_TextEditPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

Future<_SearchPolicyDraft?> _pushSearchPolicyPage(
  BuildContext context,
  AppSettings settings,
) {
  return Navigator.of(context).push<_SearchPolicyDraft>(
    MaterialPageRoute(builder: (_) => _SearchPolicyPage(settings: settings)),
  );
}

class _SearchPolicyPage extends StatefulWidget {
  const _SearchPolicyPage({required this.settings});

  final AppSettings settings;

  @override
  State<_SearchPolicyPage> createState() => _SearchPolicyPageState();
}

class _SearchPolicyPageState extends State<_SearchPolicyPage> {
  late final TextEditingController _maxController;
  late final TextEditingController _thresholdController;
  late String _timeRange;
  late int _safeSearch;

  @override
  void initState() {
    super.initState();
    _maxController = TextEditingController(
      text: widget.settings.maxSearchIterations.toString(),
    );
    _thresholdController = TextEditingController(
      text: widget.settings.confidenceThreshold.toString(),
    );
    _timeRange = widget.settings.searchTimeRange;
    _safeSearch = widget.settings.searchSafeSearch;
  }

  @override
  void dispose() {
    _maxController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic Search Policy'),
        actions: [
          TextButton(
            onPressed: () {
              final maxValue = int.tryParse(_maxController.text.trim()) ?? 3;
              final threshold =
                  double.tryParse(_thresholdController.text.trim()) ?? 0.75;
              Navigator.of(context).pop(
                _SearchPolicyDraft(
                  maxIterations: maxValue,
                  confidenceThreshold: threshold.clamp(0.0, 1.0),
                  timeRange: _timeRange,
                  safeSearch: _safeSearch,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _maxController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Iterations',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Confidence Threshold (0.0-1.0)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _timeRange,
            decoration: const InputDecoration(
              labelText: 'Time Range',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'day', child: Text('day')),
              DropdownMenuItem(value: 'month', child: Text('month')),
              DropdownMenuItem(value: 'year', child: Text('year')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _timeRange = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _safeSearch,
            decoration: const InputDecoration(
              labelText: 'Safesearch',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('0 (off)')),
              DropdownMenuItem(value: 1, child: Text('1 (moderate)')),
              DropdownMenuItem(value: 2, child: Text('2 (strict)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _safeSearch = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<ModelEndpoint?> _pushEndpointPage(
  BuildContext context, {
  ModelEndpoint? initial,
}) {
  return Navigator.of(context).push<ModelEndpoint>(
    MaterialPageRoute(builder: (_) => _EndpointEditPage(initial: initial)),
  );
}

class _EndpointEditPage extends StatefulWidget {
  const _EndpointEditPage({this.initial});

  final ModelEndpoint? initial;

  @override
  State<_EndpointEditPage> createState() => _EndpointEditPageState();
}

class _EndpointEditPageState extends State<_EndpointEditPage> {
  late final bool _isEdit;
  late LlmProviderType _provider;
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiVersionController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _maxTokensController;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initial != null;
    _provider = widget.initial?.provider ?? LlmProviderType.ollama;
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _baseUrlController = TextEditingController(
      text: widget.initial?.baseUrl ?? _suggestBaseUrl(_provider),
    );
    _modelController = TextEditingController(
      text: widget.initial?.model ?? _suggestModel(_provider),
    );
    _apiKeyController = TextEditingController(
      text: widget.initial?.apiKey ?? '',
    );
    _apiVersionController = TextEditingController(
      text: widget.initial?.apiVersion ?? '2024-06-01',
    );
    _temperatureController = TextEditingController(
      text: (widget.initial?.temperature ?? 0.4).toString(),
    );
    _maxTokensController = TextEditingController(
      text: (widget.initial?.maxTokens ?? 2048).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    _apiVersionController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  String _suggestBaseUrl(LlmProviderType type) {
    return switch (type) {
      LlmProviderType.ollama => 'http://192.168.1.40:11434',
      LlmProviderType.lmStudio => 'http://192.168.1.40:1234',
      LlmProviderType.llamaCpp => 'http://192.168.1.40:8081',
      LlmProviderType.gemini => 'https://generativelanguage.googleapis.com',
      LlmProviderType.azureOpenAi => 'https://your-resource.openai.azure.com',
    };
  }

  String _suggestModel(LlmProviderType type) {
    return switch (type) {
      LlmProviderType.ollama => 'qwen3-coder-next',
      LlmProviderType.lmStudio => 'gpt-4o-mini',
      LlmProviderType.llamaCpp => 'qwen3-coder-next',
      LlmProviderType.gemini => 'gemini-1.5-flash',
      LlmProviderType.azureOpenAi => 'gpt-4o-mini',
    };
  }

  @override
  Widget build(BuildContext context) {
    final needsApiKey =
        _provider == LlmProviderType.gemini ||
        _provider == LlmProviderType.azureOpenAi ||
        _provider == LlmProviderType.lmStudio ||
        _provider == LlmProviderType.llamaCpp;
    final needsApiVersion = _provider == LlmProviderType.azureOpenAi;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'モデル接続先を編集' : 'モデル接続先を追加'),
        actions: [
          TextButton(
            onPressed: () {
              final endpoint = ModelEndpoint(
                id:
                    widget.initial?.id ??
                    '${_provider.id}-${DateTime.now().microsecondsSinceEpoch}',
                name: _nameController.text.trim().isEmpty
                    ? _provider.label
                    : _nameController.text.trim(),
                provider: _provider,
                baseUrl: _baseUrlController.text.trim(),
                model: _modelController.text.trim(),
                temperature:
                    double.tryParse(_temperatureController.text.trim()) ?? 0.4,
                maxTokens:
                    int.tryParse(_maxTokensController.text.trim()) ?? 2048,
                apiKey: _apiKeyController.text.trim(),
                apiVersion: _apiVersionController.text.trim().isEmpty
                    ? '2024-06-01'
                    : _apiVersionController.text.trim(),
              );
              Navigator.of(context).pop(endpoint);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<LlmProviderType>(
            initialValue: _provider,
            decoration: const InputDecoration(
              labelText: 'Provider',
              border: OutlineInputBorder(),
            ),
            items: LlmProviderType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _provider = value;
                if (!_isEdit) {
                  _baseUrlController.text = _suggestBaseUrl(value);
                  _modelController.text = _suggestModel(value);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '表示名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: _provider == LlmProviderType.azureOpenAi
                  ? 'Deployment Name'
                  : 'Model',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Temperature',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Tokens',
              border: OutlineInputBorder(),
            ),
          ),
          if (needsApiKey) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (needsApiVersion) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _apiVersionController,
              decoration: const InputDecoration(
                labelText: 'Azure API Version',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
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
