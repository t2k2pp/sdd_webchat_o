import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/file_integration_repository.dart';
import '../../data/integration_repository.dart';
import '../../domain/mcp_server_definition.dart';
import '../../domain/skill_definition.dart';
import '../../domain/subagent_definition.dart';

final integrationRepositoryProvider = Provider<IntegrationRepository>((ref) {
  return FileIntegrationRepository();
});

final skillsProvider = FutureProvider<List<SkillDefinition>>((ref) async {
  return ref.read(integrationRepositoryProvider).listSkills();
});

final subAgentsProvider = FutureProvider<List<SubAgentDefinition>>((ref) async {
  return ref.read(integrationRepositoryProvider).listSubAgents();
});

final activeSubAgentIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(integrationRepositoryProvider).getActiveSubAgentId();
});

final mcpServersProvider = FutureProvider<List<McpServerDefinition>>((
  ref,
) async {
  return ref.read(integrationRepositoryProvider).listMcpServers();
});
