import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/features/chat/data/mcp_execution.dart';
import 'package:sdd_webchat_o/features/integrations/domain/mcp_server_definition.dart';

void main() {
  group('McpRequestParser', () {
    test('parses fenced mcp json', () {
      const parser = McpRequestParser();
      final request = parser.parse(
        '```mcp\n{"server":"local","tool":"search","arguments":{"q":"llm"}}\n```',
      );

      expect(request, isNotNull);
      expect(request!.server, 'local');
      expect(request.tool, 'search');
      expect(request.arguments['q'], 'llm');
    });

    test('returns null when payload has no tool fields', () {
      const parser = McpRequestParser();
      final request = parser.parse('hello world');
      expect(request, isNull);
    });
  });

  group('McpHttpExecutor', () {
    test('fails for non-http transport on mobile', () async {
      final executor = McpHttpExecutor();
      final result = await executor.execute(
        request: const McpToolCallRequest(server: 'local', tool: 'search'),
        servers: const [
          McpServerDefinition(
            id: 'm1',
            name: 'local',
            command: 'npx',
            args: ['-y', '@modelcontextprotocol/server-searxng'],
          ),
        ],
      );

      expect(result.success, isFalse);
      expect(result.output, contains('Unsupported MCP transport'));
    });
  });
}
