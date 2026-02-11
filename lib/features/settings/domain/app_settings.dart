import 'model_endpoint.dart';

class AppSettings {
  const AppSettings({
    this.searxngEnabledByDefault = false,
    this.maxSearchIterations = 3,
    this.confidenceThreshold = 0.75,
    this.searxngBaseUrl = 'http://192.168.1.40:8080',
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
  final String searxngBaseUrl;
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
    String? searxngBaseUrl,
    String? selectedEndpointId,
    List<ModelEndpoint>? modelEndpoints,
  }) {
    return AppSettings(
      searxngEnabledByDefault:
          searxngEnabledByDefault ?? this.searxngEnabledByDefault,
      maxSearchIterations: maxSearchIterations ?? this.maxSearchIterations,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      searxngBaseUrl: searxngBaseUrl ?? this.searxngBaseUrl,
      selectedEndpointId: selectedEndpointId ?? this.selectedEndpointId,
      modelEndpoints: modelEndpoints ?? this.modelEndpoints,
    );
  }
}
