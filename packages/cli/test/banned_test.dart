import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/banned_rule.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';
import 'package:w_tools_cli/src/doctor/rules/r9_banned_api.dart';

Directory makeProject(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('wt_banned_');
  files.forEach((rel, content) {
    final f = File(p.join(root.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });
  return root;
}

BannedRule rule({
  String id = 'no-foo',
  String pattern = 'Foo.bar',
  BannedPatternMode mode = BannedPatternMode.literal,
  DoctorLevel level = DoctorLevel.warn,
  List<String> paths = const <String>[],
  List<String> ignore = const <String>[],
}) => BannedRule(
  id: id,
  pattern: pattern,
  mode: mode,
  use: 'Baz.bar',
  reason: 'Foo.bar 已移除',
  level: level,
  paths: paths,
  ignore: ignore,
);

DoctorRuleResult run(Directory root, List<BannedRule> rules) => R9BannedApi.check(
  ProjectContext.load(root, DoctorConfig(banned: rules), includeTests: true),
  DoctorConfig(banned: rules),
);

void main() {
  test('未配置 banned 时跳过', () {
    final root = makeProject({'lib/a.dart': 'void main() {}\n'});
    final result = R9BannedApi.check(
      ProjectContext.load(root, DoctorConfig(), includeTests: true),
      DoctorConfig(),
    );
    expect(result.status, DoctorRuleStatus.skipped);
  });

  test('literal 命中并带 use/reason', () {
    final root = makeProject({'lib/a.dart': 'void main() { Foo.bar(); }\n'});
    final result = run(root, [rule()]);
    expect(result.status, DoctorRuleStatus.fail);
    expect(result.issues.single.file, 'lib/a.dart');
    expect(result.issues.single.hint, contains('Baz.bar'));
    expect(result.issues.single.hint, contains('Foo.bar 已移除'));
  });

  test('regex 模式命中', () {
    final root = makeProject({'lib/a.dart': 'void main() { Foo.bar(); FooXbar(); }\n'});
    final result = run(root, [
      rule(pattern: r'Foo\.(bar|baz)', mode: BannedPatternMode.regex),
    ]);
    expect(result.issues, hasLength(1));
  });

  test('注释行不命中', () {
    final root = makeProject({'lib/a.dart': '// Foo.bar\nvoid main() {}\n'});
    expect(run(root, [rule()]).status, DoctorRuleStatus.pass);
  });

  test('paths 限制命中范围', () {
    final root = makeProject({
      'lib/app/modules/a.dart': 'Foo.bar();\n',
      'lib/app/ui/b.dart': 'Foo.bar();\n',
    });
    final result = run(root, [
      rule(paths: ['lib/app/modules/**']),
    ]);
    expect(result.issues.single.file, 'lib/app/modules/a.dart');
  });

  test('ignore 排除路径', () {
    final root = makeProject({'lib/app/ui/a.dart': 'Foo.bar();\n'});
    final result = run(root, [
      rule(ignore: ['lib/app/ui/**']),
    ]);
    expect(result.status, DoctorRuleStatus.pass);
  });

  test('行级 ignore 必须带 reason', () {
    final root = makeProject({
      'lib/a.dart': '// w_tools:ignore R9 reason: legacy\nFoo.bar();\n',
    });
    expect(run(root, [rule()]).status, DoctorRuleStatus.pass);

    final noReason = makeProject({
      'lib/a.dart': '// w_tools:ignore R9\nFoo.bar();\n',
    });
    expect(run(noReason, [rule()]).status, DoctorRuleStatus.fail);
  });

  test('文件级 ignore 生效', () {
    final root = makeProject({
      'lib/a.dart': '// w_tools:ignore-file R9 reason: generated\nFoo.bar();\n',
    });
    expect(run(root, [rule()]).status, DoctorRuleStatus.pass);
  });

  test('非法 regex 报配置错误', () {
    final root = makeProject({'lib/a.dart': 'void main() {}\n'});
    final result = run(root, [
      rule(pattern: '[', mode: BannedPatternMode.regex),
    ]);
    expect(result.issues.single.level, DoctorLevel.error);
    expect(result.issues.single.file, DoctorConfig.fileName);
  });

  test('config 解析 banned 字段', () {
    final config = DoctorConfig.parse('''
banned:
  - id: no-foo
    pattern: 'Foo\\.bar'
    mode: regex
    use: Baz.bar
    reason: removed
    level: error
    paths: ['lib/app/**']
    ignore: ['lib/app/ui/**']
''');
    expect(config.banned, hasLength(1));
    expect(config.banned.single.id, 'no-foo');
    expect(config.banned.single.mode, BannedPatternMode.regex);
    expect(config.banned.single.level, DoctorLevel.error);
    expect(config.banned.single.appliesTo('lib/app/x.dart'), isTrue);
    expect(config.banned.single.appliesTo('lib/app/ui/x.dart'), isFalse);
  });
  test('rules.R9: false 时跳过', () {
    final root = makeProject({'lib/a.dart': 'Foo.bar();\n'});
    final config = DoctorConfig.parse('rules:\n  R9: false\n').copyWith(banned: [rule()]);
    final result = R9BannedApi.check(
      ProjectContext.load(root, config, includeTests: true),
      config,
    );
    expect(result.status, DoctorRuleStatus.skipped);
  });
}
