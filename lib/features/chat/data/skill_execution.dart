import 'dart:convert';

import '../../integrations/domain/skill_definition.dart';

class SkillCallRequest {
  const SkillCallRequest({
    required this.skill,
    this.input = '',
    this.arguments = const {},
  });

  final String skill;
  final String input;
  final Map<String, dynamic> arguments;
}

class SkillExecutionResult {
  const SkillExecutionResult({
    required this.skill,
    required this.success,
    required this.output,
  });

  final String skill;
  final bool success;
  final String output;
}

class SkillRequestParser {
  const SkillRequestParser();

  SkillCallRequest? parse(String text) {
    final trimmed = text.trim();
    final fenced = RegExp(
      r'```(?:skill|json)\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fenced != null) {
      final parsed = _decode(fenced.group(1) ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return _decode(trimmed);
  }

  SkillCallRequest? _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final skill = (json['skill'] as String? ?? '').trim();
      if (skill.isEmpty) {
        return null;
      }
      final input = (json['input'] as String? ?? '').trim();
      final args = json['arguments'];
      return SkillCallRequest(
        skill: skill,
        input: input,
        arguments: args is Map<String, dynamic> ? args : const {},
      );
    } catch (_) {
      return null;
    }
  }
}

class SkillExecutor {
  const SkillExecutor();

  SkillExecutionResult execute({
    required SkillCallRequest request,
    required List<SkillDefinition> enabledSkills,
  }) {
    final skill = _resolveSkill(request.skill, enabledSkills);
    if (skill == null) {
      return SkillExecutionResult(
        skill: request.skill,
        success: false,
        output: 'Skill not found or disabled: ${request.skill}',
      );
    }

    final steps = _extractSteps(skill.content);
    final summary = _summary(skill.content);
    final args = request.arguments.isEmpty ? '' : jsonEncode(request.arguments);

    final lines = <String>[
      'Skill: ${skill.name}',
      if (skill.sourceUrl.trim().isNotEmpty)
        'Source: ${skill.sourceUrl.trim()}',
      if (request.input.trim().isNotEmpty) 'Input: ${request.input.trim()}',
      if (args.isNotEmpty) 'Arguments: $args',
      if (summary.isNotEmpty) 'Summary: $summary',
    ];
    if (steps.isNotEmpty) {
      lines.add('Workflow:');
      for (var i = 0; i < steps.length; i++) {
        lines.add('${i + 1}. ${steps[i]}');
      }
    } else {
      lines.add('Skill Content:');
      lines.add(skill.content.trim());
    }

    return SkillExecutionResult(
      skill: skill.name,
      success: true,
      output: lines.join('\n'),
    );
  }

  SkillDefinition? _resolveSkill(
    String selector,
    List<SkillDefinition> enabledSkills,
  ) {
    final key = selector.trim().toLowerCase();
    for (final skill in enabledSkills) {
      if (!skill.enabled) {
        continue;
      }
      if (skill.id.toLowerCase() == key || skill.name.toLowerCase() == key) {
        return skill;
      }
    }
    return null;
  }

  String _summary(String content) {
    final compact = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }
    return compact.length <= 220 ? compact : '${compact.substring(0, 220)}...';
  }

  List<String> _extractSteps(String content) {
    final lines = content.split('\n');
    final steps = <String>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      final numbered = RegExp(r'^\d+\.\s+(.*)$').firstMatch(line);
      if (numbered != null) {
        steps.add(numbered.group(1)!.trim());
        continue;
      }
      final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        steps.add(bullet.group(1)!.trim());
      }
      if (steps.length >= 8) {
        break;
      }
    }
    return steps;
  }
}
