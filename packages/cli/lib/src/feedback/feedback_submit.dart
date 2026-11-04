import 'dart:io';

import 'package:path/path.dart' as p;

import 'feedback_lint.dart';

/// 提交反馈时的参数/校验错误。
class FeedbackSubmitException implements Exception {
  const FeedbackSubmitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 提交反馈的正文骨架（中文）；字段名必须与 lint 的别名一致。
const feedbackBodyTemplate = '''- 包/版本：
- 环境：
- 命令 / 输入：
- 期望：
- 实际：
- 影响：
- 建议：
- 复现数据：
''';

/// 提交反馈的正文骨架（英文）。
const feedbackBodyTemplateEn = '''- package/version:
- environment:
- command / input:
- expected:
- actual:
- impact:
- suggestion:
- repro data:
''';

/// `w_tools_ui` / `ui` 都归一成台账包名 `ui`。
String normalizeFeedbackPackage(String package) {
  final name = package.startsWith('w_tools_') ? package.substring('w_tools_'.length) : package;
  return name.replaceAll('-', '_');
}

/// 一条准备提交的反馈（不涉及网络）。
class FeedbackDraft {
  FeedbackDraft({
    required String package,
    required this.title,
    required String body,
  }) : package = normalizeFeedbackPackage(package),
       body = _normalizeBody(
         package: normalizeFeedbackPackage(package),
         title: title,
         body: body,
       );

  final String package;
  final String title;
  final String body;

  static String _normalizeBody({
    required String package,
    required String title,
    required String body,
  }) {
    final trimmed = body.trim();
    if (trimmed.startsWith('### [')) return trimmed;
    return '### [待处理] $package: $title\n\n$trimmed';
  }

  /// 缺失的必填字段（空表示可提交）。
  List<String> get missingFields => missingFeedbackFields(body);

  /// GitHub issue 标题。
  String get issueTitle => '[feedback][$package] $title';

  /// 预填 GitHub 新建 issue 的链接（不自动提交）。
  Uri get issueUrl => Uri.https('github.com', '/stone0533/w_tools/issues/new', {
    'title': issueTitle,
    'body': body,
    'labels': 'needs-triage',
  });

  /// 给 AI / 人复制的 gh 命令（body 走临时文件）。
  String get ghCommand =>
      'gh issue create --repo stone0533/w_tools --title ${_shell(issueTitle)} --body-file <反馈正文.md>';

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': 'w_tools_cli.feedback_submit/1',
    'package': package,
    'title': title,
    'issueTitle': issueTitle,
    'body': body,
    'missingFields': missingFields,
    'url': issueUrl.toString(),
    'ghCommand': ghCommand,
  };

  static String _shell(String value) => "'${value.replaceAll("'", "'\\''")}'";
}

/// 通过已登录的 `gh` 创建 GitHub issue；失败时抛 [FeedbackSubmitException]。
Uri createGitHubIssue(
  FeedbackDraft draft, {
  String repo = 'stone0533/w_tools',
}) {
  final gh = Process.runSync('gh', const <String>['--version']);
  if (gh.exitCode != 0) {
    throw const FeedbackSubmitException('找不到 gh CLI；先安装并登录 gh，或使用默认的预填链接');
  }
  final auth = Process.runSync('gh', const <String>['auth', 'status']);
  if (auth.exitCode != 0) {
    throw const FeedbackSubmitException('gh 未登录；先运行 gh auth login，或使用默认的预填链接');
  }

  final temp = File(
    p.join(
      Directory.systemTemp.path,
      'w_tools_feedback_${DateTime.now().microsecondsSinceEpoch}.md',
    ),
  );
  temp.writeAsStringSync(draft.body);
  try {
    final result = Process.runSync('gh', <String>[
      'issue',
      'create',
      '--repo',
      repo,
      '--title',
      draft.issueTitle,
      '--body-file',
      temp.path,
      '--label',
      'needs-triage',
    ]);
    if (result.exitCode != 0) {
      throw FeedbackSubmitException(
        'gh issue create 失败（exit ${result.exitCode}）：${result.stderr.toString().trim()}',
      );
    }
    final url = RegExp(r'https://github\.com/[^\s]+').firstMatch('${result.stdout}')?.group(0);
    if (url == null) {
      throw FeedbackSubmitException('gh 创建成功，但未解析到 issue URL：${result.stdout.toString().trim()}');
    }
    return Uri.parse(url);
  } finally {
    if (temp.existsSync()) temp.deleteSync();
  }
}

/// 一条本地查重结果。
class FeedbackMatch {
  const FeedbackMatch({required this.file, required this.line, required this.text});

  final String file;
  final int line;
  final String text;

  Map<String, Object?> toJson() => <String, Object?>{
    'file': file,
    'line': line,
    'text': text,
  };
}

/// 在库侧台账 + 消费方收件箱里做简单子串查重。
List<FeedbackMatch> searchLocal(
  Directory projectRoot, {
  String? package,
  required String query,
}) {
  final files = <File>[];
  final inbox = File(p.join(projectRoot.path, 'docs', 'agents', 'feedback.md'));
  if (inbox.existsSync()) files.add(inbox);

  final ledger = Directory(p.join(projectRoot.path, 'docs', 'feedback'));
  if (ledger.existsSync()) {
    if (package != null) {
      final file = File(p.join(ledger.path, '$package.md'));
      if (file.existsSync()) files.add(file);
    } else {
      for (final entity in ledger.listSync()) {
        if (entity is File && entity.path.endsWith('.md')) files.add(entity);
      }
    }
  }

  final needle = query.toLowerCase();
  final matches = <FeedbackMatch>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(needle)) {
        matches.add(FeedbackMatch(file: file.path, line: i + 1, text: lines[i].trim()));
      }
    }
  }
  return matches;
}
