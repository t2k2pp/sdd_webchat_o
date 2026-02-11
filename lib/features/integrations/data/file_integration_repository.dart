import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/mcp_server_definition.dart';
import '../domain/skill_definition.dart';
import '../domain/subagent_definition.dart';
import 'integration_repository.dart';

class FileIntegrationRepository implements IntegrationRepository {
  File? _skillsFile;
  File? _subAgentsFile;
  File? _mcpServersFile;
  File? _activeSubAgentFile;

  @override
  Future<List<SkillDefinition>> listSkills() async {
    final file = await _resolveSkillsFile();
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return decoded
        .map((e) => SkillDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsertSkill(SkillDefinition skill) async {
    final items = await listSkills();
    final idx = items.indexWhere((e) => e.id == skill.id);
    if (idx >= 0) {
      items[idx] = skill;
    } else {
      items.add(skill);
    }
    final file = await _resolveSkillsFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteSkill(String id) async {
    final items = await listSkills();
    items.removeWhere((e) => e.id == id);
    final file = await _resolveSkillsFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<List<SubAgentDefinition>> listSubAgents() async {
    final file = await _resolveSubAgentsFile();
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return decoded
        .map((e) => SubAgentDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsertSubAgent(SubAgentDefinition subAgent) async {
    final items = await listSubAgents();
    final idx = items.indexWhere((e) => e.id == subAgent.id);
    if (idx >= 0) {
      items[idx] = subAgent;
    } else {
      items.add(subAgent);
    }
    final file = await _resolveSubAgentsFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteSubAgent(String id) async {
    final items = await listSubAgents();
    items.removeWhere((e) => e.id == id);
    final file = await _resolveSubAgentsFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
    final active = await getActiveSubAgentId();
    if (active == id) {
      await setActiveSubAgentId(null);
    }
  }

  @override
  Future<String?> getActiveSubAgentId() async {
    final file = await _resolveActiveSubAgentFile();
    final raw = await file.readAsString();
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> setActiveSubAgentId(String? id) async {
    final file = await _resolveActiveSubAgentFile();
    await file.writeAsString(id ?? '');
  }

  @override
  Future<List<McpServerDefinition>> listMcpServers() async {
    final file = await _resolveMcpServersFile();
    final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
    return decoded
        .map((e) => McpServerDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsertMcpServer(McpServerDefinition server) async {
    final items = await listMcpServers();
    final idx = items.indexWhere((e) => e.id == server.id);
    if (idx >= 0) {
      items[idx] = server;
    } else {
      items.add(server);
    }
    final file = await _resolveMcpServersFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteMcpServer(String id) async {
    final items = await listMcpServers();
    items.removeWhere((e) => e.id == id);
    final file = await _resolveMcpServersFile();
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<File> _resolveSkillsFile() async {
    _skillsFile ??= await _ensureFile('skills_registry.json', '[]');
    return _skillsFile!;
  }

  Future<File> _resolveSubAgentsFile() async {
    _subAgentsFile ??= await _ensureFile('subagents_registry.json', '[]');
    return _subAgentsFile!;
  }

  Future<File> _resolveMcpServersFile() async {
    _mcpServersFile ??= await _ensureFile('mcp_servers_registry.json', '[]');
    return _mcpServersFile!;
  }

  Future<File> _resolveActiveSubAgentFile() async {
    _activeSubAgentFile ??= await _ensureFile('active_subagent.txt', '');
    return _activeSubAgentFile!;
  }

  Future<File> _ensureFile(String name, String initialContent) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, name));
    if (!await file.exists()) {
      await file.writeAsString(initialContent);
    }
    return file;
  }
}
