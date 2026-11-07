import 'package:args/args.dart';
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/context/install_info.dart';
import 'package:w_tools_cli/src/feedback/feedback_lint.dart';
import 'package:w_tools_cli/src/feedback/feedback_ledger.dart';
import 'package:w_tools_cli/src/feedback/feedback_path.dart';
import 'package:w_tools_cli/src/feedback/feedback_submit.dart';

var _jsonMode = false;

const _usage = '''
w_tools_cli feedback —— 把 w_tools 的问题/建议送达维护者

用法：
  dart run w_tools_cli:w_tools feedback path [--package=<包>]
  dart run w_tools_cli:w_tools feedback lint [--include-inbox]
  dart run w_tools_cli:w_tools feedback submit --package=<包> --title=<标题> (--stdin | --body-file=<file>) [--ledger | --issue]
  dart run w_tools_cli:w_tools feedback search <关键词> [--package=<包>] [--gh]
  dart run w_tools_cli:w_tools feedback status

子命令：
  path    输出库侧台账路径（消费方默认不写文件）
  lint    校验字段、状态、版本号、索引
  submit  默认：本地 docs/feedback 存在 → 写台账；否则 feedback.issue=true → 建 Issue；否则跳过
  search  先查重：本地台账/收件箱；加 --gh 同时搜 GitHub issues
  status  输出当前反馈通道：ledger / issue / disabled

选项：
  --root=<dir>        项目根（默认当前目录）
  --package=<包>      包名（小写字母/数字/下划线）
  --title=<标题>      submit 用：一句话现象
  --body-file=<file>  submit 用：Markdown 正文（也可用 --stdin）
  --stdin             submit 用：从标准输入读 Markdown 正文
  --template          submit 用：只打印正文骨架，不提交
  --issue             submit：显式创建 GitHub Issue（默认关闭，需 feedback.issue 或本 flag）
  --gh                submit：--issue 的别名；search：搜 GitHub issues
  --ledger            submit：仅 w_tools 仓库检出，直接写入 docs/feedback/<包>.md 并更新索引
  --linked-issue=<n>  ledger 用：在条目里写「关联 issue：#n」
  --allow-duplicate   ledger 用：允许写入完全相同的反馈（默认拒绝）
  --repo=<owner/repo> submit/search 的仓库（默认 stone0533/w_tools）
  --include-inbox     lint 用：连同本地收件箱一起校验
  --stale-days=<n>    lint 用：待处理超过 n 天给警告（默认 30，0 = 关闭）
  --format=<fmt>      text | json（默认 text）
  --json              等价于 --format=json
  -h, --help          显示本帮助

说明：
  --gh 需要 gh 已安装并登录；gh 不可用时退出 3，且不返回本地查重结果。
  只想查本地台账时去掉 --gh。

示例：
  dart run w_tools_cli:w_tools feedback search "WImage 缓存" --package=ui
  dart run w_tools_cli:w_tools feedback submit --package=ui --title="WImage 缓存不生效" --stdin
  dart run w_tools_cli:w_tools feedback submit --package=ui --title="..." --body-file=/tmp/f.md --gh
  dart run w_tools_cli:w_tools feedback lint --include-inbox
''';

CommandResult run(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('package')
    ..addOption('title')
    ..addOption('body-file')
    ..addFlag('stdin', negatable: false)
    ..addFlag('template', negatable: false)
    ..addFlag('issue', negatable: false)
    ..addFlag('gh', negatable: false)
    ..addFlag('ledger', negatable: false)
    ..addOption('repo', defaultsTo: 'stone0533/w_tools')
    ..addOption('linked-issue')
    ..addFlag('allow-duplicate', negatable: false)
    ..addFlag('include-inbox', negatable: false)
    ..addOption('stale-days', defaultsTo: '30')
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json'])
    ..addFlag('json', negatable: false);

  final result = Command(
    usage: _usage,
    parser: parser,
    body: (args) {
      _jsonMode = outputFormat(args) == 'json';
      final rest = args.rest;
      if (rest.isEmpty) {
        _usageError('缺少子命令（path / lint / submit / search / status）');
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
        case 'status':
          _status(root, asJson);
        default:
          _usageError('未知子命令：$sub（可用：path / lint / submit / search / status）');
      }
    },
  ).run(argv);
  return result;
}

void _path(ArgResults args, Directory root, bool asJson) {
  String? package;
  try {
    package = validatePackageName(args['package'] as String?);
  } on FormatException catch (e) {
    _usageError(e.message);
  }
  final ledgerName = package == null ? null : feedbackLedgerName(package);
  if (ledgerName != null && !feedbackPackages.contains(ledgerName)) {
    _usageError('未知反馈包：$ledgerName（可选：${feedbackPackages.join(', ')}）');
  }
  final target = FeedbackTarget.resolve(projectRoot: root, package: ledgerName);
  if (asJson) {
    print(
      jsonEncode(<String, Object?>{
        'schema': 'w_tools_cli.feedback/1',
        'schemaVersion': 1,
        ...target.toJson(),
      }),
    );
    return;
  }

  if (!target.isLibrary) {
    print('未启用本地反馈通道：默认不写文件。');
    print('仓库内用 feedback submit --ledger；消费方开启 feedback.issue 后用 --issue。');
    return;
  }
  print(target.path!);
  if (target.kind == 'library-dir') {
    print('# 库侧反馈目录；按包选文件，如 --package=cli');
  } else if (!target.exists) {
    stderr.writeln(
      '# 该包还没有库侧台账；在仓库内用 feedback submit --package=${package ?? '<包>'} --ledger 建档',
    );
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
  if (!result.ok) throw CliExit(1);
}

void _submit(ArgResults args, Directory root, bool asJson) {
  if (args['template'] as bool) {
    print(feedbackBodyTemplate);
    return;
  }
  final package = _packageArg(args)!;
  final name = feedbackLedgerName(package);
  if (!feedbackPackages.contains(name)) {
    _usageError('未知反馈包：$name（可选：${feedbackPackages.join(', ')}）');
  }

  final explicitIssue = (args['issue'] as bool) || (args['gh'] as bool);
  final modes = [explicitIssue, args['ledger']].where((v) => v == true).length;
  if (modes > 1) {
    _usageError('--issue / --ledger 只能选一个');
  }

  DoctorConfig config;
  try {
    config = ProjectFiles.loadConfig(root);
  } on ProjectLoadException catch (e) {
    _usageError(e.message);
  }
  final repo = isWtoolsRepo(root);
  final wantLedger = (args['ledger'] as bool) || (!explicitIssue && repo);
  final wantIssue = explicitIssue || (!(args['ledger'] as bool) && !repo && config.feedbackIssue);

  if (!wantLedger && !wantIssue) {
    if (asJson) {
      print(
        jsonEncode({
          'package': name,
          'mode': 'skipped',
          'reason': 'no_channel',
        }),
      );
    } else {
      print('反馈未提交：当前不是 w_tools 仓库，且 feedback.issue=false。');
      print('在 w_tools 仓库内用 --ledger；或项目开启 feedback.issue: true 后重试。');
    }
    return;
  }

  final linkedRaw = (args['linked-issue'] as String?)?.trim();
  int? linkedIssue;
  if (linkedRaw != null && linkedRaw.isNotEmpty) {
    linkedIssue = int.tryParse(linkedRaw.replaceFirst('#', ''));
    if (linkedIssue == null || linkedIssue <= 0) {
      _usageError('--linked-issue 需要正整数：$linkedRaw');
    }
    if (!wantLedger) _usageError('--linked-issue 只能配合 --ledger 使用');
  }

  final title = (args['title'] as String?)?.trim() ?? '';
  if (title.isEmpty) _usageError('submit 需要 --title=<一句话现象>');

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

  final draft = FeedbackDraft(package: name, title: title, body: body);
  final missing = draft.missingFields;
  if (missing.isNotEmpty) {
    final message =
        '反馈缺少必填字段：${missing.join('、')}；'
        '按 `feedback submit --template` 的字段补全后重试。';
    if (asJson) {
      stdout.writeln(
        jsonEncode({
          'schema': 'w_tools_cli.feedback/1',
          'ok': false,
          'error': message,
        }),
      );
      throw CliExit(2);
    }
    stderr.writeln(message);
    throw CliExit(2);
  }

  if (wantLedger) {
    try {
      final result = addToLedger(
        root,
        draft,
        linkedIssue: linkedIssue,
        allowDuplicate: args['allow-duplicate'] as bool,
      );
      if (asJson) {
        print(
          jsonEncode({
            ...draft.toJson(),
            'mode': 'ledger',
            'ledgerPath': result.file.path,
            'pending': result.pending,
          }),
        );
      } else {
        print('已写入库侧台账：${result.file.path}（待处理 ${result.pending} 条）');
      }
    } on FeedbackLedgerException catch (e) {
      stderr.writeln(e.message);
      throw CliExit(2);
    }
    return;
  }

  try {
    final url = createGitHubIssue(draft, repo: args['repo'] as String);
    if (asJson) {
      print(jsonEncode({...draft.toJson(), 'mode': 'gh', 'issueUrl': url.toString()}));
    } else {
      print('已创建 GitHub issue：$url');
    }
  } on FeedbackExternalException catch (e) {
    _externalError(e.message);
  } on FeedbackSubmitException catch (e) {
    stderr.writeln(e.message);
    throw CliExit(1);
  }
}

/// 外部工具不可用：统一退出码 3（与 README / cli.dart 的约定一致）。
Never _externalError(String message) {
  if (_jsonMode) {
    stdout.writeln(
      jsonEncode({
        'schema': 'w_tools_cli.feedback/1',
        'ok': false,
        'error': message,
      }),
    );
  } else {
    stderr.writeln(message);
  }
  throw CliExit(3);
}

void _status(Directory root, bool asJson) {
  DoctorConfig config;
  try {
    config = ProjectFiles.loadConfig(root);
  } on ProjectLoadException catch (e) {
    _usageError(e.message);
  }
  final repo = isWtoolsRepo(root);
  final channel = repo ? 'ledger' : (config.feedbackIssue ? 'issue' : 'disabled');
  if (asJson) {
    print(
      jsonEncode({
        'schema': 'w_tools_cli.feedback/1',
        'schemaVersion': 1,
        'channel': channel,
        'isWtoolsRepo': repo,
        'feedbackIssue': config.feedbackIssue,
        'ledger': repo ? '${root.path}/docs/feedback' : null,
      }),
    );
    return;
  }
  switch (channel) {
    case 'ledger':
      print('反馈通道：ledger（${root.path}/docs/feedback）');
    case 'issue':
      print('反馈通道：issue（feedback.issue=true；需要 gh 登录/令牌）');
    default:
      print('反馈通道：disabled（默认不提交）');
      print('w_tools 仓库内自动用 ledger；消费方在 .w_tools_doctor.yaml 设置 feedback.issue: true');
  }
}

void _search(ArgResults args, Directory root, bool asJson) {
  final query = args.rest.skip(1).join(' ').trim();
  if (query.isEmpty) _usageError('search 需要一个关键词');
  final rawPackage = _packageArg(args, required: false);
  final package = rawPackage == null ? null : feedbackLedgerName(rawPackage);
  if (package != null && !feedbackPackages.contains(package)) {
    _usageError('未知反馈包：$package（可选：${feedbackPackages.join(', ')}）');
  }

  final local = searchLocal(root, package: package, query: query);
  final github = <Map<String, Object?>>[];
  if (args['gh'] as bool) {
    try {
      github.addAll(_searchGitHub(query, package: package, repo: args['repo'] as String));
    } on FeedbackSubmitException catch (e) {
      _externalError(e.message);
    } on FeedbackExternalException catch (e) {
      _externalError(e.message);
    }
  }

  if (asJson) {
    print(
      jsonEncode({
        'schema': 'w_tools_cli.feedback/1',
        'schemaVersion': 1,
        'query': query,
        'package': package,
        'local': [for (final m in local) m.toJson()],
        'github': github,
      }),
    );
  } else {
    if (local.isEmpty && github.isEmpty) {
      print('没有找到相关反馈。');
    }
    for (final m in local) {
      print('${m.file}:${m.line}  ${m.text}');
    }
    for (final issue in github) {
      print('GitHub #${issue['number']}  ${issue['title']}  ${issue['url']}');
    }
  }
  if (local.isEmpty && github.isEmpty) throw CliExit(1);
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
  final ProcessResult auth;
  try {
    auth = Process.runSync('gh', const <String>['auth', 'status']);
  } on ProcessException {
    throw const FeedbackExternalException('找不到 gh CLI；先安装并登录 gh，或去掉 --gh');
  }
  if (auth.exitCode != 0) {
    throw const FeedbackExternalException('gh 未登录；先运行 gh auth login，或去掉 --gh');
  }
  final q = package == null ? query : '$query $package';
  final ProcessResult result;
  try {
    result = Process.runSync('gh', <String>[
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
  } on ProcessException {
    throw const FeedbackExternalException('找不到 gh CLI；先安装并登录 gh，或去掉 --gh');
  }
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
  if (_jsonMode) {
    stdout.writeln(
      jsonEncode({
        'schema': 'w_tools_cli.feedback/1',
        'ok': false,
        'error': message,
      }),
    );
  } else {
    stderr.writeln('参数错误：$message\n');
    stderr.writeln(_usage);
  }
  throw CliExit(2);
}
