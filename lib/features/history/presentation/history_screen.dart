import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/widgets/app_drawer.dart';
import '../../chat/domain/conversation_thread.dart';
import '../../chat/presentation/providers/chat_controller.dart';
import '../../chat/presentation/providers/conversation_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(conversationListProvider);

    return Scaffold(
      drawer: const AppDrawer(currentPath: '/history'),
      appBar: AppBar(title: const Text('History')),
      body: asyncList.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('履歴はまだありません。'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final thread = items[index];
              final preview = thread.messages.isNotEmpty
                  ? thread.messages.last.content
                  : '(empty)';
              return ListTile(
                title: Text(thread.title),
                subtitle: Text(
                  '${thread.updatedAt.toLocal()}\n$preview',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () async {
                  await ref
                      .read(chatControllerProvider.notifier)
                      .loadConversation(thread);
                  if (context.mounted) {
                    context.go('/chat');
                  }
                },
                trailing: PopupMenuButton<_HistoryAction>(
                  onSelected: (action) async {
                    final text = _toMarkdown(thread);
                    switch (action) {
                      case _HistoryAction.copy:
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('コピーしました')),
                          );
                        }
                        break;
                      case _HistoryAction.export:
                        final file = await _exportToFile(thread, text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('保存: ${file.path}')),
                          );
                        }
                        break;
                      case _HistoryAction.share:
                        await SharePlus.instance.share(
                          ShareParams(text: text, subject: thread.title),
                        );
                        break;
                      case _HistoryAction.delete:
                        await ref
                            .read(conversationRepositoryProvider)
                            .delete(thread.id);
                        ref.invalidate(conversationListProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _HistoryAction.copy,
                      child: Text('コピー'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.export,
                      child: Text('エクスポート'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.share,
                      child: Text('共有'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.delete,
                      child: Text('削除'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('履歴読み込み失敗: $error')),
      ),
    );
  }
}

enum _HistoryAction { copy, export, share, delete }

String _toMarkdown(ConversationThread thread) {
  final buffer = StringBuffer();
  buffer.writeln('# ${thread.title}');
  buffer.writeln();
  for (final msg in thread.messages) {
    buffer.writeln('## ${msg.role}');
    buffer.writeln(msg.content);
    buffer.writeln();
  }
  return buffer.toString();
}

Future<File> _exportToFile(ConversationThread thread, String text) async {
  final dir = await getApplicationDocumentsDirectory();
  final safeTitle = thread.title.toString().replaceAll(
    RegExp(r'[^a-zA-Z0-9\-_]'),
    '_',
  );
  final file = File(
    p.join(
      dir.path,
      'export_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.md',
    ),
  );
  await file.writeAsString(text);
  return file;
}
