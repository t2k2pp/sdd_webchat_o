import 'model_endpoint.dart';

enum ArtifactSafetyMode { safe, interactive, trusted }

extension ArtifactSafetyModeX on ArtifactSafetyMode {
  String get id => switch (this) {
    ArtifactSafetyMode.safe => 'safe',
    ArtifactSafetyMode.interactive => 'interactive',
    ArtifactSafetyMode.trusted => 'trusted',
  };

  String get label => switch (this) {
    ArtifactSafetyMode.safe => 'Safe',
    ArtifactSafetyMode.interactive => 'Interactive',
    ArtifactSafetyMode.trusted => 'Trusted',
  };

  String get description => switch (this) {
    ArtifactSafetyMode.safe => 'JS無効 / 外部アクセス遮断（推奨）',
    ArtifactSafetyMode.interactive => 'JS有効 / 外部アクセス遮断',
    ArtifactSafetyMode.trusted => 'JS有効 / 外部アクセス許可',
  };

  static ArtifactSafetyMode fromId(String id) {
    return ArtifactSafetyMode.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ArtifactSafetyMode.safe,
    );
  }
}

class AppSettings {
  const AppSettings({
    this.searxngEnabledByDefault = false,
    this.maxSearchIterations = 3,
    this.confidenceThreshold = 0.75,
    this.searchTimeRange = 'month',
    this.searchSafeSearch = 1,
    this.searxngBaseUrl = 'http://192.168.1.40:8080',
    this.systemPrompt = '',
    this.ttsEnabled = true,
    this.ttsLanguage = 'ja-JP',
    this.ttsSpeechRate = 0.5,
    this.ttsVolume = 1.0,
    this.ttsPitch = 1.0,
    this.artifactSafetyMode = ArtifactSafetyMode.interactive,
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
  final bool ttsEnabled;
  final String ttsLanguage;
  final double ttsSpeechRate;
  final double ttsVolume;
  final double ttsPitch;
  final ArtifactSafetyMode artifactSafetyMode;
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
    bool? ttsEnabled,
    String? ttsLanguage,
    double? ttsSpeechRate,
    double? ttsVolume,
    double? ttsPitch,
    ArtifactSafetyMode? artifactSafetyMode,
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
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      artifactSafetyMode: artifactSafetyMode ?? this.artifactSafetyMode,
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
      'ttsEnabled': ttsEnabled,
      'ttsLanguage': ttsLanguage,
      'ttsSpeechRate': ttsSpeechRate,
      'ttsVolume': ttsVolume,
      'ttsPitch': ttsPitch,
      'artifactSafetyMode': artifactSafetyMode.id,
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
      ttsEnabled: json['ttsEnabled'] as bool? ?? true,
      ttsLanguage: json['ttsLanguage'] as String? ?? 'ja-JP',
      ttsSpeechRate: (json['ttsSpeechRate'] as num?)?.toDouble() ?? 0.5,
      ttsVolume: (json['ttsVolume'] as num?)?.toDouble() ?? 1.0,
      ttsPitch: (json['ttsPitch'] as num?)?.toDouble() ?? 1.0,
      artifactSafetyMode: ArtifactSafetyModeX.fromId(
        json['artifactSafetyMode'] as String? ?? 'interactive',
      ),
      selectedEndpointId:
          json['selectedEndpointId'] as String? ??
          (endpoints.isNotEmpty ? endpoints.first.id : 'ollama-local'),
      modelEndpoints: endpoints.isEmpty
          ? const AppSettings().modelEndpoints
          : endpoints,
    );
  }
}
