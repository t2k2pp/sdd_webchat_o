import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/mcp_server_definition.dart';
import '../domain/skill_definition.dart';
import '../domain/subagent_definition.dart';
import 'providers/integration_providers.dart';

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Skills'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const _SkillsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Sub Agents'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const _SubAgentsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('MCP Servers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _McpServersPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillsPage extends ConsumerWidget {
  const _SkillsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            onPressed: () async {
              final imported = await _pickSkillArchive(context);
              if (imported == null) {
                return;
              }
              await ref
                  .read(integrationRepositoryProvider)
                  .upsertSkill(imported);
              ref.invalidate(skillsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('インポート完了: ${imported.name}')),
                );
              }
            },
            icon: const Icon(Icons.file_open_outlined),
            tooltip: '.skill/.zip をインポート',
          ),
          IconButton(
            onPressed: () async {
              final skill = await _showSkillDialog(context);
              if (skill != null) {
                await ref
                    .read(integrationRepositoryProvider)
                    .upsertSkill(skill);
                ref.invalidate(skillsProvider);
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: skillsAsync.when(
        data: (items) => ListView(
          children: items.map((skill) {
            return SwitchListTile(
              title: Text(skill.name),
              subtitle: Text(
                skill.sourceUrl.isEmpty
                    ? skill.content
                    : '${skill.sourceUrl}\n${skill.content}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              value: skill.enabled,
              onChanged: (value) async {
                await ref
                    .read(integrationRepositoryProvider)
                    .upsertSkill(skill.copyWith(enabled: value));
                ref.invalidate(skillsProvider);
              },
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(integrationRepositoryProvider)
                      .deleteSkill(skill.id);
                  ref.invalidate(skillsProvider);
                },
              ),
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込み失敗: $error')),
      ),
    );
  }
}

class _SubAgentsPage extends ConsumerWidget {
  const _SubAgentsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subAgentsProvider);
    final activeAsync = ref.watch(activeSubAgentIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub Agents'),
        actions: [
          IconButton(
            onPressed: () async {
              final sub = await _showSubAgentDialog(context);
              if (sub != null) {
                await ref
                    .read(integrationRepositoryProvider)
                    .upsertSubAgent(sub);
                ref.invalidate(subAgentsProvider);
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: subAsync.when(
        data: (subAgents) => activeAsync.when(
          data: (activeId) => ListView(
            children: subAgents.map((sub) {
              final selected = sub.id == activeId;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(sub.name),
                subtitle: Text(
                  sub.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  await ref
                      .read(integrationRepositoryProvider)
                      .setActiveSubAgentId(sub.id);
                  ref.invalidate(activeSubAgentIdProvider);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(integrationRepositoryProvider)
                        .deleteSubAgent(sub.id);
                    ref.invalidate(subAgentsProvider);
                    ref.invalidate(activeSubAgentIdProvider);
                  },
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('読み込み失敗: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込み失敗: $error')),
      ),
    );
  }
}

class _McpServersPage extends ConsumerWidget {
  const _McpServersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mcpAsync = ref.watch(mcpServersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Servers'),
        actions: [
          IconButton(
            onPressed: () async {
              final server = await _showMcpDialog(context);
              if (server != null) {
                await ref
                    .read(integrationRepositoryProvider)
                    .upsertMcpServer(server);
                ref.invalidate(mcpServersProvider);
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: mcpAsync.when(
        data: (servers) => ListView(
          children: servers.map((server) {
            return SwitchListTile(
              title: Text(server.name),
              subtitle: Text(
                '${server.command} ${server.args.join(' ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              value: server.enabled,
              onChanged: (value) async {
                await ref
                    .read(integrationRepositoryProvider)
                    .upsertMcpServer(server.copyWith(enabled: value));
                ref.invalidate(mcpServersProvider);
              },
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(integrationRepositoryProvider)
                      .deleteMcpServer(server.id);
                  ref.invalidate(mcpServersProvider);
                },
              ),
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込み失敗: $error')),
      ),
    );
  }
}

Future<SkillDefinition?> _showSkillDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final urlController = TextEditingController();
  final contentController = TextEditingController();

  final result = await showDialog<SkillDefinition>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add Skill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Source URL (optional)',
                ),
              ),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    if (url.isEmpty) return;
                    try {
                      final res = await Dio().get<String>(url);
                      contentController.text = res.data ?? '';
                    } catch (e, s) {
                      AppLogger.warning(
                        'Failed to fetch skill content from URL',
                        e,
                        s,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URLからの取得に失敗しました')),
                      );
                    }
                  },
                  child: const Text('URLから取得'),
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
              Navigator.of(context).pop(
                SkillDefinition(
                  id: 'sk_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
                  name: nameController.text.trim().isEmpty
                      ? 'Skill'
                      : nameController.text.trim(),
                  sourceUrl: urlController.text.trim(),
                  content: contentController.text,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  nameController.dispose();
  urlController.dispose();
  contentController.dispose();
  return result;
}

Future<SkillDefinition?> _pickSkillArchive(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['skill', 'zip'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  final picked = result.files.first;
  final fileName = picked.name;
  final bytes =
      picked.bytes ??
      (picked.path != null ? await File(picked.path!).readAsBytes() : null);
  if (bytes == null) {
    return null;
  }
  return _parseSkillArchive(bytes, fileName);
}

SkillDefinition? _parseSkillArchive(Uint8List bytes, String fileName) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);

  ArchiveFile? skillFile;
  for (final f in archive.files) {
    if (f.isFile && f.name.toLowerCase().endsWith('skill.md')) {
      skillFile = f;
      break;
    }
  }
  if (skillFile == null) {
    for (final f in archive.files) {
      if (f.isFile &&
          (f.name.toLowerCase().endsWith('.md') ||
              f.name.toLowerCase().endsWith('.txt'))) {
        skillFile = f;
        break;
      }
    }
  }

  if (skillFile == null || !skillFile.isFile) {
    return null;
  }

  final content = _toString(skillFile.content);
  if (content.trim().isEmpty) {
    return null;
  }

  final parsedName = _extractFrontMatterName(content);
  final fallback = fileName.replaceAll(
    RegExp(r'\.(skill|zip)$', caseSensitive: false),
    '',
  );

  return SkillDefinition(
    id: 'sk_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
    name: parsedName.isEmpty ? fallback : parsedName,
    content: content,
    sourceUrl: fileName,
    enabled: true,
  );
}

String _toString(Object content) {
  if (content is String) {
    return content;
  }
  if (content is List<int>) {
    return String.fromCharCodes(content);
  }
  if (content is Uint8List) {
    return String.fromCharCodes(content);
  }
  return content.toString();
}

String _extractFrontMatterName(String content) {
  final lines = content.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return '';
  }
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == '---') {
      break;
    }
    if (line.toLowerCase().startsWith('name:')) {
      final raw = line.substring(5).trim();
      return raw.replaceAll('"', '').replaceAll("'", '');
    }
  }
  return '';
}

Future<SubAgentDefinition?> _showSubAgentDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final instructionController = TextEditingController();
  final sourceController = TextEditingController();
  final result = await showDialog<SubAgentDefinition>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add SubAgent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source URL (optional)',
                ),
              ),
              TextField(
                controller: instructionController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Instruction'),
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
              Navigator.of(context).pop(
                SubAgentDefinition(
                  id: 'sa_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
                  name: nameController.text.trim().isEmpty
                      ? 'SubAgent'
                      : nameController.text.trim(),
                  sourceUrl: sourceController.text.trim(),
                  instruction: instructionController.text,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  nameController.dispose();
  instructionController.dispose();
  sourceController.dispose();
  return result;
}

Future<McpServerDefinition?> _showMcpDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final cmdController = TextEditingController();
  final argsController = TextEditingController();
  final envController = TextEditingController();
  final result = await showDialog<McpServerDefinition>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Add MCP Server'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: cmdController,
                decoration: const InputDecoration(labelText: 'Command'),
              ),
              TextField(
                controller: argsController,
                decoration: const InputDecoration(
                  labelText: 'Args (space separated)',
                ),
              ),
              TextField(
                controller: envController,
                decoration: const InputDecoration(
                  labelText: 'Env (KEY=VALUE,comma)',
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
              final env = <String, String>{};
              for (final pair in envController.text.split(',')) {
                final p = pair.trim();
                if (p.isEmpty || !p.contains('=')) continue;
                final k = p.split('=').first.trim();
                final v = p.substring(p.indexOf('=') + 1).trim();
                if (k.isNotEmpty) {
                  env[k] = v;
                }
              }

              Navigator.of(context).pop(
                McpServerDefinition(
                  id: 'mcp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
                  name: nameController.text.trim().isEmpty
                      ? 'MCP'
                      : nameController.text.trim(),
                  command: cmdController.text.trim(),
                  args: argsController.text
                      .split(' ')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  env: env,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  nameController.dispose();
  cmdController.dispose();
  argsController.dispose();
  envController.dispose();
  return result;
}
