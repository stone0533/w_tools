import 'dart:io';

import 'package:path/path.dart' as p;

/// 一条 lint 问题。
class FeedbackIssue {
  const FeedbackIssue({
    required this.file,
    required this.line,
    required this.message,
  });

  final String file;
  final int line;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
    'file': file,
    'line': line,
    'message': message,
  };

  @override
  String toString() => '$file:$line $message';
}

/// 反馈文件统计（给 `--json` 与人读输出用）。
class FeedbackLintResult {
  FeedbackLintResult({
    required this.files,
    required this.pending,
    required this.closed,
    required this.issues,
  });

  final List<String> files;
  final int pending;
  final int closed;
  final List<FeedbackIssue> issues;

  bool get ok => issues.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 'w_tools_cli.feedback/1',
    'ok': ok,
    'files': files,
    'pending': pending,
    'closed': closed,
    'issues': <Map<String, Object?>>[for (final i in issues) i.toJson()],
  };
}

/// 校验反馈文件的格式：字段齐全、状态合法、已闭环带版本号。
class FeedbackLinter {
  const FeedbackLinter();

  static const _statuses = <String>{
    '待处理',
    '已确认',
    '已修复',
    '不修',
    'pending',
    'confirmed',
    'fixed',
    'wontfix',
  };

  /// 待处理条目必须出现的字段（中英文均可）。
  static const _requiredFields = <List<String>>[
    ['包/版本', 'package/version'],
    ['环境', 'environment'],
    ['命令', 'command'],
    ['期望', 'expected'],
    ['实际', 'actual'],
    ['影响', 'impact'],
    ['建议', 'suggestion'],
    ['复现数据', 'repro'],
  ];

  static final _heading = RegExp(r'^###\s*\[([^\]]+)\]\s*(.*)$');
  static final _closedRow = RegExp(r'^\|\s*\d{4}-\d{2}-\d{2}\s*\|');
  static final _version = RegExp(r'✅\s*(?:[A-Za-z_]+\s+)?\d+\.\d+\.\d+');

  FeedbackLintResult lintFiles(List<String> paths) {
    final issues = <FeedbackIssue>[];
    var pending = 0;
    var closed = 0;
    final checked = <String>[];

    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      checked.add(path);
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final rowMatch = _closedRow.firstMatch(lines[i]);
        if (rowMatch != null) {
          closed++;
          if (!_version.hasMatch(lines[i])) {
            issues.add(
              FeedbackIssue(
                file: path,
                line: i + 1,
                message: '已闭环条目缺少版本号（应为「✅ x.y.z」）',
              ),
            );
          }
          continue;
        }
        final heading = _heading.firstMatch(lines[i]);
        if (heading == null) continue;
        final status = heading.group(1)!.trim();
        if (!_statuses.contains(status)) {
          issues.add(
            FeedbackIssue(
              file: path,
              line: i + 1,
              message: '未知状态「$status」（可用：${_statuses.join(' / ')}）',
            ),
          );
          continue;
        }
        if (status != '待处理' && status != 'pending') continue;
        pending++;
        // 收集本条正文，直到下一个 ### / ## 或文件结束
        final body = <String>[];
        var end = i + 1;
        while (end < lines.length &&
            !lines[end].startsWith('### ') &&
            !lines[end].startsWith('## ')) {
          body.add(lines[end]);
          end++;
        }
        final text = body.join('\n');
        for (final aliases in _requiredFields) {
          final ok = aliases.any((a) => text.contains(a));
          if (!ok) {
            issues.add(
              FeedbackIssue(
                file: path,
                line: i + 1,
                message: '待处理条目缺字段「${aliases.first}」',
              ),
            );
          }
        }
      }
    }
    return FeedbackLintResult(
      files: checked,
      pending: pending,
      closed: closed,
      issues: issues,
    );
  }

  /// 库侧：所有 `docs/feedback/*.md`（排除 README / TEMPLATE）+ 索引数量核对。
  FeedbackLintResult lintLibrary(Directory feedbackDir) {
    final files = <String>[];
    if (feedbackDir.existsSync()) {
      for (final entity in feedbackDir.listSync()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name == 'README.md' || name == 'TEMPLATE.md') continue;
        if (!name.endsWith('.md')) continue;
        files.add(entity.path);
      }
    }
    final result = lintFiles(files);
    final issues = [...result.issues, ..._checkIndex(feedbackDir, result)];
    return FeedbackLintResult(
      files: result.files,
      pending: result.pending,
      closed: result.closed,
      issues: issues,
    );
  }

  /// 索引表里的「待处理」数量必须与实际一致。
  List<FeedbackIssue> _checkIndex(Directory dir, FeedbackLintResult result) {
    final readme = File(p.join(dir.path, 'README.md'));
    if (!readme.existsSync()) return const [];
    final counts = <String, int>{};
    for (final path in result.files) {
      final lines = File(path).readAsLinesSync();
      counts[p.basenameWithoutExtension(path)] = lines
          .where((l) => l.startsWith('### [待处理]'))
          .length;
    }
    final row = RegExp(r'^\|\s*\[([a-z_]+)\]\([^)]+\)\s*\|\s*(\d+)\s*\|');
    final issues = <FeedbackIssue>[];
    final lines = readme.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final m = row.firstMatch(lines[i]);
      if (m == null) continue;
      final pkg = m.group(1)!;
      final indexed = int.parse(m.group(2)!);
      final actual = counts[pkg];
      if (actual != null && actual != indexed) {
        issues.add(
          FeedbackIssue(
            file: readme.path,
            line: i + 1,
            message: '索引写「$indexed」条待处理，实际 $actual 条',
          ),
        );
      }
    }
    return issues;
  }
}
