import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/logging/app_logger.dart';
import '../../integrations/domain/mcp_server_definition.dart';

class McpToolCallRequest {
  const McpToolCallRequest({
    required this.server,
    required this.tool,
    this.arguments = const {},
  });

  final String server;
  final String tool;
  final Map<String, dynamic> arguments;
}

class McpExecutionResult {
  const McpExecutionResult({
    required this.server,
    required this.tool,
    required this.success,
    required this.output,
  });

  final String server;
  final String tool;
  final bool success;
  final String output;
}

class McpRequestParser {
  const McpRequestParser();

  McpToolCallRequest? parse(String text) {
    final trimmed = text.trim();

    final fenced = RegExp(
      r'```(?:mcp|json)\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fenced != null) {
      final parsed = _decodeRequest(fenced.group(1) ?? '');
      if (parsed != null) {
        return parsed;
      }
    }

    return _decodeRequest(trimmed);
  }

  McpToolCallRequest? _decodeRequest(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final server = (json['server'] as String? ?? '').trim();
      final tool = (json['tool'] as String? ?? '').trim();
      final args = json['arguments'];
      final normalizedArgs = args is Map<String, dynamic>
          ? args
          : <String, dynamic>{};
      if (server.isEmpty || tool.isEmpty) {
        return null;
      }
      return McpToolCallRequest(
        server: server,
        tool: tool,
        arguments: normalizedArgs,
      );
    } catch (e, s) {
      AppLogger.warning('Failed to parse MCP request JSON', e, s);
      return null;
    }
  }
}

class McpHttpExecutor {
  McpHttpExecutor({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<McpExecutionResult> execute({
    required McpToolCallRequest request,
    required List<McpServerDefinition> servers,
  }) async {
    final server = _resolveServer(request.server, servers);
    if (server == null) {
      return McpExecutionResult(
        server: request.server,
        tool: request.tool,
        success: false,
        output: 'MCP server not found or disabled: ${request.server}',
      );
    }

    final baseUrl = server.command.trim();
    if (!(baseUrl.startsWith('http://') || baseUrl.startsWith('https://'))) {
      return McpExecutionResult(
        server: server.name,
        tool: request.tool,
        success: false,
        output:
            'Unsupported MCP transport for mobile: ${server.command}. Use HTTP/HTTPS bridge URL in Command.',
      );
    }

    final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/tools/call';
    try {
      final response = await _dio.post<Object?>(
        url,
        data: {'name': request.tool, 'arguments': request.arguments},
        options: Options(
          headers: {...server.env, 'content-type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final output = _normalizeOutput(response.data);
      return McpExecutionResult(
        server: server.name,
        tool: request.tool,
        success: true,
        output: output,
      );
    } catch (error, stackTrace) {
      AppLogger.warning('MCP HTTP call failed', error, stackTrace);
      return McpExecutionResult(
        server: server.name,
        tool: request.tool,
        success: false,
        output: 'MCP call failed: $error',
      );
    }
  }

  McpServerDefinition? _resolveServer(
    String selector,
    List<McpServerDefinition> servers,
  ) {
    final key = selector.trim().toLowerCase();
    for (final server in servers) {
      if (!server.enabled) {
        continue;
      }
      if (server.id.toLowerCase() == key || server.name.toLowerCase() == key) {
        return server;
      }
    }
    return null;
  }

  String _normalizeOutput(Object? data) {
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final content = data['content'];
      if (content is String) {
        return content;
      }
      final result = data['result'];
      if (result is String) {
        return result;
      }
    }
    return jsonEncode(data);
  }
}
