import 'package:flutter_test/flutter_test.dart';
import 'package:sdd_webchat_o/features/chat/data/skill_execution.dart';
import 'package:sdd_webchat_o/features/integrations/domain/skill_definition.dart';

void main() {
  group('SkillRequestParser', () {
    test('parses fenced skill json', () {
      const parser = SkillRequestParser();
      final request = parser.parse(
        '```skill\n{"skill":"doc-writer","input":"summarize","arguments":{"lang":"ja"}}\n```',
      );

      expect(request, isNotNull);
      expect(request!.skill, 'doc-writer');
      expect(request.input, 'summarize');
      expect(request.arguments['lang'], 'ja');
    });

    test('returns null when no skill key is provided', () {
      const parser = SkillRequestParser();
      final request = parser.parse('{"tool":"x"}');
      expect(request, isNull);
    });
  });

  group('SkillExecutor', () {
    test('returns workflow summary for matching enabled skill', () {
      const executor = SkillExecutor();
      final result = executor.execute(
        request: const SkillCallRequest(skill: 'Doc Writer'),
        enabledSkills: const [
          SkillDefinition(
            id: 's1',
            name: 'Doc Writer',
            content: '# Steps\n1. Gather context\n2. Draft summary',
          ),
        ],
      );

      expect(result.success, isTrue);
      expect(result.output, contains('Workflow:'));
      expect(result.output, contains('Gather context'));
    });

    test('returns error when skill is not found', () {
      const executor = SkillExecutor();
      final result = executor.execute(
        request: const SkillCallRequest(skill: 'missing-skill'),
        enabledSkills: const [],
      );

      expect(result.success, isFalse);
      expect(result.output, contains('not found'));
    });
  });
}
