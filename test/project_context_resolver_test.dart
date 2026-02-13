import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/features/chat/data/project_embedding_client.dart';
import 'package:sdd_webchat_o/features/chat/data/project_context_resolver.dart';
import 'package:sdd_webchat_o/features/projects/domain/project.dart';
import 'package:sdd_webchat_o/features/projects/domain/project_attachment.dart';

void main() {
  group('ProjectContextResolver', () {
    test('builds RAG context from matching attachment snippets', () async {
      final dir = await Directory.systemTemp.createTemp('rag_test_');
      final file = File('${dir.path}/readme.txt');
      await file.writeAsString(
        'Flutter app architecture with Riverpod and chat controller. '
        'This document explains project setup.',
      );

      final project = Project(
        id: 'p1',
        name: 'Demo',
        additionalSystemPrompt: '',
        attachments: [
          ProjectAttachment(id: 'a1', path: file.path, name: 'readme.txt'),
        ],
        updatedAt: DateTime.now(),
        knowledgeMode: ProjectKnowledgeMode.rag,
      );

      final context = await const ProjectContextResolver().resolve(
        project: project,
        userQuery: 'Riverpod architecture',
      );

      expect(context, contains('Project Knowledge (RAG):'));
      expect(context, contains('readme.txt'));
      await dir.delete(recursive: true);
    });

    test(
      'builds Agentic context with confidence and iteration metadata',
      () async {
        final dir = await Directory.systemTemp.createTemp('agentic_test_');
        final file = File('${dir.path}/notes.txt');
        await file.writeAsString(
          'SearXNG integration guide and agentic search workflow. '
          'Confidence threshold and max iteration tuning examples.',
        );

        final project = Project(
          id: 'p2',
          name: 'Demo2',
          additionalSystemPrompt: '',
          attachments: [
            ProjectAttachment(id: 'a2', path: file.path, name: 'notes.txt'),
          ],
          updatedAt: DateTime.now(),
          knowledgeMode: ProjectKnowledgeMode.agenticSearch,
          agenticMaxIterations: 2,
          agenticConfidenceThreshold: 0.2,
        );

        final context = await const ProjectContextResolver().resolve(
          project: project,
          userQuery: 'agentic workflow',
        );

        expect(context, contains('Project Knowledge (Agentic Search):'));
        expect(context, contains('Confidence:'));
        await dir.delete(recursive: true);
      },
    );

    test(
      'hybrid mode uses embedding client and returns ranked snippets',
      () async {
        final dir = await Directory.systemTemp.createTemp('hybrid_test_');
        final file = File('${dir.path}/hybrid.txt');
        await file.writeAsString(
          'alpha alpha project note. beta keyword is here. '
          'gamma details for architecture.',
        );

        final project = Project(
          id: 'p3',
          name: 'Hybrid',
          additionalSystemPrompt: '',
          attachments: [
            ProjectAttachment(id: 'a3', path: file.path, name: 'hybrid.txt'),
          ],
          updatedAt: DateTime.now(),
          knowledgeMode: ProjectKnowledgeMode.rag,
          retrievalMode: ProjectRetrievalMode.hybrid,
          embeddingModel: 'nomic-embed-text',
        );

        final context = await const ProjectContextResolver().resolve(
          project: project,
          userQuery: 'beta architecture',
          embeddingClient: _FakeEmbeddingClient(),
          embeddingModel: 'nomic-embed-text',
        );

        expect(context, contains('Project Knowledge (RAG):'));
        expect(context, contains('hybrid.txt'));
        await dir.delete(recursive: true);
      },
    );
  });
}

class _FakeEmbeddingClient implements ProjectEmbeddingClient {
  @override
  Future<List<List<double>>> embedTexts({
    required List<String> texts,
    required String model,
  }) async {
    return texts.map(_embed).toList(growable: false);
  }

  List<double> _embed(String text) {
    final lower = text.toLowerCase();
    return [
      lower.contains('alpha') ? 1 : 0,
      lower.contains('beta') ? 1 : 0,
      lower.contains('gamma') ? 1 : 0,
      lower.length / 1000,
    ];
  }
}
