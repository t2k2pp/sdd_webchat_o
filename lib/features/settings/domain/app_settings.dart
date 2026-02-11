class AppSettings {
  const AppSettings({
    this.searxngEnabledByDefault = false,
    this.maxSearchIterations = 3,
    this.confidenceThreshold = 0.75,
    this.defaultLlmProvider = 'ollama',
    this.ollamaModel = 'qwen3-coder-next',
    this.ollamaBaseUrl = 'http://192.168.1.40:11434',
    this.lmStudioBaseUrl = 'http://192.168.1.40:1234',
    this.llamaCppBaseUrl = 'http://192.168.1.40:8081',
    this.searxngBaseUrl = 'http://192.168.1.40:8080',
  });

  final bool searxngEnabledByDefault;
  final int maxSearchIterations;
  final double confidenceThreshold;
  final String defaultLlmProvider;
  final String ollamaModel;
  final String ollamaBaseUrl;
  final String lmStudioBaseUrl;
  final String llamaCppBaseUrl;
  final String searxngBaseUrl;

  AppSettings copyWith({
    bool? searxngEnabledByDefault,
    int? maxSearchIterations,
    double? confidenceThreshold,
    String? defaultLlmProvider,
    String? ollamaModel,
    String? ollamaBaseUrl,
    String? lmStudioBaseUrl,
    String? llamaCppBaseUrl,
    String? searxngBaseUrl,
  }) {
    return AppSettings(
      searxngEnabledByDefault:
          searxngEnabledByDefault ?? this.searxngEnabledByDefault,
      maxSearchIterations: maxSearchIterations ?? this.maxSearchIterations,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      defaultLlmProvider: defaultLlmProvider ?? this.defaultLlmProvider,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      lmStudioBaseUrl: lmStudioBaseUrl ?? this.lmStudioBaseUrl,
      llamaCppBaseUrl: llamaCppBaseUrl ?? this.llamaCppBaseUrl,
      searxngBaseUrl: searxngBaseUrl ?? this.searxngBaseUrl,
    );
  }
}
