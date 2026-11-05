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
    this.issues = const <FeedbackIssue>[],
    this.warnings = const <FeedbackIssue>[],
  });

  final List<String> files;
  final int pending;
  final int closed;

  /// 必须修的问题（退出码 1）。
  final List<FeedbackIssue> issues;

  /// 建议处理（stale 等），不影响退出码。
  final List<FeedbackIssue> warnings;

  bool get ok => issues.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 'w_tools_cli.feedback/1',
    'ok': ok,
    'files': files,
    'pending': pending,
    'closed': closed,
    'issues': <Map<String, Object?>>[for (final i in issues) i.toJson()],
    'warnings': <Map<String, Object?>>[for (final i in warnings) i.toJson()],
  };
}

/// 待处理 / 提交反馈必须出现的字段（中英文均可）。
const feedbackRequiredFields = <List<String>>[
  ['包/版本', 'package/version'],
  ['环境', 'environment'],
  ['命令', 'command'],
  ['期望', 'expected'],
  ['实际', 'actual'],
  ['影响', 'impact'],
  ['建议', 'suggestion'],
  ['复现数据', 'repro'],
];

/// 按行首 `- 字段：` 提取字段名。
final feedbackFieldLine = RegExp(r'^\s*-\s*(.+?)\s*[：:]');

/// 从一段 Markdown 中提取已填写的字段名。
Set<String> feedbackFieldsIn(String text) {
  final present = <String>{};
  for (final line in text.split('\n')) {
    final m = feedbackFieldLine.firstMatch(line);
    if (m != null) present.add(m.group(1)!.trim());
  }
  return present;
}

/// 返回缺失的必填字段（展示第一个别名）。
List<String> missingFeedbackFields(String text) {
  final present = feedbackFieldsIn(text);
  return [
    for (final aliases in feedbackRequiredFields)
      if (!aliases.any((a) => present.any((key) => key.startsWith(a)))) aliases.first,
  ];
}

/// 校验反馈文件的格式：字段齐全、状态合法、已闭环带版本号、待处理不 stale。
String _feedbackTitle(String heading) {
  final m = RegExp(r'^[^:]+:\s*(.*)$').firstMatch(heading);
  return (m?.group(1) ?? heading).trim();
}

String _feedbackSignature(String text) {
  return text
      .replaceFirst(RegExp(r'^[^\n]*\n'), '')
      .replaceAll(RegExp(r'^\s*-\s*状态变更.*$', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _placeholder(String value) {
  final s = value.trim().toLowerCase();
  return s.isEmpty ||
      s == '-' ||
      s == '...' ||
      s == 'x' ||
      s == 'test' ||
      s == 'todo' ||
      s == 'n/a' ||
      s == '见附件' ||
      s.contains('...') ||
      s.startsWith('<');
}

class FeedbackLinter {
  const FeedbackLinter({this.staleDays = 30});

  /// `待处理` 超过这么多天没动 → 警告（默认 30）；`<= 0` 关闭该检查。
  final int staleDays;

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

  static final _heading = RegExp(r'^###\s*\[([^\]]+)\]\s*(.*)$');
  static final _closedRow = RegExp(r'^\|\s*\d{4}-\d{2}-\d{2}\s*\|');
  static final _version = RegExp(r'✅\s*(?:[A-Za-z_]+\s+)?\d+\.\d+\.\d+');
  static final _fieldLine = feedbackFieldLine;
  static final _statusDate = RegExp(r'状态变更[：:]\s*(\d{4}-\d{2}-\d{2})');
  static final _issueLink = RegExp(r'#\d+|https?://');
  static final _releaseVersion = RegExp(
    r'(版本|version)\s*[：:]\s*[A-Za-z_]*\s*\d+\.\d+\.\d+',
    caseSensitive: false,
  );
  static final _reason = RegExp(r'(理由|原因|reason)\s*[：:]', caseSensitive: false);

  FeedbackLintResult lintFiles(List<String> paths, {DateTime? now}) {
    final issues = <FeedbackIssue>[];
    final warnings = <FeedbackIssue>[];
    var pending = 0;
    var closed = 0;
    final checked = <String>[];
    final seen = <String, int>{};
    final today = now ?? DateTime.now();

    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      checked.add(path);
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_closedRow.firstMatch(lines[i]) != null) {
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
        final body = <String>[];
        var end = i + 1;
        while (end < lines.length &&
            !lines[end].startsWith('### ') &&
            !lines[end].startsWith('## ')) {
          body.add(lines[end]);
          end++;
        }
        final text = '${heading.group(2)}\n${body.join('\n')}';
        final signature = '${heading.group(2)!.trim()}|${_feedbackSignature(text)}';
        final previous = seen.putIfAbsent(signature, () => i + 1);
        if (previous != i + 1) {
          issues.add(
            FeedbackIssue(
              file: path,
              line: i + 1,
              message: '重复反馈：与第 $previous 行内容相同',
            ),
          );
        }
        final title = _feedbackTitle(heading.group(2)!);
        if (_placeholder(title)) {
          issues.add(
            FeedbackIssue(
              file: path,
              line: i + 1,
              message: '标题不能是占位内容（如 x / test / <...>）',
            ),
          );
        }

        if (status != '待处理' && status != 'pending') {
          // 已确认必须链 issue（#123 或 http 链接），否则没法追踪
          if (status == '已确认' || status == 'confirmed') {
            if (!_issueLink.hasMatch(text)) {
              issues.add(
                FeedbackIssue(
                  file: path,
                  line: i + 1,
                  message: '已确认条目要链 issue（#123 或链接），否则无法追踪',
                ),
              );
            }
          }
          if (status == '已修复' || status == 'fixed') {
            if (!_version.hasMatch(text) && !_releaseVersion.hasMatch(text)) {
              issues.add(
                FeedbackIssue(
                  file: path,
                  line: i + 1,
                  message: '已修复条目缺少版本号（应为「✅ x.y.z」或「版本：x.y.z」）',
                ),
              );
            }
          }
          if (status == '不修' || status == 'wontfix') {
            if (!_reason.hasMatch(text)) {
              issues.add(
                FeedbackIssue(
                  file: path,
                  line: i + 1,
                  message: '不修条目缺少理由（应为「理由：…」或「原因：…」）',
                ),
              );
            }
          }
          continue;
        }
        pending++;

        // 字段：按行首 `- 字段：` 收集，避免正文里偶然出现关键词就过关
        final present = <String>{};
        for (final line in body) {
          final m = _fieldLine.firstMatch(line);
          if (m != null) present.add(m.group(1)!.trim());
        }
        for (final aliases in feedbackRequiredFields) {
          // 允许「命令 / 输入」「影响（我因此…）」这类带后缀的写法
          final filled = aliases.any((a) => present.any((key) => key.startsWith(a)));
          if (!filled) {
            issues.add(
              FeedbackIssue(
                file: path,
                line: i + 1,
                message: '待处理条目缺字段「${aliases.first}」',
              ),
            );
          }
        }

        final values = <String, String>{};
        for (final line in body) {
          final m = RegExp(r'^\s*-\s*(.+?)\s*[：:]\s*(.*)$').firstMatch(line);
          if (m != null) values[m.group(1)!.trim()] = m.group(2)!.trim();
        }
        for (final aliases in const <List<String>>[
          ['命令', 'command'],
          ['复现数据', 'repro'],
        ]) {
          final entry = values.entries
              .where((e) => aliases.any((a) => e.key.startsWith(a)))
              .firstOrNull;
          if (entry != null && _placeholder(entry.value)) {
            issues.add(
              FeedbackIssue(
                file: path,
                line: i + 1,
                message: '「${entry.key}」不能是占位内容（如 x / - / 见附件）',
              ),
            );
          }
        }

        // stale：看「状态变更：YYYY-MM-DD」
        final dateMatch = _statusDate.firstMatch(text);
        if (dateMatch != null) {
          final date = DateTime.tryParse(dateMatch.group(1)!);
          if (date != null) {
            final age = today.difference(date).inDays;
            // staleDays <= 0 表示关闭该检查（与 --help / README 一致）
            if (staleDays > 0 && age > staleDays) {
              warnings.add(
                FeedbackIssue(
                  file: path,
                  line: i + 1,
                  message: '待处理已 $age 天没动（状态变更 ${dateMatch.group(1)}），考虑 triage',
                ),
              );
            }
          }
        }
      }
    }
    return FeedbackLintResult(
      files: checked,
      pending: pending,
      closed: closed,
      issues: issues,
      warnings: warnings,
    );
  }

  /// 库侧：所有 `docs/feedback/*.md`（排除 README / TEMPLATE）+ 索引数量核对。
  FeedbackLintResult lintLibrary(Directory feedbackDir, {DateTime? now}) {
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
    final result = lintFiles(files, now: now);
    final issues = [...result.issues, ..._checkIndex(feedbackDir)];
    return FeedbackLintResult(
      files: result.files,
      pending: result.pending,
      closed: result.closed,
      issues: issues,
      warnings: result.warnings,
    );
  }

  /// 索引表与文件必须一一对应：数量一致，且不能列出不存在的文件。
  List<FeedbackIssue> _checkIndex(Directory dir) {
    final readme = File(p.join(dir.path, 'README.md'));
    if (!readme.existsSync()) return const [];
    final counts = <String, int>{};
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.endsWith('.md') || name == 'README.md' || name == 'TEMPLATE.md') {
        continue;
      }
      final pending = File(entity.path)
          .readAsLinesSync()
          .where((l) => l.startsWith('### [待处理]') || l.startsWith('### [pending]'))
          .length;
      counts[p.basenameWithoutExtension(name)] = pending;
    }

    final row = RegExp(r'^\|\s*\[([a-z0-9_]+)\]\([^)]+\)\s*\|\s*(\d+)\s*\|');
    final issues = <FeedbackIssue>[];
    final listed = <String>{};
    final lines = readme.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final m = row.firstMatch(lines[i]);
      if (m == null) continue;
      final pkg = m.group(1)!;
      final indexed = int.parse(m.group(2)!);
      listed.add(pkg);
      final actual = counts[pkg];
      if (actual == null) {
        issues.add(
          FeedbackIssue(
            file: readme.path,
            line: i + 1,
            message: '索引列了 $pkg，但没有 $pkg.md（删文件要同步删索引，或写 0 条）',
          ),
        );
      } else if (actual != indexed) {
        issues.add(
          FeedbackIssue(
            file: readme.path,
            line: i + 1,
            message: '索引写「$indexed」条待处理，实际 $actual 条',
          ),
        );
      }
    }
    for (final pkg in counts.keys) {
      if (!listed.contains(pkg)) {
        issues.add(
          FeedbackIssue(
            file: readme.path,
            line: 1,
            message: '有 $pkg.md 但索引里没有它',
          ),
        );
      }
    }
    return issues;
  }
}
