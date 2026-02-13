import 'project_attachment.dart';

enum ProjectKnowledgeMode { rag, agenticSearch }

enum ProjectRetrievalMode { lexical, hybrid }

extension ProjectKnowledgeModeX on ProjectKnowledgeMode {
  String get id => switch (this) {
    ProjectKnowledgeMode.rag => 'rag',
    ProjectKnowledgeMode.agenticSearch => 'agentic_search',
  };

  String get label => switch (this) {
    ProjectKnowledgeMode.rag => 'RAG',
    ProjectKnowledgeMode.agenticSearch => 'Agentic Search',
  };

  static ProjectKnowledgeMode fromId(String id) {
    return ProjectKnowledgeMode.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ProjectKnowledgeMode.rag,
    );
  }
}

extension ProjectRetrievalModeX on ProjectRetrievalMode {
  String get id => switch (this) {
    ProjectRetrievalMode.lexical => 'lexical',
    ProjectRetrievalMode.hybrid => 'hybrid',
  };

  String get label => switch (this) {
    ProjectRetrievalMode.lexical => 'Lexical (BM25)',
    ProjectRetrievalMode.hybrid => 'Hybrid (BM25 + Embedding)',
  };

  static ProjectRetrievalMode fromId(String id) {
    return ProjectRetrievalMode.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ProjectRetrievalMode.lexical,
    );
  }
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.additionalSystemPrompt,
    required this.attachments,
    required this.updatedAt,
    this.knowledgeMode = ProjectKnowledgeMode.rag,
    this.retrievalMode = ProjectRetrievalMode.lexical,
    this.embeddingModel = '',
    this.ragTopK = 4,
    this.ragChunkSize = 800,
    this.agenticMaxIterations = 3,
    this.agenticConfidenceThreshold = 0.55,
  });

  final String id;
  final String name;
  final String additionalSystemPrompt;
  final List<ProjectAttachment> attachments;
  final DateTime updatedAt;
  final ProjectKnowledgeMode knowledgeMode;
  final ProjectRetrievalMode retrievalMode;
  final String embeddingModel;
  final int ragTopK;
  final int ragChunkSize;
  final int agenticMaxIterations;
  final double agenticConfidenceThreshold;

  Project copyWith({
    String? id,
    String? name,
    String? additionalSystemPrompt,
    List<ProjectAttachment>? attachments,
    DateTime? updatedAt,
    ProjectKnowledgeMode? knowledgeMode,
    ProjectRetrievalMode? retrievalMode,
    String? embeddingModel,
    int? ragTopK,
    int? ragChunkSize,
    int? agenticMaxIterations,
    double? agenticConfidenceThreshold,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      additionalSystemPrompt:
          additionalSystemPrompt ?? this.additionalSystemPrompt,
      attachments: attachments ?? this.attachments,
      updatedAt: updatedAt ?? this.updatedAt,
      knowledgeMode: knowledgeMode ?? this.knowledgeMode,
      retrievalMode: retrievalMode ?? this.retrievalMode,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      ragTopK: ragTopK ?? this.ragTopK,
      ragChunkSize: ragChunkSize ?? this.ragChunkSize,
      agenticMaxIterations: agenticMaxIterations ?? this.agenticMaxIterations,
      agenticConfidenceThreshold:
          agenticConfidenceThreshold ?? this.agenticConfidenceThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'additionalSystemPrompt': additionalSystemPrompt,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'knowledgeMode': knowledgeMode.id,
      'retrievalMode': retrievalMode.id,
      'embeddingModel': embeddingModel,
      'ragTopK': ragTopK,
      'ragChunkSize': ragChunkSize,
      'agenticMaxIterations': agenticMaxIterations,
      'agenticConfidenceThreshold': agenticConfidenceThreshold,
    };
  }

  static Project fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? const [];
    return Project(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Project',
      additionalSystemPrompt: json['additionalSystemPrompt'] as String? ?? '',
      attachments: rawAttachments
          .map((e) => ProjectAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      knowledgeMode: ProjectKnowledgeModeX.fromId(
        json['knowledgeMode'] as String? ?? 'rag',
      ),
      retrievalMode: ProjectRetrievalModeX.fromId(
        json['retrievalMode'] as String? ?? 'lexical',
      ),
      embeddingModel: json['embeddingModel'] as String? ?? '',
      ragTopK: (json['ragTopK'] as num?)?.toInt() ?? 4,
      ragChunkSize: (json['ragChunkSize'] as num?)?.toInt() ?? 800,
      agenticMaxIterations:
          (json['agenticMaxIterations'] as num?)?.toInt() ?? 3,
      agenticConfidenceThreshold:
          (json['agenticConfidenceThreshold'] as num?)?.toDouble() ?? 0.55,
    );
  }
}
