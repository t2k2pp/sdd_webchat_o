import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../app/widgets/app_drawer.dart';
import '../../../core/logging/error_visibility.dart';
import '../../integrations/presentation/integrations_screen.dart';
import '../../usage/presentation/usage_reports_page.dart';
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
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Speech'),
              subtitle: Text(
                'enabled=${settings.ttsEnabled} / ${settings.ttsLanguage} / '
                'rate=${settings.ttsSpeechRate.toStringAsFixed(2)} / '
                'pitch=${settings.ttsPitch.toStringAsFixed(2)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _SpeechSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Artifact Security'),
              subtitle: Text(settings.artifactSafetyMode.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _ArtifactSettingsPage(),
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
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Usage Reports'),
              subtitle: const Text('日次/月次 トークン・コスト集計'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UsageReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Integrations'),
              subtitle: const Text('Skills / Sub Agents / MCP'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IntegrationsScreen()),
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
            title: const Text('Search Max HTML Chars'),
            subtitle: Text('${settings.searchMaxFallbackCharacters} chars'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final value = await _pushSearchHtmlCharsPage(
                context,
                settings.searchMaxFallbackCharacters,
              );
              if (value != null) {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .updateSearchMaxFallbackCharacters(value);
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

class _SpeechSettingsPage extends ConsumerStatefulWidget {
  const _SpeechSettingsPage();

  @override
  ConsumerState<_SpeechSettingsPage> createState() =>
      _SpeechSettingsPageState();
}

class _SpeechSettingsPageState extends ConsumerState<_SpeechSettingsPage> {
  final FlutterTts _tts = FlutterTts();
  bool _previewPlaying = false;
  bool _initialized = false;
  bool _loadingLanguages = true;

  bool _enabled = true;
  String _language = 'ja-JP';
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  List<String> _availableLanguages = const ['ja-JP'];

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPlaying = false;
      });
    });
    _tts.setCancelHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPlaying = false;
      });
    });
    _tts.setErrorHandler((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPlaying = false;
      });
    });
    _loadAvailableLanguages();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakPreview() async {
    await _tts.stop();
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_speechRate.clamp(0.0, 1.0));
    await _tts.setVolume(_volume.clamp(0.0, 1.0));
    await _tts.setPitch(_pitch.clamp(0.5, 2.0));
    await _tts.speak('これは音声合成のテストです。現在の設定で読み上げています。');
  }

  Future<void> _togglePreview() async {
    if (_previewPlaying) {
      final messenger = ScaffoldMessenger.of(context);
      await _tts.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPlaying = false;
      });
      messenger.showSnackBar(const SnackBar(content: Text('読み上げを停止しました')));
      return;
    }
    if (!_enabled) {
      return;
    }
    setState(() {
      _previewPlaying = true;
    });
    try {
      await _speakPreview();
    } catch (e, s) {
      if (!mounted) {
        return;
      }
      ErrorVisibility.notifyUser(
        context,
        userMessage: 'テスト読み上げに失敗しました',
        logMessage: 'Failed to play speech preview',
        error: e,
        stackTrace: s,
      );
      setState(() {
        _previewPlaying = false;
      });
    }
  }

  Future<void> _saveCurrent() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .updateTtsSettings(
          enabled: _enabled,
          language: _language,
          speechRate: _speechRate,
          volume: _volume,
          pitch: _pitch,
        );
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final raw = await _tts.getLanguages;
      final parsed = <String>{};
      if (raw is List) {
        for (final item in raw) {
          final normalized = _normalizeLanguageCode(item.toString());
          if (normalized.isNotEmpty) {
            parsed.add(normalized);
          }
        }
      }
      if (parsed.isEmpty) {
        parsed.add('ja-JP');
      }
      final sorted = parsed.toList()..sort();
      if (!sorted.contains(_language)) {
        sorted.insert(0, _language);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _availableLanguages = sorted;
        _loadingLanguages = false;
      });
    } catch (e, s) {
      ErrorVisibility.logOnly(
        'Failed to load available TTS languages',
        error: e,
        stackTrace: s,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _availableLanguages = const ['ja-JP', 'en-US'];
        _loadingLanguages = false;
      });
    }
  }

  String _normalizeLanguageCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll('_', '-');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_initialized) {
      _initialized = true;
      _enabled = settings.ttsEnabled;
      _language = settings.ttsLanguage;
      _speechRate = settings.ttsSpeechRate;
      _volume = settings.ttsVolume;
      _pitch = settings.ttsPitch;
      _language = _normalizeLanguageCode(_language);
      if (!_availableLanguages.contains(_language)) {
        _availableLanguages = [_language, ..._availableLanguages];
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Speech Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable TTS'),
            subtitle: const Text('AI応答の読み上げを有効化'),
            value: _enabled,
            onChanged: (value) async {
              setState(() {
                _enabled = value;
              });
              await _saveCurrent();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: DropdownButtonFormField<String>(
              initialValue: _language,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
                helperText: '端末で利用可能な音声言語',
              ),
              items: _availableLanguages
                  .map(
                    (lang) => DropdownMenuItem<String>(
                      value: lang,
                      child: Text(lang),
                    ),
                  )
                  .toList(),
              onChanged: (_enabled && !_loadingLanguages)
                  ? (value) async {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _language = value;
                      });
                      await _saveCurrent();
                    }
                  : null,
            ),
          ),
          _SliderTile(
            label: 'Speech Rate',
            value: _speechRate,
            min: 0.0,
            max: 1.0,
            enabled: _enabled,
            onChanged: (v) {
              setState(() {
                _speechRate = v;
              });
            },
            onChangeEnd: (_) => _saveCurrent(),
          ),
          _SliderTile(
            label: 'Volume',
            value: _volume,
            min: 0.0,
            max: 1.0,
            enabled: _enabled,
            onChanged: (v) {
              setState(() {
                _volume = v;
              });
            },
            onChangeEnd: (_) => _saveCurrent(),
          ),
          _SliderTile(
            label: 'Pitch',
            value: _pitch,
            min: 0.5,
            max: 2.0,
            enabled: _enabled,
            onChanged: (v) {
              setState(() {
                _pitch = v;
              });
            },
            onChangeEnd: (_) => _saveCurrent(),
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.tonalIcon(
              onPressed: !_enabled && !_previewPlaying ? null : _togglePreview,
              icon: Icon(
                _previewPlaying
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              label: Text(_previewPlaying ? '停止' : 'テスト再生'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactSettingsPage extends ConsumerWidget {
  const _ArtifactSettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Artifact Security')),
      body: ListView(
        children: [
          for (final mode in ArtifactSafetyMode.values)
            ListTile(
              leading: Icon(
                settings.artifactSafetyMode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(mode.label),
              subtitle: Text(mode.description),
              trailing: settings.artifactSafetyMode == mode
                  ? const Icon(Icons.check, size: 18)
                  : null,
              onTap: () async {
                if (settings.artifactSafetyMode == mode) {
                  return;
                }
                await ref
                    .read(settingsControllerProvider.notifier)
                    .updateArtifactSafetyMode(mode);
              },
            ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$label: ${value.toStringAsFixed(2)}'),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 20,
            label: value.toStringAsFixed(2),
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
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
                'usage in=${endpoint.inputTokensTotal}, out=${endpoint.outputTokensTotal}\n'
                'actual≈${endpoint.currency} ${endpoint.actualCostEstimate.toStringAsFixed(4)} | '
                'ref≈${endpoint.currency} ${endpoint.referenceCostEstimate.toStringAsFixed(4)} | '
                'saved≈${endpoint.currency} ${endpoint.savedCostEstimate.toStringAsFixed(4)}\n'
                '${endpoint.baseUrl}',
              ),
              isThreeLine: false,
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

Future<int?> _pushSearchHtmlCharsPage(BuildContext context, int current) {
  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) => _SearchHtmlCharsPage(initialValue: current),
    ),
  );
}

class _SearchPolicyPage extends StatefulWidget {
  const _SearchPolicyPage({required this.settings});

  final AppSettings settings;

  @override
  State<_SearchPolicyPage> createState() => _SearchPolicyPageState();
}

class _SearchPolicyPageState extends State<_SearchPolicyPage> {
  static const List<int> _iterationOptions = [1, 2, 3, 4, 5, 8, 12, 16, 24, 32];

  late int _maxIterations;
  late double _confidenceThreshold;
  late String _timeRange;
  late int _safeSearch;

  @override
  void initState() {
    super.initState();
    _maxIterations = widget.settings.maxSearchIterations.clamp(1, 32);
    _confidenceThreshold = widget.settings.confidenceThreshold.clamp(0.0, 1.0);
    _timeRange = widget.settings.searchTimeRange;
    _safeSearch = widget.settings.searchSafeSearch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic Search Policy'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                _SearchPolicyDraft(
                  maxIterations: _maxIterations,
                  confidenceThreshold: _confidenceThreshold,
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Max Iterations'),
            subtitle: Text('$_maxIterations'),
          ),
          DropdownButtonFormField<int>(
            initialValue: _iterationOptions.contains(_maxIterations)
                ? _maxIterations
                : 8,
            decoration: const InputDecoration(
              labelText: 'Max Iterations',
              border: OutlineInputBorder(),
            ),
            items: _iterationOptions
                .map(
                  (v) => DropdownMenuItem<int>(
                    value: v,
                    child: Text(v.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _maxIterations = value;
              });
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Confidence Threshold'),
            subtitle: Text(_confidenceThreshold.toStringAsFixed(2)),
          ),
          Slider(
            value: _confidenceThreshold,
            min: 0.1,
            max: 0.95,
            divisions: 17,
            label: _confidenceThreshold.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _confidenceThreshold = value;
              });
            },
          ),
          const SizedBox(height: 8),
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

class _SearchHtmlCharsPage extends StatefulWidget {
  const _SearchHtmlCharsPage({required this.initialValue});

  final int initialValue;

  @override
  State<_SearchHtmlCharsPage> createState() => _SearchHtmlCharsPageState();
}

class _SearchHtmlCharsPageState extends State<_SearchHtmlCharsPage> {
  static const List<int> _charOptions = [
    5000,
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
    2000000,
  ];

  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.clamp(5000, 2000000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Max HTML Chars'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_value),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HTML fallback text length: $_value chars',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: _charOptions.contains(_value) ? _value : 50000,
              decoration: const InputDecoration(
                labelText: 'Preset',
                border: OutlineInputBorder(),
              ),
              items: _charOptions
                  .map(
                    (v) => DropdownMenuItem<int>(
                      value: v,
                      child: Text(v.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _value = value;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('Range: 5,000 - 2,000,000'),
          ],
        ),
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

class _EndpointEditPage extends ConsumerStatefulWidget {
  const _EndpointEditPage({this.initial});

  final ModelEndpoint? initial;

  @override
  ConsumerState<_EndpointEditPage> createState() => _EndpointEditPageState();
}

class _EndpointEditPageState extends ConsumerState<_EndpointEditPage> {
  late final bool _isEdit;
  late LlmProviderType _provider;
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiVersionController;
  late double _temperature;
  late final TextEditingController _maxTokensController;
  late final TextEditingController _actualInputCostController;
  late final TextEditingController _actualOutputCostController;
  late final TextEditingController _referenceInputCostController;
  late final TextEditingController _referenceOutputCostController;
  late final TextEditingController _currencyController;

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
    _temperature = (widget.initial?.temperature ?? 0.4).clamp(0.0, 1.5);
    _maxTokensController = TextEditingController(
      text: (widget.initial?.maxTokens ?? 2048).toString(),
    );
    _actualInputCostController = TextEditingController(
      text: (widget.initial?.actualInputCostPerMillion ?? 0).toString(),
    );
    _actualOutputCostController = TextEditingController(
      text: (widget.initial?.actualOutputCostPerMillion ?? 0).toString(),
    );
    _referenceInputCostController = TextEditingController(
      text: (widget.initial?.referenceInputCostPerMillion ?? 0).toString(),
    );
    _referenceOutputCostController = TextEditingController(
      text: (widget.initial?.referenceOutputCostPerMillion ?? 0).toString(),
    );
    _currencyController = TextEditingController(
      text: widget.initial?.currency ?? 'USD',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    _apiVersionController.dispose();
    _maxTokensController.dispose();
    _actualInputCostController.dispose();
    _actualOutputCostController.dispose();
    _referenceInputCostController.dispose();
    _referenceOutputCostController.dispose();
    _currencyController.dispose();
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
                temperature: _temperature,
                maxTokens:
                    int.tryParse(_maxTokensController.text.trim()) ?? 2048,
                actualInputCostPerMillion:
                    double.tryParse(_actualInputCostController.text.trim()) ??
                    0,
                actualOutputCostPerMillion:
                    double.tryParse(_actualOutputCostController.text.trim()) ??
                    0,
                referenceInputCostPerMillion:
                    double.tryParse(
                      _referenceInputCostController.text.trim(),
                    ) ??
                    0,
                referenceOutputCostPerMillion:
                    double.tryParse(
                      _referenceOutputCostController.text.trim(),
                    ) ??
                    0,
                currency: _currencyController.text.trim().isEmpty
                    ? 'USD'
                    : _currencyController.text.trim(),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Temperature'),
            subtitle: Text(_temperature.toStringAsFixed(2)),
          ),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 1.5,
            divisions: 30,
            label: _temperature.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _temperature = value;
              });
            },
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
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency (e.g. USD, JPY)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualInputCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual Input Cost / 1M tokens',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualOutputCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual Output Cost / 1M tokens',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceInputCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Reference Input Cost / 1M tokens',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceOutputCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Reference Output Cost / 1M tokens',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage & Cost Summary',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input tokens: ${widget.initial!.inputTokensTotal}\n'
                      'Output tokens: ${widget.initial!.outputTokensTotal}\n'
                      'Actual: ${widget.initial!.currency} ${widget.initial!.actualCostEstimate.toStringAsFixed(4)}\n'
                      'Reference: ${widget.initial!.currency} ${widget.initial!.referenceCostEstimate.toStringAsFixed(4)}\n'
                      'Saved: ${widget.initial!.currency} ${widget.initial!.savedCostEstimate.toStringAsFixed(4)}',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .resetUsage(widget.initial!.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('トークン集計をリセットしました')),
                        );
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('トークン集計をリセット'),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    } on DioException catch (e) {
      if (e.response != null) {
        return '$name: ${e.response?.statusCode}';
      }
      return '$name: ${e.type.name}';
    } catch (e) {
      return '$name: Error';
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
