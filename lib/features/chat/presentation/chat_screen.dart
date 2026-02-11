import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final selectedEndpoint = settings?.selectedEndpoint;

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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          color: isUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.content),
                                if (!isUser && msg.artifactHtml != null) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ArtifactScreen(
                                            title: 'Artifact',
                                            html: msg.artifactHtml!,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.code),
                                    label: const Text('Open Artifact'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (selectedEndpoint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Model: ${selectedEndpoint.name} (${selectedEndpoint.provider.label})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: _Composer(
                controller: _controller,
                isSending: chatState.isSending,
                searxngEnabled: chatState.searxngEnabled,
                onToggleSearxng: (enabled) {
                  ref
                      .read(chatControllerProvider.notifier)
                      .toggleSearxng(enabled);
                },
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
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.searxngEnabled,
    required this.onToggleSearxng,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool searxngEnabled;
  final ValueChanged<bool> onToggleSearxng;
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
                  onPressed: () => onToggleSearxng(!searxngEnabled),
                  icon: Icon(
                    Icons.travel_explore,
                    color: searxngEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: 'SearXNG ON/OFF',
                ),
                const SizedBox(width: 6),
                Text(
                  searxngEnabled ? 'SearXNG ON' : 'SearXNG OFF',
                  style: Theme.of(context).textTheme.bodySmall,
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
