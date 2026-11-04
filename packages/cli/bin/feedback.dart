import 'package:args/args.dart';
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/context/install_info.dart';
import 'package:w_tools_cli/src/feedback/feedback_lint.dart';
import 'package:w_tools_cli/src/feedback/feedback_path.dart';
import 'package:w_tools_cli/src/feedback/feedback_submit.dart';

const _usage = '''
w_tools_cli feedback —— 把 w_tools 的问题/建议送达维护者

用法：
  dart run w_tools_cli:feedback path [--package=<包>]
  dart run w_tools_cli:feedback lint [--include-inbox]
  dart run w_tools_cli:feedback submit --package=<包> --title=<标题> (--stdin | --body-file=<file>) [--local | --gh]
  dart run w_tools_cli:feedback search <关键词> [--package=<包>] [--gh]

子命令：
  path    输出反馈该写到的文件（库侧台账 / 本地收件箱）
  lint    校验字段、状态、版本号、索引
  submit  生成预填 GitHub Issue（默认只打印链接）；--gh 直接建 issue，--local 写本地收件箱
  search  先查重：本地台账/收件箱；加 --gh 同时搜 GitHub issues

选项：
  --root=<dir>        项目根（默认当前目录）
  --package=<包>      包名（小写字母/数字/下划线）
  --title=<标题>      submit 用：一句话现象
  --body-file=<file>  submit 用：Markdown 正文（也可用 --stdin）
  --stdin             submit 用：从标准输入读 Markdown 正文
  --template          submit 用：只打印正文骨架，不提交
  --gh                submit：直接 gh issue create；search：搜 GitHub issues
  --local             submit：只写 docs/agents/feedback.md，不联网
  --repo=<owner/repo> submit/search 的仓库（默认 stone0533/w_tools）
  --include-inbox     lint 用：连同本地收件箱一起校验
  --stale-days=<n>    lint 用：待处理超过 n 天给警告（默认 30，0 = 关闭）
  --format=<fmt>      text | json（默认 text）
  --json              等价于 --format=json
  -h, --help          显示本帮助

示例：
  dart run w_tools_cli:feedback search "WImage 缓存" --package=ui
  dart run w_tools_cli:feedback submit --package=ui --title="WImage 缓存不生效" --stdin
  dart run w_tools_cli:feedback submit --package=ui --title="..." --body-file=/tmp/f.md --gh
  dart run w_tools_cli:feedback submit --package=ui --title="..." --stdin --local
  dart run w_tools_cli:feedback lint --include-inbox
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('package')
    ..addOption('title')
    ..addOption('body-file')
    ..addFlag('stdin', negatable: false)
    ..addFlag('template', negatable: false)
    ..addFlag('gh', negatable: false)
    ..addFlag('local', negatable: false)
    ..addOption('repo', defaultsTo: 'stone0533/w_tools')
    ..addFlag('include-inbox', negatable: false)
    ..addOption('stale-days', defaultsTo: '30')
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json'])
    ..addFlag('json', negatable: false);

  CliCommand(
    usage: _usage,
    parser: parser,
    body: (args) {
      final rest = args.rest;
      if (rest.isEmpty) {
        _usageError('缺少子命令（path / lint / submit / search）');
      }
      final sub = rest.first;
      final root = Directory(args['root'] as String? ?? Directory.current.path);
      final asJson = outputFormat(args) == 'json';

      switch (sub) {
        case 'path':
          _path(args, root, asJson);
        case 'lint':
          _lint(args, root, asJson);
        case 'submit':
          _submit(args, root, asJson);
        case 'search':
          _search(args, root, asJson);
        default:
          _usageError('未知子命令：$sub（可用：path / lint / submit / search）');
      }
    },
  ).run(argv);
}

void _path(ArgResults args, Directory root, bool asJson) {
  String? package;
  try {
    package = validatePackageName(args['package'] as String?);
  } on FormatException catch (e) {
    _usageError(e.message);
  }
  final target = FeedbackTarget.resolve(projectRoot: root, package: package);
  if (asJson) {
    print(jsonEncode(target.toJson()));
    return;
  }

  print(target.path);
  if (target.isLibrary) {
    if (target.kind == 'library-dir') {
      print('# 库侧反馈目录；按包选文件，如 --package=cli');
    } else if (!target.exists) {
      stderr.writeln(
        '# 该包还没有库侧台账；用 feedback submit --package=${package ?? '<包>'} 提交，'
        '维护者 triage 后建档（不要直接改索引）',
      );
    }
  } else {
    stderr.writeln('# 本地收件箱不会自动发送；用 feedback submit --gh 或按模板提交到 GitHub');
  }
}

void _lint(ArgResults args, Directory root, bool asJson) {
  final staleDaysRaw = args['stale-days'] as String;
  final staleDays = int.tryParse(staleDaysRaw);
  if (staleDays == null) {
    _usageError('--stale-days 需要整数：$staleDaysRaw');
  }
  final install = InstallInfo.detect(projectRoot: root);
  final linter = FeedbackLinter(staleDays: staleDays);
  final paths = <String>[];
  FeedbackLintResult result;
  if (install.feedbackDir != null) {
    result = linter.lintLibrary(Directory(install.feedbackDir!));
  } else {
    result = FeedbackLintResult(
      files: const <String>[],
      pending: 0,
      closed: 0,
      issues: const <FeedbackIssue>[],
    );
  }
  if (args['include-inbox'] as bool) {
    final inbox = inboxFile(root);
    if (inbox.existsSync()) paths.add(inbox.path);
    final inboxResult = linter.lintFiles(paths);
    result = FeedbackLintResult(
      files: [...result.files, ...inboxResult.files],
      pending: result.pending + inboxResult.pending,
      closed: result.closed + inboxResult.closed,
      issues: [...result.issues, ...inboxResult.issues],
      warnings: [...result.warnings, ...inboxResult.warnings],
    );
  }

  if (asJson) {
    print(jsonEncode(result.toJson()));
  } else {
    if (result.files.isEmpty) {
      print('没有可校验的反馈文件（库侧未检出，也没有收件箱）');
    }
    for (final i in result.issues) {
      stderr.writeln('✗ $i');
    }
    for (final w in result.warnings) {
      stderr.writeln('! $w');
    }
    for (final f in result.files) {
      stdout.writeln('· $f');
    }
    print(
      '${result.ok ? '✓' : '✗'} 待处理 ${result.pending} 条，已闭环 ${result.closed} 条，'
      '问题 ${result.issues.length} 个，警告 ${result.warnings.length} 个',
    );
  }
  if (!result.ok) exit(1);
}

void _submit(ArgResults args, Directory root, bool asJson) {
  if (args['template'] as bool) {
    print(feedbackBodyTemplate);
    return;
  }
  final package = _packageArg(args)!;
  final title = (args['title'] as String?)?.trim() ?? '';
  if (title.isEmpty) _usageError('submit 需要 --title=<一句话现象>');
  if ((args['local'] as bool) && (args['gh'] as bool)) {
    _usageError('--local 与 --gh 不能同时使用');
  }

  final bodyFile = args['body-file'] as String?;
  final useStdin = args['stdin'] as bool;
  if (bodyFile == null && !useStdin) {
    _usageError('submit 需要 --stdin 或 --body-file=<file>');
  }
  String body;
  if (bodyFile != null) {
    final file = File(bodyFile);
    if (!file.existsSync()) _usageError('找不到 --body-file：$bodyFile');
    body = file.readAsStringSync();
  } else {
    body = _readStdin();
  }

  final draft = FeedbackDraft(package: package, title: title, body: body);
  final missing = draft.missingFields;
  if (missing.isNotEmpty) {
    stderr.writeln('反馈缺少必填字段：${missing.join('、')}');
    stderr.writeln('按 docs/feedback/TEMPLATE.md 补全后重试。');
    exit(2);
  }

  if (args['local'] as bool) {
    final file = writeLocalInbox(root, draft);
    if (asJson) {
      print(jsonEncode({...draft.toJson(), 'mode': 'local', 'localPath': file.path}));
    } else {
      print('已写入本地收件箱：${file.path}');
      print('它不会自动发送；用 feedback submit --gh 或按模板提交到 GitHub。');
    }
    return;
  }

  if (args['gh'] as bool) {
    try {
      final url = createGitHubIssue(draft, repo: args['repo'] as String);
      if (asJson) {
        print(jsonEncode({...draft.toJson(), 'mode': 'gh', 'issueUrl': url.toString()}));
      } else {
        print('已创建 GitHub issue：$url');
      }
    } on FeedbackSubmitException catch (e) {
      stderr.writeln(e.message);
      exit(1);
    }
    return;
  }

  if (asJson) {
    print(jsonEncode({...draft.toJson(), 'mode': 'url'}));
    return;
  }
  print('反馈已准备（不会自动上传）。');
  print('标题：${draft.issueTitle}');
  print('GitHub 预填：${draft.issueUrl}');
  print('直接创建：${draft.ghCommand}');
  print('离线保存：加 --local；创建 issue：加 --gh。');
  print('');
  print(draft.body);
}

void _search(ArgResults args, Directory root, bool asJson) {
  final query = args.rest.skip(1).join(' ').trim();
  if (query.isEmpty) _usageError('search 需要一个关键词');
  final package = _packageArg(args, required: false);

  final local = searchLocal(root, package: package, query: query);
  final github = <Map<String, Object?>>[];
  String? githubError;
  if (args['gh'] as bool) {
    try {
      github.addAll(_searchGitHub(query, package: package, repo: args['repo'] as String));
    } on FeedbackSubmitException catch (e) {
      githubError = e.message;
    }
  }

  if (asJson) {
    print(
      jsonEncode({
        'query': query,
        'package': package,
        'local': [for (final m in local) m.toJson()],
        'github': github,
        if (githubError != null) 'githubError': githubError,
      }),
    );
  } else {
    if (local.isEmpty && github.isEmpty && githubError == null) {
      print('没有找到相关反馈。');
    }
    for (final m in local) {
      print('${m.file}:${m.line}  ${m.text}');
    }
    for (final issue in github) {
      print('GitHub #${issue['number']}  ${issue['title']}  ${issue['url']}');
    }
    if (githubError != null) stderr.writeln('GitHub 搜索失败：$githubError');
  }
  if (local.isEmpty && github.isEmpty && githubError == null) exit(1);
}

String? _packageArg(ArgResults args, {bool required = true}) {
  String? package;
  try {
    package = validatePackageName(args['package'] as String?);
  } on FormatException catch (e) {
    _usageError(e.message);
  }
  if (required && package == null) _usageError('需要 --package=<包>');
  return package;
}

List<Map<String, Object?>> _searchGitHub(
  String query, {
  String? package,
  required String repo,
}) {
  final auth = Process.runSync('gh', const <String>['auth', 'status']);
  if (auth.exitCode != 0) {
    throw const FeedbackSubmitException('gh 未登录；先运行 gh auth login，或去掉 --gh');
  }
  final q = package == null ? query : '$query $package';
  final result = Process.runSync('gh', <String>[
    'search',
    'issues',
    '--repo',
    repo,
    '--limit',
    '20',
    '--json',
    'number,title,url,state',
    q,
  ]);
  if (result.exitCode != 0) {
    throw FeedbackSubmitException('gh search 失败：${result.stderr.toString().trim()}');
  }
  final decoded = jsonDecode('${result.stdout}');
  if (decoded is! List) return const [];
  return [
    for (final item in decoded)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

String _readStdin() {
  final buffer = StringBuffer();
  String? line;
  while ((line = stdin.readLineSync()) != null) {
    buffer.writeln(line);
  }
  return buffer.toString();
}

Never _usageError(String message) {
  stderr.writeln('参数错误：$message\n');
  stderr.writeln(_usage);
  exit(2);
}
