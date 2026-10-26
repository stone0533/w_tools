// ignore_for_file: avoid_print

import 'dart:convert';

import 'rule.dart';

/// 把规则结果输出成「人读」或 JSON，并给出退出码。
class DoctorReporter {
  DoctorReporter({required this.projectName, required this.fileCount, this.strict = false});

  final String projectName;
  final int fileCount;
  final bool strict;

  void printHuman(List<DoctorRuleResult> results) {
    final errors = _count(results, DoctorLevel.error);
    final warns = _count(results, DoctorLevel.warn);

    print('w_tools doctor · $projectName · 扫描 $fileCount 个 dart 文件');
    print('━' * 60);
    for (final r in results) {
      switch (r.status) {
        case DoctorRuleStatus.skipped:
          print('- ${r.ruleId}  ${r.title}（跳过：${r.skipReason ?? ''}）');
        case DoctorRuleStatus.pass:
          print('✓ ${r.ruleId}  ${r.title}');
        case DoctorRuleStatus.fail:
          for (final issue in r.issues) {
            final mark = switch (issue.level) {
              DoctorLevel.error => '✗',
              DoctorLevel.warn => '⚠',
              DoctorLevel.info => '·',
            };
            final where = issue.location.isEmpty ? '' : '  ${issue.location}';
            print('$mark ${r.ruleId}$where  ${issue.message}');
            if (issue.hint != null) print('      → ${issue.hint}');
          }
      }
    }
    print('');
    print('$errors error · $warns warning · 退出码 ${exitCode(results)}');
  }

  void printJson(List<DoctorRuleResult> results) {
    final payload = <String, Object?>{
      'project': projectName,
      'fileCount': fileCount,
      'counts': <String, int>{
        'error': _count(results, DoctorLevel.error),
        'warn': _count(results, DoctorLevel.warn),
      },
      'exitCode': exitCode(results),
      'rules': results
          .map(
            (r) => <String, Object?>{
              'id': r.ruleId,
              'title': r.title,
              'status': r.status.name,
              if (r.skipReason != null) 'skipReason': r.skipReason,
              'issues': r.issues
                  .map(
                    (i) => <String, Object?>{
                      'level': i.level.name,
                      'file': i.file,
                      'line': i.line,
                      'message': i.message,
                      'hint': i.hint,
                      if (i.fix != null) 'fix': i.fix!.toJson(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
    print(const JsonEncoder.withIndent('  ').convert(payload));
  }

  /// Markdown 摘要：可直接粘给 AI / 写进 PR 评论。
  void printMarkdown(List<DoctorRuleResult> results) {
    final errors = _count(results, DoctorLevel.error);
    final warns = _count(results, DoctorLevel.warn);
    final b = StringBuffer()
      ..writeln('# w_tools doctor · $projectName')
      ..writeln()
      ..writeln('- 扫描文件：$fileCount')
      ..writeln('- 结果：$errors error / $warns warning（退出码 ${exitCode(results)}）')
      ..writeln();
    for (final r in results) {
      if (r.status == DoctorRuleStatus.skipped) {
        b.writeln('- `${r.ruleId}` ${r.title}：跳过（${r.skipReason ?? ''}）');
        continue;
      }
      if (r.status == DoctorRuleStatus.pass) {
        b.writeln('- `${r.ruleId}` ${r.title}：通过');
        continue;
      }
      b
        ..writeln('### `${r.ruleId}` ${r.title}')
        ..writeln();
      for (final issue in r.issues) {
        final where = issue.location.isEmpty ? '' : '`${issue.location}` ';
        b.writeln('- $where**${issue.level.name}** ${issue.message}');
        if (issue.hint != null) b.writeln('  - 建议：${issue.hint}');
        final command = issue.fix?.command;
        if (command != null) b.writeln('  - 修复命令：`$command`');
      }
      b.writeln();
    }
    print(b.toString().trimRight());
  }

  int exitCode(List<DoctorRuleResult> results) {
    if (_count(results, DoctorLevel.error) > 0) return 1;
    if (strict && _count(results, DoctorLevel.warn) > 0) return 1;
    return 0;
  }

  int _count(List<DoctorRuleResult> results, DoctorLevel level) =>
      results.expand((r) => r.issues).where((i) => i.level == level).length;
}
