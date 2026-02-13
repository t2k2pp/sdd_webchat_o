import 'dart:io';
import 'dart:math' as math;

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

    final chunkSize = project.ragChunkSize.clamp(300, 2400);
    final index = _buildChunkIndex(docs: docs, chunkSize: chunkSize);
    if (index.chunks.isEmpty) {
      return '';
    }

    return switch (project.knowledgeMode) {
      ProjectKnowledgeMode.rag => _resolveRag(
        index: index,
        query: q,
        topK: project.ragTopK,
      ),
      ProjectKnowledgeMode.agenticSearch => _resolveAgentic(
        index: index,
        query: q,
        topK: project.ragTopK,
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
    required _ChunkIndex index,
    required String query,
    required int topK,
  }) {
    final results = _rankChunks(index: index, query: query, topK: topK);
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
    required _ChunkIndex index,
    required String query,
    required int topK,
    required int maxIterations,
    required double minConfidence,
  }) {
    var currentQuery = query;
    var best = <_RankedChunk>[];
    var bestConfidence = 0.0;

    for (var i = 0; i < maxIterations.clamp(1, 6); i++) {
      final ranked = _rankChunks(index: index, query: currentQuery, topK: topK);
      if (ranked.isNotEmpty) {
        final confidence = _scoreToConfidence(ranked.first.score);
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
    required _ChunkIndex index,
    required String query,
    required int topK,
  }) {
    final queryTerms = _tokenCounts(query);
    if (queryTerms.isEmpty) {
      return const [];
    }
    final candidates = <_RankedChunk>[];
    for (final chunk in index.chunks) {
      final score = _score(queryTerms, chunk, index);
      if (score <= 0) {
        continue;
      }
      final snippet = chunk.text.length > 320
          ? '${chunk.text.substring(0, 320)}...'
          : chunk.text;
      candidates.add(
        _RankedChunk(source: chunk.source, snippet: snippet, score: score),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(topK.clamp(1, 8)).toList();
  }

  _ChunkIndex _buildChunkIndex({
    required List<_Doc> docs,
    required int chunkSize,
  }) {
    final chunks = <_ChunkEntry>[];
    for (final doc in docs) {
      final slices = _chunkText(doc.text, chunkSize);
      for (final slice in slices) {
        final tokenFreq = _tokenCounts(slice);
        if (tokenFreq.isEmpty) {
          continue;
        }
        chunks.add(
          _ChunkEntry(
            source: doc.name,
            text: slice,
            tokenFreq: tokenFreq,
            tokenCount: tokenFreq.values.fold(0, (a, b) => a + b),
          ),
        );
      }
    }

    if (chunks.isEmpty) {
      return const _ChunkIndex(chunks: [], docFreq: {}, avgChunkLength: 1);
    }
    final df = <String, int>{};
    var totalLen = 0;
    for (final chunk in chunks) {
      totalLen += chunk.tokenCount;
      for (final token in chunk.tokenFreq.keys) {
        df.update(token, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final avgLen = totalLen / chunks.length;
    return _ChunkIndex(chunks: chunks, docFreq: df, avgChunkLength: avgLen);
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

  Map<String, int> _tokenCounts(String text) {
    final out = <String, int>{};
    for (final token
        in text
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9_\u3040-\u30ff\u4e00-\u9faf]+'))
            .map((e) => e.trim())
            .where((e) => e.length >= 2)) {
      if (_stopwords.contains(token)) {
        continue;
      }
      out.update(token, (v) => v + 1, ifAbsent: () => 1);
    }
    return out;
  }

  double _score(
    Map<String, int> queryTerms,
    _ChunkEntry chunk,
    _ChunkIndex index,
  ) {
    const k1 = 1.5;
    const b = 0.75;
    final n = index.chunks.length;
    if (n == 0) {
      return 0;
    }
    final norm = k1 * (1 - b + b * (chunk.tokenCount / index.avgChunkLength));
    var score = 0.0;
    for (final entry in queryTerms.entries) {
      final token = entry.key;
      final qf = entry.value;
      final tf = chunk.tokenFreq[token] ?? 0;
      if (tf == 0) {
        continue;
      }
      final df = index.docFreq[token] ?? 0;
      final idf = _idf(total: n, freq: df);
      final tfWeight = (tf * (k1 + 1)) / (tf + norm);
      score += idf * tfWeight * qf;
    }
    final phraseBoost = _phraseBoost(queryTerms.keys, chunk.text);
    return score + phraseBoost;
  }

  double _idf({required int total, required int freq}) {
    final num = (total - freq + 0.5);
    final den = (freq + 0.5);
    final raw = num <= 0 ? 0.0 : (num / den);
    return math.log((1 + raw).clamp(1, 1e9).toDouble());
  }

  double _phraseBoost(Iterable<String> queryTerms, String chunk) {
    final query = queryTerms.join(' ').trim();
    if (query.isEmpty) {
      return 0;
    }
    return chunk.toLowerCase().contains(query.toLowerCase()) ? 0.4 : 0.0;
  }

  double _scoreToConfidence(double score) {
    if (score <= 0) {
      return 0;
    }
    final normalized = 1 - (1 / (1 + score));
    return normalized.clamp(0, 1).toDouble();
  }

  List<String> _keywordsFrom(String snippet) {
    final tokens = _tokenCounts(snippet).keys.toList();
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

class _ChunkEntry {
  const _ChunkEntry({
    required this.source,
    required this.text,
    required this.tokenFreq,
    required this.tokenCount,
  });

  final String source;
  final String text;
  final Map<String, int> tokenFreq;
  final int tokenCount;
}

class _ChunkIndex {
  const _ChunkIndex({
    required this.chunks,
    required this.docFreq,
    required this.avgChunkLength,
  });

  final List<_ChunkEntry> chunks;
  final Map<String, int> docFreq;
  final double avgChunkLength;
}

const Set<String> _stopwords = {
  'the',
  'and',
  'for',
  'with',
  'from',
  'that',
  'this',
  'are',
  'was',
  'were',
  'have',
  'has',
  'had',
  'will',
  'shall',
  'can',
  'could',
  'would',
  'your',
  'you',
  'our',
  'about',
  'into',
  'onto',
  'http',
  'https',
  'www',
  'com',
  'org',
  'net',
  'です',
  'ます',
  'した',
  'して',
  'する',
  'いる',
  'ある',
  'ない',
  'こと',
  'ため',
  'よう',
  'これ',
  'それ',
  'また',
  'など',
  'から',
  'まで',
  'より',
  'について',
};
