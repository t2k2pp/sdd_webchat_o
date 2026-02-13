import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../app/widgets/app_drawer.dart';
import '../../settings/domain/model_endpoint.dart';
import '../../settings/presentation/providers/settings_controller.dart';
import 'artifact_screen.dart';
import 'providers/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  int? _speakingAssistantIndex;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _speakingAssistantIndex = null;
      });
    });
    _tts.setErrorHandler((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speakingAssistantIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatControllerProvider, (previous, next) {
      final previousCount = previous?.messages.length ?? 0;
      if (next.messages.length == previousCount) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    });

    final chatState = ref.watch(chatControllerProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final selectedEndpoint = settings?.selectedEndpoint;
    final endpoints = settings?.modelEndpoints ?? const <ModelEndpoint>[];

    return Scaffold(
      drawer: const AppDrawer(currentPath: '/chat'),
      appBar: AppBar(
        title: Text(chatState.title),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(chatControllerProvider.notifier).startNewConversation();
            },
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: '新規会話',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const Center(child: Text('メッセージを送信すると会話が始まります。'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isUser = msg.role == 'user';
                      if (isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(msg.content),
                            ),
                          ),
                        );
                      }
                      return _AssistantMessage(
                        content: msg.content,
                        artifactHtml: msg.artifactHtml,
                        isSpeaking: _speakingAssistantIndex == index,
                        onToggleSpeak: () =>
                            _toggleSpeak(index: index, markdown: msg.content),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: _Composer(
                controller: _controller,
                isSending: chatState.isSending,
                onOpenOptions: () => _openChatOptions(
                  context: context,
                  searxngEnabled: chatState.searxngEnabled,
                  selectedEndpoint: selectedEndpoint,
                  endpoints: endpoints,
                ),
                onSend: () async {
                  final text = _controller.text;
                  _controller.clear();
                  await ref
                      .read(chatControllerProvider.notifier)
                      .sendMessage(text);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatOptions({
    required BuildContext context,
    required bool searxngEnabled,
    required ModelEndpoint? selectedEndpoint,
    required List<ModelEndpoint> endpoints,
  }) async {
    var localSearch = searxngEnabled;
    var localEndpointId = selectedEndpoint?.id;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: localSearch,
                      onChanged: (value) {
                        setModalState(() {
                          localSearch = value;
                        });
                        ref
                            .read(chatControllerProvider.notifier)
                            .toggleSearxng(value);
                      },
                      title: const Text('SearXNG'),
                      subtitle: Text(localSearch ? 'ON' : 'OFF'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: localEndpointId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Model Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      items: endpoints
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text('${e.name} (${e.provider.label})'),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) {
                        return endpoints
                            .map(
                              (e) => Text(
                                '${e.name} (${e.provider.label})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                            .toList();
                      },
                      onChanged: (value) async {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          localEndpointId = value;
                        });
                        await ref
                            .read(settingsControllerProvider.notifier)
                            .selectEndpoint(value);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleSpeak({
    required int index,
    required String markdown,
  }) async {
    if (_speakingAssistantIndex == index) {
      await _tts.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _speakingAssistantIndex = null;
      });
      return;
    }

    await _tts.stop();
    final plain = _markdownToPlainText(markdown);
    if (plain.trim().isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _speakingAssistantIndex = index;
    });
    await _tts.speak(plain);
  }

  String _markdownToPlainText(String markdown) {
    return markdown
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
        .replaceAll(RegExp(r'[*_>#-]'), ' ')
        .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onOpenOptions,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onOpenOptions;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              minLines: 1,
              maxLines: 7,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onOpenOptions,
                  icon: const Icon(Icons.tune),
                  tooltip: 'SearXNG / Model',
                ),
                const Spacer(),
                IconButton(
                  onPressed: isSending ? null : onSend,
                  tooltip: '送信',
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.content,
    required this.artifactHtml,
    required this.isSpeaking,
    required this.onToggleSpeak,
  });

  final String content;
  final String? artifactHtml;
  final bool isSpeaking;
  final VoidCallback onToggleSpeak;

  @override
  Widget build(BuildContext context) {
    final split = _splitSearchTrace(content);
    final traceStepCount = _countTraceSteps(split.trace);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: isSpeaking ? '読み上げ停止' : '読み上げ',
                  onPressed: onToggleSpeak,
                  icon: Icon(
                    isSpeaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: split.body,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: Theme.of(context).textTheme.bodyLarge,
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
          ),
          if (split.trace.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.travel_explore, size: 16),
                  label: const Text('Web検索利用'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('Steps: $traceStepCount'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
              leading: const Icon(Icons.travel_explore, size: 18),
              title: const Text('Search Trace'),
              subtitle: const Text('query / hits / urls'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarkdownBody(
                    data: split.trace,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(p: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: split.trace));
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search Traceをコピーしました')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Trace'),
                  ),
                ),
              ],
            ),
          ],
          if (artifactHtml != null) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ArtifactScreen(title: 'Artifact', html: artifactHtml!),
                  ),
                );
              },
              icon: const Icon(Icons.code),
              label: const Text('Open Artifact'),
            ),
          ],
        ],
      ),
    );
  }
}

({String body, String trace}) _splitSearchTrace(String markdown) {
  const marker = '\n## Search Trace';
  final idx = markdown.indexOf(marker);
  if (idx < 0) {
    return (body: markdown, trace: '');
  }
  final body = markdown.substring(0, idx).trim();
  final trace = markdown.substring(idx + 1).trim();
  return (body: body.isEmpty ? markdown.trim() : body, trace: trace);
}

int _countTraceSteps(String traceMarkdown) {
  if (traceMarkdown.trim().isEmpty) {
    return 0;
  }
  final reg = RegExp(r'^\s*-\s*Step\s+\d+:', multiLine: true);
  return reg.allMatches(traceMarkdown).length;
}
