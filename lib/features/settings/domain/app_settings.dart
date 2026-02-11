import 'model_endpoint.dart';

class AppSettings {
  const AppSettings({
    this.searxngEnabledByDefault = false,
    this.maxSearchIterations = 3,
    this.confidenceThreshold = 0.75,
    this.searchTimeRange = 'month',
    this.searchSafeSearch = 1,
    this.searxngBaseUrl = 'http://192.168.1.40:8080',
    this.systemPrompt = '',
    this.selectedEndpointId = 'ollama-local',
    this.modelEndpoints = const [
      ModelEndpoint(
        id: 'ollama-local',
        name: 'Local Ollama',
        provider: LlmProviderType.ollama,
        baseUrl: 'http://192.168.1.40:11434',
        model: 'qwen3-coder-next',
      ),
      ModelEndpoint(
        id: 'gemini-default',
        name: 'Gemini (placeholder)',
        provider: LlmProviderType.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com',
        model: 'gemini-1.5-flash',
      ),
      ModelEndpoint(
        id: 'azure-openai-default',
        name: 'Azure OpenAI (placeholder)',
        provider: LlmProviderType.azureOpenAi,
        baseUrl: 'https://your-resource.openai.azure.com',
        model: 'gpt-4o-mini',
      ),
    ],
  });

  final bool searxngEnabledByDefault;
  final int maxSearchIterations;
  final double confidenceThreshold;
  final String searchTimeRange;
  final int searchSafeSearch;
  final String searxngBaseUrl;
  final String systemPrompt;
  final String selectedEndpointId;
  final List<ModelEndpoint> modelEndpoints;

  ModelEndpoint? get selectedEndpoint {
    for (final endpoint in modelEndpoints) {
      if (endpoint.id == selectedEndpointId) {
        return endpoint;
      }
    }
    return modelEndpoints.isEmpty ? null : modelEndpoints.first;
  }

  AppSettings copyWith({
    bool? searxngEnabledByDefault,
    int? maxSearchIterations,
    double? confidenceThreshold,
    String? searchTimeRange,
    int? searchSafeSearch,
    String? searxngBaseUrl,
    String? systemPrompt,
    String? selectedEndpointId,
    List<ModelEndpoint>? modelEndpoints,
  }) {
    return AppSettings(
      searxngEnabledByDefault:
          searxngEnabledByDefault ?? this.searxngEnabledByDefault,
      maxSearchIterations: maxSearchIterations ?? this.maxSearchIterations,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      searchTimeRange: searchTimeRange ?? this.searchTimeRange,
      searchSafeSearch: searchSafeSearch ?? this.searchSafeSearch,
      searxngBaseUrl: searxngBaseUrl ?? this.searxngBaseUrl,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      selectedEndpointId: selectedEndpointId ?? this.selectedEndpointId,
      modelEndpoints: modelEndpoints ?? this.modelEndpoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searxngEnabledByDefault': searxngEnabledByDefault,
      'maxSearchIterations': maxSearchIterations,
      'confidenceThreshold': confidenceThreshold,
      'searchTimeRange': searchTimeRange,
      'searchSafeSearch': searchSafeSearch,
      'searxngBaseUrl': searxngBaseUrl,
      'systemPrompt': systemPrompt,
      'selectedEndpointId': selectedEndpointId,
      'modelEndpoints': modelEndpoints.map((e) => e.toJson()).toList(),
    };
  }

  static AppSettings fromJson(Map<String, dynamic> json) {
    final rawEndpoints = json['modelEndpoints'] as List<dynamic>? ?? const [];
    final endpoints = rawEndpoints
        .map((e) => ModelEndpoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return AppSettings(
      searxngEnabledByDefault:
          json['searxngEnabledByDefault'] as bool? ?? false,
      maxSearchIterations: (json['maxSearchIterations'] as num?)?.toInt() ?? 3,
      confidenceThreshold:
          (json['confidenceThreshold'] as num?)?.toDouble() ?? 0.75,
      searchTimeRange: json['searchTimeRange'] as String? ?? 'month',
      searchSafeSearch: (json['searchSafeSearch'] as num?)?.toInt() ?? 1,
      searxngBaseUrl:
          json['searxngBaseUrl'] as String? ?? 'http://192.168.1.40:8080',
      systemPrompt: json['systemPrompt'] as String? ?? '',
      selectedEndpointId:
          json['selectedEndpointId'] as String? ??
          (endpoints.isNotEmpty ? endpoints.first.id : 'ollama-local'),
      modelEndpoints: endpoints.isEmpty
          ? const AppSettings().modelEndpoints
          : endpoints,
    );
  }
}
