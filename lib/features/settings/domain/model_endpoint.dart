enum LlmProviderType { ollama, lmStudio, llamaCpp, gemini, azureOpenAi }

extension LlmProviderTypeX on LlmProviderType {
  String get id => switch (this) {
    LlmProviderType.ollama => 'ollama',
    LlmProviderType.lmStudio => 'lm_studio',
    LlmProviderType.llamaCpp => 'llama_cpp',
    LlmProviderType.gemini => 'gemini',
    LlmProviderType.azureOpenAi => 'azure_openai',
  };

  String get label => switch (this) {
    LlmProviderType.ollama => 'Ollama',
    LlmProviderType.lmStudio => 'LM Studio',
    LlmProviderType.llamaCpp => 'llama.cpp',
    LlmProviderType.gemini => 'Gemini API',
    LlmProviderType.azureOpenAi => 'Azure OpenAI',
  };

  static LlmProviderType fromId(String id) {
    return LlmProviderType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => LlmProviderType.ollama,
    );
  }
}

class ModelEndpoint {
  const ModelEndpoint({
    required this.id,
    required this.name,
    required this.provider,
    required this.baseUrl,
    required this.model,
    this.temperature = 0.4,
    this.maxTokens = 2048,
    this.apiKey = '',
    this.apiVersion = '2024-06-01',
  });

  final String id;
  final String name;
  final LlmProviderType provider;
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;
  final String apiKey;
  final String apiVersion;

  ModelEndpoint copyWith({
    String? id,
    String? name,
    LlmProviderType? provider,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    String? apiKey,
    String? apiVersion,
  }) {
    return ModelEndpoint(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      apiKey: apiKey ?? this.apiKey,
      apiVersion: apiVersion ?? this.apiVersion,
    );
  }
}
