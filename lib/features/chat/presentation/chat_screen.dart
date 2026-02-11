import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('SearXNG'),
              selected: chatState.searxngEnabled,
              onSelected: (value) {
                ref.read(chatControllerProvider.notifier).toggleSearxng(value);
              },
            ),
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
                            child: Text(msg.content),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'メッセージを入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: chatState.isSending
                        ? null
                        : () async {
                            final text = _controller.text;
                            _controller.clear();
                            await ref
                                .read(chatControllerProvider.notifier)
                                .sendMessage(text);
                          },
                    child: chatState.isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('送信'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
