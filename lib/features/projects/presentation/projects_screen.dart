import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/app_drawer.dart';
import '../domain/project.dart';
import '../domain/project_attachment.dart';
import 'providers/project_providers.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final activeIdAsync = ref.watch(activeProjectIdProvider);

    return Scaffold(
      drawer: const AppDrawer(currentPath: '/projects'),
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            onPressed: () async {
              final created = await Navigator.of(context).push<Project>(
                MaterialPageRoute(builder: (_) => const _ProjectEditPage()),
              );
              if (created != null) {
                await ref.read(projectRepositoryProvider).upsert(created);
                await ref
                    .read(projectRepositoryProvider)
                    .setActiveProjectId(created.id);
                ref.invalidate(projectListProvider);
                ref.invalidate(activeProjectIdProvider);
              }
            },
            icon: const Icon(Icons.add),
            tooltip: '新規プロジェクト',
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          return activeIdAsync.when(
            data: (activeId) {
              if (projects.isEmpty) {
                return const Center(child: Text('プロジェクトはまだありません。'));
              }
              return ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final selected = project.id == activeId;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(project.name),
                    subtitle: Text(
                      '添付: ${project.attachments.length}件\n'
                      'Mode: ${project.knowledgeMode.label}\n'
                      '${project.additionalSystemPrompt.isEmpty ? '(追加プロンプトなし)' : project.additionalSystemPrompt}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    onTap: () async {
                      await ref
                          .read(projectRepositoryProvider)
                          .setActiveProjectId(project.id);
                      ref.invalidate(activeProjectIdProvider);
                    },
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final edited = await Navigator.of(context)
                                .push<Project>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        _ProjectEditPage(initial: project),
                                  ),
                                );
                            if (edited != null) {
                              await ref
                                  .read(projectRepositoryProvider)
                                  .upsert(edited);
                              ref.invalidate(projectListProvider);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(projectRepositoryProvider)
                                .delete(project.id);
                            ref.invalidate(projectListProvider);
                            ref.invalidate(activeProjectIdProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('読み込み失敗: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込み失敗: $error')),
      ),
    );
  }
}

class _ProjectEditPage extends StatefulWidget {
  const _ProjectEditPage({this.initial});

  final Project? initial;

  @override
  State<_ProjectEditPage> createState() => _ProjectEditPageState();
}

class _ProjectEditPageState extends State<_ProjectEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _promptController;
  late final TextEditingController _ragTopKController;
  late final TextEditingController _ragChunkSizeController;
  late final TextEditingController _agenticIterationsController;
  late final TextEditingController _agenticConfidenceController;
  late List<ProjectAttachment> _attachments;
  late ProjectKnowledgeMode _knowledgeMode;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _promptController = TextEditingController(
      text: widget.initial?.additionalSystemPrompt ?? '',
    );
    _ragTopKController = TextEditingController(
      text: (widget.initial?.ragTopK ?? 4).toString(),
    );
    _ragChunkSizeController = TextEditingController(
      text: (widget.initial?.ragChunkSize ?? 800).toString(),
    );
    _agenticIterationsController = TextEditingController(
      text: (widget.initial?.agenticMaxIterations ?? 3).toString(),
    );
    _agenticConfidenceController = TextEditingController(
      text: (widget.initial?.agenticConfidenceThreshold ?? 0.55).toString(),
    );
    _attachments = [...(widget.initial?.attachments ?? const [])];
    _knowledgeMode = widget.initial?.knowledgeMode ?? ProjectKnowledgeMode.rag;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _ragTopKController.dispose();
    _ragChunkSizeController.dispose();
    _agenticIterationsController.dispose();
    _agenticConfidenceController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    if (file.path == null || file.path!.isEmpty) {
      return;
    }
    setState(() {
      _attachments = [
        ..._attachments,
        ProjectAttachment(
          id: 'att_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
          path: file.path!,
          name: file.name,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'プロジェクト編集' : '新規プロジェクト'),
        actions: [
          TextButton(
            onPressed: () {
              final project = Project(
                id:
                    widget.initial?.id ??
                    'prj_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
                name: _nameController.text.trim().isEmpty
                    ? 'Project'
                    : _nameController.text.trim(),
                additionalSystemPrompt: _promptController.text,
                attachments: _attachments,
                updatedAt: DateTime.now(),
                knowledgeMode: _knowledgeMode,
                ragTopK: int.tryParse(_ragTopKController.text.trim()) ?? 4,
                ragChunkSize:
                    int.tryParse(_ragChunkSizeController.text.trim()) ?? 800,
                agenticMaxIterations:
                    int.tryParse(_agenticIterationsController.text.trim()) ?? 3,
                agenticConfidenceThreshold:
                    double.tryParse(_agenticConfidenceController.text.trim()) ??
                    0.55,
              );
              Navigator.of(context).pop(project);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProjectKnowledgeMode>(
            initialValue: _knowledgeMode,
            decoration: const InputDecoration(
              labelText: 'Knowledge Search Mode',
              border: OutlineInputBorder(),
            ),
            items: ProjectKnowledgeMode.values
                .map(
                  (e) => DropdownMenuItem<ProjectKnowledgeMode>(
                    value: e,
                    child: Text(e.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _knowledgeMode = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ragTopKController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RAG TopK',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ragChunkSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'RAG Chunk Size',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _agenticIterationsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Agentic Iterations',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _agenticConfidenceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Agentic Confidence (0-1)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Additional System Prompt',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Attachments',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_attachments.isEmpty)
            const Text('添付ファイルはありません。')
          else
            ..._attachments.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text(
                  a.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _attachments = _attachments
                          .where((e) => e.id != a.id)
                          .toList();
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
