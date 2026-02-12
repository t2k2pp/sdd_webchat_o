import 'dart:io';

import '../../projects/domain/project.dart';
import '../../projects/domain/project_attachment.dart';

class ProjectContextResolver {
  const ProjectContextResolver();

  Future<String> resolve({
    required Project project,
    required String userQuery,
  }) async {
    final q = userQuery.trim();
    if (project.attachments.isEmpty) {
      return '';
    }

    final docs = await _loadAttachments(project.attachments);
    if (docs.isEmpty) {
      return '';
    }

    return switch (project.knowledgeMode) {
      ProjectKnowledgeMode.rag => _resolveRag(
        docs: docs,
        query: q,
        topK: project.ragTopK,
        chunkSize: project.ragChunkSize,
      ),
      ProjectKnowledgeMode.agenticSearch => _resolveAgentic(
        docs: docs,
        query: q,
        topK: project.ragTopK,
        chunkSize: project.ragChunkSize,
        maxIterations: project.agenticMaxIterations,
        minConfidence: project.agenticConfidenceThreshold,
      ),
    };
  }

  Future<List<_Doc>> _loadAttachments(
    List<ProjectAttachment> attachments,
  ) async {
    final docs = <_Doc>[];
    for (final att in attachments.take(10)) {
      try {
        final file = File(att.path);
        if (!await file.exists()) {
          continue;
        }
        final text = await file.readAsString();
        final compact = text.replaceAll(RegExp(r'\r\n?'), '\n').trim();
        if (compact.isEmpty) {
          continue;
        }
        docs.add(_Doc(name: att.name, text: compact));
      } catch (_) {}
    }
    return docs;
  }

  String _resolveRag({
    required List<_Doc> docs,
    required String query,
    required int topK,
    required int chunkSize,
  }) {
    final results = _rankChunks(
      docs: docs,
      query: query,
      topK: topK,
      chunkSize: chunkSize,
    );
    if (results.isEmpty) {
      return '';
    }
    final lines = <String>['Project Knowledge (RAG):'];
    for (final result in results) {
      lines.add('- Source: ${result.source}');
      lines.add('  Score: ${result.score.toStringAsFixed(3)}');
      lines.add('  Snippet: ${result.snippet}');
    }
    return lines.join('\n');
  }

  String _resolveAgentic({
    required List<_Doc> docs,
    required String query,
    required int topK,
    required int chunkSize,
    required int maxIterations,
    required double minConfidence,
  }) {
    var currentQuery = query;
    var best = <_RankedChunk>[];
    var bestConfidence = 0.0;

    for (var i = 0; i < maxIterations.clamp(1, 6); i++) {
      final ranked = _rankChunks(
        docs: docs,
        query: currentQuery,
        topK: topK,
        chunkSize: chunkSize,
      );
      if (ranked.isNotEmpty) {
        final confidence = ranked.first.score.clamp(0, 1).toDouble();
        if (confidence > bestConfidence) {
          best = ranked;
          bestConfidence = confidence;
        }
        if (confidence >= minConfidence) {
          return _agenticOutput(
            ranked: ranked,
            confidence: confidence,
            iterations: i + 1,
            query: currentQuery,
          );
        }
        final expansion = _keywordsFrom(ranked.first.snippet);
        if (expansion.isNotEmpty) {
          currentQuery = '$currentQuery ${expansion.take(3).join(' ')}';
        }
      }
    }

    if (best.isEmpty) {
      return '';
    }
    return _agenticOutput(
      ranked: best,
      confidence: bestConfidence.toDouble(),
      iterations: maxIterations.clamp(1, 6),
      query: currentQuery,
    );
  }

  String _agenticOutput({
    required List<_RankedChunk> ranked,
    required double confidence,
    required int iterations,
    required String query,
  }) {
    final lines = <String>[
      'Project Knowledge (Agentic Search):',
      '- Iterations: $iterations',
      '- Confidence: ${confidence.toStringAsFixed(3)}',
      '- Final Query: $query',
    ];
    for (final result in ranked) {
      lines.add('- Source: ${result.source}');
      lines.add('  Score: ${result.score.toStringAsFixed(3)}');
      lines.add('  Snippet: ${result.snippet}');
    }
    return lines.join('\n');
  }

  List<_RankedChunk> _rankChunks({
    required List<_Doc> docs,
    required String query,
    required int topK,
    required int chunkSize,
  }) {
    final queryTokens = _tokens(query);
    if (queryTokens.isEmpty) {
      return const [];
    }
    final candidates = <_RankedChunk>[];
    for (final doc in docs) {
      final chunks = _chunkText(doc.text, chunkSize.clamp(300, 2400));
      for (final chunk in chunks) {
        final score = _score(queryTokens, chunk);
        if (score <= 0) {
          continue;
        }
        final snippet = chunk.length > 320
            ? '${chunk.substring(0, 320)}...'
            : chunk;
        candidates.add(
          _RankedChunk(source: doc.name, snippet: snippet, score: score),
        );
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(topK.clamp(1, 8)).toList();
  }

  List<String> _chunkText(String text, int chunkSize) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= chunkSize) {
      return [clean];
    }
    final overlap = (chunkSize / 4).round();
    final out = <String>[];
    var start = 0;
    while (start < clean.length) {
      final end = (start + chunkSize).clamp(0, clean.length);
      out.add(clean.substring(start, end));
      if (end >= clean.length) {
        break;
      }
      start = (end - overlap).clamp(0, clean.length);
    }
    return out;
  }

  Set<String> _tokens(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9_\u3040-\u30ff\u4e00-\u9faf]+'))
        .where((e) => e.trim().length >= 2)
        .map((e) => e.trim())
        .toSet();
  }

  double _score(Set<String> queryTokens, String chunk) {
    final chunkLower = chunk.toLowerCase();
    var hit = 0;
    for (final token in queryTokens) {
      if (chunkLower.contains(token)) {
        hit++;
      }
    }
    final base = hit / queryTokens.length;
    final phraseBoost = chunkLower.contains(queryTokens.join(' ')) ? 0.2 : 0;
    return (base + phraseBoost).clamp(0, 1.2).toDouble();
  }

  List<String> _keywordsFrom(String snippet) {
    final tokens = _tokens(snippet).toList();
    tokens.sort((a, b) => b.length.compareTo(a.length));
    return tokens.take(6).toList();
  }
}

class _Doc {
  const _Doc({required this.name, required this.text});

  final String name;
  final String text;
}

class _RankedChunk {
  const _RankedChunk({
    required this.source,
    required this.snippet,
    required this.score,
  });

  final String source;
  final String snippet;
  final double score;
}
