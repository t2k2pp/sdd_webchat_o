import 'package:dio/dio.dart';

import '../../settings/domain/model_endpoint.dart';

abstract class ProjectEmbeddingClient {
  Future<List<List<double>>> embedTexts({
    required List<String> texts,
    required String model,
  });
}

class EndpointEmbeddingClient implements ProjectEmbeddingClient {
  EndpointEmbeddingClient({required Dio dio, required ModelEndpoint endpoint})
    : _dio = dio,
      _endpoint = endpoint;

  final Dio _dio;
  final ModelEndpoint _endpoint;

  static EndpointEmbeddingClient? forEndpoint(Dio dio, ModelEndpoint endpoint) {
    return switch (endpoint.provider) {
      LlmProviderType.ollama ||
      LlmProviderType.lmStudio ||
      LlmProviderType.llamaCpp => EndpointEmbeddingClient(
        dio: dio,
        endpoint: endpoint,
      ),
      _ => null,
    };
  }

  @override
  Future<List<List<double>>> embedTexts({
    required List<String> texts,
    required String model,
  }) async {
    final compact = texts.map((e) => e.trim()).where((e) => e.isNotEmpty);
    final inputs = compact.toList(growable: false);
    if (inputs.isEmpty) {
      return const [];
    }
    switch (_endpoint.provider) {
      case LlmProviderType.ollama:
        return _embedWithOllama(inputs: inputs, model: model);
      case LlmProviderType.lmStudio:
      case LlmProviderType.llamaCpp:
        return _embedWithOpenAiCompatible(inputs: inputs, model: model);
      case LlmProviderType.gemini:
      case LlmProviderType.azureOpenAi:
        return const [];
    }
  }

  Future<List<List<double>>> _embedWithOllama({
    required List<String> inputs,
    required String model,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/embed',
      data: {'model': model, 'input': inputs},
    );
    final data = response.data ?? const <String, dynamic>{};
    final raw = data['embeddings'];
    if (raw is List) {
      return _parseEmbeddings(raw);
    }
    final single = data['embedding'];
    if (single is List) {
      return [_parseVector(single)];
    }
    return const [];
  }

  Future<List<List<double>>> _embedWithOpenAiCompatible({
    required List<String> inputs,
    required String model,
  }) async {
    final headers = <String, String>{};
    if (_endpoint.apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_endpoint.apiKey.trim()}';
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/embeddings',
      data: {'model': model, 'input': inputs},
      options: Options(headers: headers),
    );
    final data = response.data ?? const <String, dynamic>{};
    final rows = data['data'];
    if (rows is! List) {
      return const [];
    }
    final vectors = <List<double>>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      final emb = row['embedding'];
      if (emb is List) {
        vectors.add(_parseVector(emb));
      }
    }
    return vectors;
  }

  List<List<double>> _parseEmbeddings(List<dynamic> rows) {
    final out = <List<double>>[];
    for (final row in rows) {
      if (row is List) {
        out.add(_parseVector(row));
      }
    }
    return out;
  }

  List<double> _parseVector(List<dynamic> raw) {
    return raw.map((e) => (e as num?)?.toDouble() ?? 0).toList(growable: false);
  }
}
