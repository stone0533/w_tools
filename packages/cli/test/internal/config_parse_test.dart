import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/banned_rule.dart';
import 'package:w_tools_cli/src/doctor/config.dart';

void main() {
  test('顶层 colors 与 rules.R3 两种写法都能解析', () {
    final top = DoctorConfig.parse('colors:\n  palette: ["#111111"]\n  min_count: 5\n');
    expect(top.palette, ['#111111']);
    expect(top.colorMinCount, 5);

    final nested = DoctorConfig.parse(
      'rules:\n  R3:\n    palette: ["#222222"]\n    min_count: 2\n',
    );
    expect(nested.palette, ['#222222']);
    expect(nested.colorMinCount, 2);
  });

  test('R6 支持布尔与 enabled map 两种开关', () {
    expect(DoctorConfig.parse('rules:\n  R6: true\n').enabledRules, contains('R6'));
    expect(
      DoctorConfig.parse('rules:\n  R6:\n    enabled: true\n').enabledRules,
      contains('R6'),
    );
  });

  test('rules 里显式 false 可关掉默认规则', () {
    expect(DoctorConfig.parse('rules:\n  R1: false\n').enabledRules, isNot(contains('R1')));
  });

  test('feedback.enabled 默认 false；旧键 feedback.issue 仍兼容', () {
    expect(DoctorConfig().feedbackEnabled, isFalse);
    expect(DoctorConfig.parse('feedback:\n  enabled: true\n').feedbackEnabled, isTrue);
    expect(DoctorConfig.parse('feedback:\n  enabled: false\n').feedbackEnabled, isFalse);
    // 1.17 之前的写法：等价处理，不让老项目失效
    expect(DoctorConfig.parse('feedback:\n  issue: true\n').feedbackEnabled, isTrue);
    expect(DoctorConfig.parse('feedback:\n  issue: false\n').feedbackEnabled, isFalse);
    // 两个键同时出现时 enabled 优先
    expect(
      DoctorConfig.parse('feedback:\n  enabled: false\n  issue: true\n').feedbackEnabled,
      isFalse,
    );
  });

  test('feedback.max_issues_per_day 默认 5，非法值忽略', () {
    expect(DoctorConfig().feedbackMaxIssuesPerDay, 5);
    expect(
      DoctorConfig.parse('feedback:\n  max_issues_per_day: 3\n').feedbackMaxIssuesPerDay,
      3,
    );
    expect(
      DoctorConfig.parse('feedback:\n  max_issues_per_day: 0\n').feedbackMaxIssuesPerDay,
      0,
      reason: '0 = 不限',
    );
    expect(
      DoctorConfig.parse('feedback:\n  max_issues_per_day: -1\n').feedbackMaxIssuesPerDay,
      5,
    );
    expect(
      DoctorConfig.parse('feedback:\n  max_issues_per_day: "3"\n').feedbackMaxIssuesPerDay,
      5,
    );
  });

  test('feedback.ledger 解析为路径（空串 / 非字符串忽略）', () {
    expect(DoctorConfig().feedbackLedger, isNull);
    expect(
      DoctorConfig.parse('feedback:\n  ledger: ../w_tools\n').feedbackLedger,
      '../w_tools',
    );
    expect(
      DoctorConfig.parse('feedback:\n  ledger: /opt/w_tools\n').feedbackLedger,
      '/opt/w_tools',
    );
    expect(DoctorConfig.parse('feedback:\n  ledger: "  "\n').feedbackLedger, isNull);
    expect(DoctorConfig.parse('feedback:\n  ledger: 42\n').feedbackLedger, isNull);
  });

  test('ignore 解析为列表', () {
    final config = DoctorConfig.parse('ignore:\n  - lib/app/generated/\n  - build/\n');
    expect(config.ignore, ['lib/app/generated/', 'build/']);
  });

  test('ai.targets 与 ai.language 解析', () {
    final config = DoctorConfig.parse('ai:\n  targets: [agents, claude]\n  language: en\n');
    expect(config.aiTargets, ['agents', 'claude']);
    expect(config.aiLanguage, 'en');
  });

  test('copyWith 覆盖指定字段', () {
    final config = DoctorConfig().copyWith(
      toolkitEntry: 'lib/x/toolkit.dart',
      palette: const ['#333333'],
      colorMinCount: 5,
      enabledRules: const {'R1'},
      ignore: const ['build/'],
      banned: const <BannedRule>[],
    );
    expect(config.toolkitEntry, 'lib/x/toolkit.dart');
    expect(config.palette, ['#333333']);
    expect(config.colorMinCount, 5);
    expect(config.enabledRules, {'R1'});
    expect(config.ignore, ['build/']);
    expect(config.banned, isEmpty);
  });

  test('copyWith 可覆盖 ai 字段', () {
    final config = DoctorConfig().copyWith(
      aiTargets: const ['agents', 'cursor'],
      aiLanguage: 'en',
    );
    expect(config.aiTargets, ['agents', 'cursor']);
    expect(config.aiLanguage, 'en');
  });

  test('copyWith 不传参数时保留原值', () {
    final base = DoctorConfig(
      toolkitEntry: 'lib/custom/toolkit.dart',
      palette: const ['#444444'],
      enabledRules: const {'R2'},
    );
    final copy = base.copyWith();
    expect(copy.toolkitEntry, base.toolkitEntry);
    expect(copy.palette, base.palette);
    expect(copy.enabledRules, base.enabledRules);
    expect(copy.colorMinCount, base.colorMinCount);
    expect(copy.ignore, base.ignore);
  });
}
