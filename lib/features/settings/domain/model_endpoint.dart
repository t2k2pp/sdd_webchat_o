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
    this.inputTokensTotal = 0,
    this.outputTokensTotal = 0,
    this.actualInputCostPerMillion = 0,
    this.actualOutputCostPerMillion = 0,
    this.referenceInputCostPerMillion = 0,
    this.referenceOutputCostPerMillion = 0,
    this.currency = 'USD',
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
  final int inputTokensTotal;
  final int outputTokensTotal;
  final double actualInputCostPerMillion;
  final double actualOutputCostPerMillion;
  final double referenceInputCostPerMillion;
  final double referenceOutputCostPerMillion;
  final String currency;
  final String apiKey;
  final String apiVersion;

  double get actualCostEstimate {
    return (inputTokensTotal / 1000000) * actualInputCostPerMillion +
        (outputTokensTotal / 1000000) * actualOutputCostPerMillion;
  }

  double get referenceCostEstimate {
    return (inputTokensTotal / 1000000) * referenceInputCostPerMillion +
        (outputTokensTotal / 1000000) * referenceOutputCostPerMillion;
  }

  double get savedCostEstimate => referenceCostEstimate - actualCostEstimate;

  ModelEndpoint copyWith({
    String? id,
    String? name,
    LlmProviderType? provider,
    String? baseUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    int? inputTokensTotal,
    int? outputTokensTotal,
    double? actualInputCostPerMillion,
    double? actualOutputCostPerMillion,
    double? referenceInputCostPerMillion,
    double? referenceOutputCostPerMillion,
    String? currency,
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
      inputTokensTotal: inputTokensTotal ?? this.inputTokensTotal,
      outputTokensTotal: outputTokensTotal ?? this.outputTokensTotal,
      actualInputCostPerMillion:
          actualInputCostPerMillion ?? this.actualInputCostPerMillion,
      actualOutputCostPerMillion:
          actualOutputCostPerMillion ?? this.actualOutputCostPerMillion,
      referenceInputCostPerMillion:
          referenceInputCostPerMillion ?? this.referenceInputCostPerMillion,
      referenceOutputCostPerMillion:
          referenceOutputCostPerMillion ?? this.referenceOutputCostPerMillion,
      currency: currency ?? this.currency,
      apiKey: apiKey ?? this.apiKey,
      apiVersion: apiVersion ?? this.apiVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.id,
      'baseUrl': baseUrl,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'inputTokensTotal': inputTokensTotal,
      'outputTokensTotal': outputTokensTotal,
      'actualInputCostPerMillion': actualInputCostPerMillion,
      'actualOutputCostPerMillion': actualOutputCostPerMillion,
      'referenceInputCostPerMillion': referenceInputCostPerMillion,
      'referenceOutputCostPerMillion': referenceOutputCostPerMillion,
      'currency': currency,
      'apiKey': apiKey,
      'apiVersion': apiVersion,
    };
  }

  static ModelEndpoint fromJson(Map<String, dynamic> json) {
    return ModelEndpoint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Endpoint',
      provider: LlmProviderTypeX.fromId(
        json['provider'] as String? ?? 'ollama',
      ),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.4,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2048,
      inputTokensTotal: (json['inputTokensTotal'] as num?)?.toInt() ?? 0,
      outputTokensTotal: (json['outputTokensTotal'] as num?)?.toInt() ?? 0,
      actualInputCostPerMillion:
          (json['actualInputCostPerMillion'] as num?)?.toDouble() ?? 0,
      actualOutputCostPerMillion:
          (json['actualOutputCostPerMillion'] as num?)?.toDouble() ?? 0,
      referenceInputCostPerMillion:
          (json['referenceInputCostPerMillion'] as num?)?.toDouble() ?? 0,
      referenceOutputCostPerMillion:
          (json['referenceOutputCostPerMillion'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      apiKey: json['apiKey'] as String? ?? '',
      apiVersion: json['apiVersion'] as String? ?? '2024-06-01',
    );
  }
}
