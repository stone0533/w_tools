import 'dart:io';

import 'package:path/path.dart' as p;

import 'feedback_submit.dart';

/// 台账操作失败（非仓库检出 / 文件结构异常）。
class FeedbackLedgerException implements Exception {
  const FeedbackLedgerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 结果：写入的文件 + 当前待处理数。
class FeedbackLedgerResult {
  const FeedbackLedgerResult({required this.file, required this.pending});

  final File file;
  final int pending;
}

/// 包名 → 台账文件名（接受 `ui` 或 `w_tools_ui`）。
String feedbackLedgerName(String package) => normalizeFeedbackPackage(package);

/// 反馈支持的包名（归一后）。
const feedbackPackages = <String>{
  'w_tools',
  'core',
  'async',
  'ui',
  'form',
  'api',
  'app',
  'toast',
  'map',
  'qr',
  'cli',
  'figma',
  'device',
  'e2e',
};

/// 是否是 w_tools 仓库检出（而不是消费方恰好有一个 docs/feedback 目录）。
bool isWtoolsRepo(Directory root) {
  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  final named = RegExp(
    r'^name:\s*w_tools\s*$',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());
  return named &&
      Directory(p.join(root.path, 'docs', 'feedback')).existsSync() &&
      Directory(p.join(root.path, 'packages', 'cli')).existsSync();
}

/// 把反馈追加到库侧台账（`docs/feedback/<包>.md`）并同步索引。
///
/// 只允许在 w_tools 仓库检出（name=w_tools + packages/cli + docs/feedback）时调用；消费方走 issue。
FeedbackLedgerResult addToLedger(
  Directory projectRoot,
  FeedbackDraft draft, {
  int? linkedIssue,
  bool allowDuplicate = false,
}) {
  final dir = p.join(projectRoot.path, 'docs', 'feedback');
  if (!isWtoolsRepo(projectRoot)) {
    throw const FeedbackLedgerException(
      '--ledger 只能在 w_tools 仓库检出中使用（需要 pubspec name=w_tools、packages/cli、docs/feedback）；'
      '消费方开启 feedback.issue 后用 --issue，否则跳过',
    );
  }

  final name = feedbackLedgerName(draft.package);
  if (!feedbackPackages.contains(name)) {
    throw FeedbackLedgerException('未知反馈包：$name（可选：${feedbackPackages.join(', ')}）');
  }
  final file = File(p.join(dir, '$name.md'));
  if (!allowDuplicate && file.existsSync() && _hasSameEntry(file, draft)) {
    throw FeedbackLedgerException(
      '相同反馈已存在：${file.path}；确认要重复记录时加 --allow-duplicate',
    );
  }
  final entry = linkedIssue == null
      ? draft.body.trim()
      : '${draft.body.trim()}\n- 关联 issue：#$linkedIssue';
  if (!file.existsSync()) {
    file.writeAsStringSync(_newLedger(name, entry));
  } else {
    _appendEntry(file, entry);
  }

  final pending = _pendingCount(file);
  _updateIndex(Directory(dir), name, pending);
  return FeedbackLedgerResult(file: file, pending: pending);
}

bool _hasSameEntry(File file, FeedbackDraft draft) {
  final targetTitle = draft.title.trim();
  final targetBody = _signature(draft.body);
  for (final entry in _entries(file.readAsStringSync())) {
    if (entry.title.trim() == targetTitle && _signature(entry.body) == targetBody) {
      return true;
    }
  }
  return false;
}

List<({String title, String body})> _entries(String content) {
  final lines = content.split('\n');
  final result = <({String title, String body})>[];
  String? title;
  final body = <String>[];
  void flush() {
    final current = title;
    if (current == null) return;
    result.add((title: current, body: body.join('\n')));
  }

  for (final line in lines) {
    if (line.startsWith('### ')) {
      flush();
      final m = RegExp(r'^###\s*\[[^\]]+\]\s*[^:]+:\s*(.*)$').firstMatch(line);
      title = m?.group(1) ?? '';
      body.clear();
    } else if (line.startsWith('## ')) {
      flush();
      title = null;
      body.clear();
    } else if (title != null) {
      body.add(line);
    }
  }
  flush();
  return result;
}

String _signature(String text) {
  return text
      .replaceFirst(RegExp(r'^###\s*\[[^\]]+\]\s*[^:]+:\s*.*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*-\s*状态变更.*$', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _newLedger(String name, String entry) =>
    '''# w_tools_$name 反馈

## 待处理

$entry

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
''';

void _appendEntry(File file, String entry) {
  final lines = file.readAsLinesSync();
  final start = lines.indexWhere((l) => l.trim() == '## 待处理');
  if (start < 0) {
    throw FeedbackLedgerException('${file.path} 缺少「## 待处理」段落');
  }
  var end = lines.length;
  for (var i = start + 1; i < lines.length; i++) {
    if (lines[i].startsWith('## ')) {
      end = i;
      break;
    }
  }
  // 去掉占位符，保留真正的条目
  final section = lines
      .sublist(start + 1, end)
      .where((l) => l.trim() != '（暂无）' && l.trim() != '(none)')
      .toList();
  while (section.isNotEmpty && section.last.trim().isEmpty) {
    section.removeLast();
  }
  final body = <String>[
    ...lines.sublist(0, start + 1),
    '',
    ...section,
    if (section.isNotEmpty) '',
    ...entry.split('\n'),
    '',
    ...lines.sublist(end),
  ];
  file.writeAsStringSync('${body.join('\n')}\n');
}

int _pendingCount(File file) {
  return RegExp(
    r'^###\s*\[(待处理|pending)\]',
    multiLine: true,
  ).allMatches(file.readAsStringSync()).length;
}

final _indexRow = RegExp(
  r'^\|\s*\[([a-z0-9_]+)\]\(([^)]+)\)\s*\|\s*(\d+)\s*\|\s*([^|]*)\|\s*$',
);

void _updateIndex(Directory dir, String name, int pending) {
  final readme = File(p.join(dir.path, 'README.md'));
  if (!readme.existsSync()) {
    throw FeedbackLedgerException('找不到 ${readme.path}，无法同步反馈索引');
  }
  final lines = readme.readAsLinesSync();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  var matched = false;
  var lastRow = -1;
  for (var i = 0; i < lines.length; i++) {
    final m = _indexRow.firstMatch(lines[i]);
    if (m == null) continue;
    lastRow = i;
    if (m.group(1) == name) {
      lines[i] = '| [$name](${m.group(2)}) | $pending | $today |';
      matched = true;
    }
  }
  if (!matched) {
    if (lastRow < 0) {
      throw FeedbackLedgerException('${readme.path} 没有反馈索引表');
    }
    lines.insert(lastRow + 1, '| [$name]($name.md) | $pending | $today |');
  }
  readme.writeAsStringSync('${lines.join('\n')}\n');
}
