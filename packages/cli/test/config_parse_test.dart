import 'package:test/test.dart';
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

  test('project_ui_dir 解析为自定义路径', () {
    final config = DoctorConfig.parse('project_ui_dir: lib/app/design\n');
    expect(config.projectUiDir, 'lib/app/design');
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
      projectUiDir: 'lib/x/ui',
      designSystemDir: 'lib/x/design_system',
      palette: const ['#333333'],
      enabledRules: const {'R1'},
    );
    expect(config.toolkitEntry, 'lib/x/toolkit.dart');
    expect(config.projectUiDir, 'lib/x/ui');
    expect(config.designSystemDir, 'lib/x/design_system');
    expect(config.palette, ['#333333']);
    expect(config.enabledRules, {'R1'});
    expect(config.colorMinCount, DoctorConfig().colorMinCount);
    expect(config.ignore, DoctorConfig().ignore);
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
    expect(copy.projectUiDir, base.projectUiDir);
    expect(copy.designSystemDir, base.designSystemDir);
    expect(copy.palette, base.palette);
    expect(copy.enabledRules, base.enabledRules);
    expect(copy.colorMinCount, base.colorMinCount);
    expect(copy.ignore, base.ignore);
  });
}
