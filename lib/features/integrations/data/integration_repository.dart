import '../domain/mcp_server_definition.dart';
import '../domain/skill_definition.dart';
import '../domain/subagent_definition.dart';

abstract interface class IntegrationRepository {
  Future<List<SkillDefinition>> listSkills();
  Future<void> upsertSkill(SkillDefinition skill);
  Future<void> deleteSkill(String id);

  Future<List<SubAgentDefinition>> listSubAgents();
  Future<void> upsertSubAgent(SubAgentDefinition subAgent);
  Future<void> deleteSubAgent(String id);
  Future<String?> getActiveSubAgentId();
  Future<void> setActiveSubAgentId(String? id);

  Future<List<McpServerDefinition>> listMcpServers();
  Future<void> upsertMcpServer(McpServerDefinition server);
  Future<void> deleteMcpServer(String id);
}
