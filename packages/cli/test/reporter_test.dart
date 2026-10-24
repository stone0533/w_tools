import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/reporter.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';

DoctorIssue _issue(DoctorLevel level) =>
    DoctorIssue(rule: 'R1', level: level, message: 'message', file: 'lib/a.dart', line: 3);

DoctorRuleResult _rule(DoctorRuleStatus status, [List<DoctorIssue> issues = const []]) =>
    DoctorRuleResult(ruleId: 'R1', title: '测试规则', status: status, issues: issues);

/// 捕获 print 输出（reporter 直接 print）。
String _capture(void Function() body) {
  final out = StringBuffer();
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => out.writeln(line),
    ),
  );
  return out.toString();
}

void main() {
  group('退出码', () {
    test('error → 1', () {
      final reporter = DoctorReporter(projectName: 'demo', fileCount: 1);
      expect(
        reporter.exitCode([
          _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.error)]),
        ]),
        1,
      );
    });

    test('warn 默认 → 0', () {
      final reporter = DoctorReporter(projectName: 'demo', fileCount: 1);
      expect(
        reporter.exitCode([
          _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.warn)]),
        ]),
        0,
      );
    });

    test('warn + strict → 1', () {
      final reporter = DoctorReporter(projectName: 'demo', fileCount: 1, strict: true);
      expect(
        reporter.exitCode([
          _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.warn)]),
        ]),
        1,
      );
    });

    test('info → 0', () {
      final reporter = DoctorReporter(projectName: 'demo', fileCount: 1);
      expect(
        reporter.exitCode([
          _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.info)]),
        ]),
        0,
      );
    });
  });

  test('--json 输出可解析，含 exitCode 与计数', () {
    final reporter = DoctorReporter(projectName: 'demo', fileCount: 2);
    final raw = _capture(
      () => reporter.printJson([
        _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.error), _issue(DoctorLevel.warn)]),
        _rule(DoctorRuleStatus.skipped),
      ]),
    );
    final json = jsonDecode(raw) as Map<String, Object?>;
    expect(json['project'], 'demo');
    expect(json['fileCount'], 2);
    expect(json['exitCode'], 1);
    expect((json['counts'] as Map)['error'], 1);
    expect((json['counts'] as Map)['warn'], 1);
    expect(json['rules'], hasLength(2));
  });

  test('人读输出包含定位、提示与统计', () {
    final reporter = DoctorReporter(projectName: 'demo', fileCount: 1);
    final raw = _capture(
      () => reporter.printHuman([
        _rule(DoctorRuleStatus.fail, [_issue(DoctorLevel.error), _issue(DoctorLevel.info)]),
        _rule(DoctorRuleStatus.pass),
        _rule(DoctorRuleStatus.skipped),
      ]),
    );
    expect(raw, contains('lib/a.dart:3'));
    expect(raw, contains('1 error · 0 warning'));
    expect(raw, contains('✓ R1'));
    expect(raw, contains('跳过'));
  });

  test('location 三种形态', () {
    const a = DoctorIssue(rule: 'R1', level: DoctorLevel.warn, message: 'm');
    const b = DoctorIssue(rule: 'R1', level: DoctorLevel.warn, message: 'm', file: 'lib/a.dart');
    const c = DoctorIssue(
      rule: 'R1',
      level: DoctorLevel.warn,
      message: 'm',
      file: 'lib/a.dart',
      line: 9,
    );
    expect(a.location, '');
    expect(b.location, 'lib/a.dart');
    expect(c.location, 'lib/a.dart:9');
  });
}
