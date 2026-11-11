import 'package:args/args.dart';
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/feedback/feedback_budget.dart';
import 'package:w_tools_cli/src/feedback/feedback_channel.dart';
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
  path    输出台账路径（本机没有 w_tools 仓库时不写文件）
  lint    校验字段、状态、版本号、索引
  submit  默认路由：本地 w_tools 台账 → GitHub Issue → 跳过（exit 4）
  search  先查重：本地台账/收件箱；加 --gh 同时搜 GitHub issues
  status  输出当前通道：ledger / issue / disabled（附带 gh 可用性与公开 Issue 日额度）

通道（submit / status 共用同一套判定）：
  1. 项目根是 w_tools 仓库      → 写 <仓库>/docs/feedback/（维护者默认，不读开关）
  2. feedback.enabled: true 且本机有 w_tools 检出 → 写该仓库 docs/feedback/（不公开发）
  3. feedback.enabled: true 且本机没有检出        → 建 GitHub Issue
  4. 未开启 / 都没有                              → 跳过（exit 4，不写文件）

选项：
  --root=<dir>        项目根（默认当前目录）
  --package=<包>      包名（小写字母/数字/下划线）
  --title=<标题>      submit 用：一句话现象
  --body-file=<file>  submit 用：Markdown 正文（也可用 --stdin）
  --stdin             submit 用：从标准输入读 Markdown 正文
  --template          submit 用：只打印正文骨架，不提交
  --issue             submit：强制建 GitHub Issue（需 feedback.enabled；本机有台账时默认写台账）
  --gh                submit：--issue 的别名；search：搜 GitHub issues
  --ledger            submit：强制写本地台账（需本机 w_tools 仓库检出）
  --linked-issue=<n>  ledger 用：在条目里写「关联 issue：#n」
  --allow-duplicate   ledger 用：允许写入完全相同的反馈（默认拒绝）
  --repo=<owner/repo> submit/search 的仓库（默认 stone0533/w_tools）
  --include-inbox     lint 用：连同本地收件箱一起校验
  --stale-days=<n>    lint 用：待处理超过 n 天给警告（默认 30，0 = 关闭）
  --format=<fmt>      text | json（默认 text）
  --json              等价于 --format=json
  -h, --help          显示本帮助

退出码：
  0  成功（含「没有可校验的反馈文件」）
  1  查重没找到 / lint 有规则问题
  2  参数或配置错误（含 feedback.enabled=false 时的 --issue）
  3  外部工具不可用（gh 未安装 / 未登录）
  4  跳过：没有可用通道，什么都没写

说明：
  --gh 需要 gh 已安装并登录；gh 不可用时退出 3，且不返回本地查重结果。
  只想查本地台账时去掉 --gh。

示例：
  dart run w_tools_cli:w_tools feedback search "WImage 缓存" --package=ui
  dart run w_tools_cli:w_tools feedback submit --package=ui --title="WImage 缓存不生效" --stdin
  dart run w_tools_cli:w_tools feedback submit --package=ui --title="..." --body-file=/tmp/f.md --issue
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
  final channel = _channel(root);
  final dir = channel.ledgerDir;
  final target = dir == null ? null : (ledgerName == null ? dir : p.join(dir, '$ledgerName.md'));
  final exists = target == null
      ? false
      : (ledgerName == null ? Directory(target).existsSync() : File(target).existsSync());
  final kind = dir == null ? 'disabled' : (ledgerName == null ? 'library-dir' : 'library-package');

  if (asJson) {
    print(
      jsonEncode(<String, Object?>{
        'schema': 'w_tools_cli.feedback/1',
        'schemaVersion': 1,
        'path': target,
        'kind': kind,
        'exists': exists,
        ...channel.toJson(),
      }),
    );
    return;
  }

  if (target == null) {
    print('未启用本地反馈通道：本机没有 w_tools 仓库，默认不写文件。');
    print('仓库内用 feedback submit --ledger；消费方开启 feedback.enabled 后走默认通道（本地台账优先，其次 Issue）。');
    return;
  }
  _warnInvalidOverride(channel);
  print(target);
  if (ledgerName == null) {
    print('# 库侧反馈目录；按包选文件，如 --package=cli');
  } else if (!exists) {
    stderr.writeln('# 该包还没有库侧台账；用 feedback submit --package=$ledgerName --ledger 建档');
  }
}

/// 通道解析只做一次：`submit` / `status` / `path` / `search` / `lint` 共用。
typedef _Resolved = ({FeedbackChannel channel, DoctorConfig config});

_Resolved _resolve(Directory root) {
  DoctorConfig config;
  try {
    config = ProjectFiles.loadConfig(root);
  } on ProjectLoadException catch (e) {
    _usageError(e.message);
  }
  final channel = FeedbackChannel.resolve(
    projectRoot: root,
    issueEnabled: config.feedbackEnabled,
    ledgerOverride: config.feedbackLedger,
  );
  return (channel: channel, config: config);
}

FeedbackChannel _channel(Directory root) => _resolve(root).channel;

void _lint(ArgResults args, Directory root, bool asJson) {
  final staleDaysRaw = args['stale-days'] as String;
  final staleDays = int.tryParse(staleDaysRaw);
  if (staleDays == null) {
    _usageError('--stale-days 需要整数：$staleDaysRaw');
  }
  final channel = _channel(root);
  final linter = FeedbackLinter(staleDays: staleDays);
  final paths = <String>[];
  final dir = channel.ledgerDir;
  FeedbackLintResult result = dir == null
      ? FeedbackLintResult(files: const <String>[], pending: 0, closed: 0)
      : linter.lintLibrary(Directory(dir));
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

  if (result.files.isEmpty) {
    if (asJson) {
      print(
        jsonEncode(<String, Object?>{
          'schema': 'w_tools_cli.feedback/1',
          'ok': true,
          'skipped': true,
          'reason': 'no_ledger',
          ...channel.toJson(),
          ...result.toJson(),
        }),
      );
      return;
    }
    print('跳过：本机没有可校验的反馈文件（没有 w_tools 台账，也没有旧收件箱）。');
    print('台账只存在于 w_tools 仓库检出；消费方默认不写台账，这里没有可校验的内容即正常。');
    return;
  }

  if (asJson) {
    print(jsonEncode(result.toJson()));
  } else {
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
  final explicitLedger = args['ledger'] as bool;
  if (explicitIssue && explicitLedger) {
    _usageError('--issue / --ledger 只能选一个');
  }

  final resolved = _resolve(root);
  final channel = resolved.channel;
  // 开关是硬门禁：消费方未开启时 --issue 也不放行，否则「默认关闭」名存实亡。
  if (explicitIssue && !channel.enabled && !channel.isWtoolsRepo) {
    _usageError(
      'feedback.enabled=false：反馈通道未开启，--issue 不会绕过开关。'
      '在 .w_tools_doctor.yaml 写 feedback.enabled: true 后重试；'
      '只想写本地台账用 --ledger（需本机 w_tools 仓库检出）',
    );
  }
  if (explicitLedger && !channel.hasLedger) {
    _usageError('--ledger 需要本机 w_tools 仓库检出（pubspec name=w_tools + packages/cli + docs/feedback）');
  }

  _warnInvalidOverride(channel);
  final wantLedger = explicitLedger || (!explicitIssue && channel.mode == FeedbackMode.ledger);
  final wantIssue = !wantLedger && (explicitIssue || channel.mode == FeedbackMode.issue);

  if (!wantLedger && !wantIssue) {
    _skipped(name, root, channel, asJson);
    throw const CliExit(4);
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
    _refused(
      '反馈缺少必填字段：${missing.join('、')}；'
      '按 `feedback submit --template` 的字段补全后重试。',
      asJson,
    );
  }

  if (wantLedger) {
    final repoRoot = channel.repoRoot!;
    try {
      final result = addToLedger(
        Directory(repoRoot),
        draft,
        linkedIssue: linkedIssue,
        allowDuplicate: args['allow-duplicate'] as bool,
      );
      final dirtiesRepo = p.normalize(repoRoot) != p.normalize(root.path);
      if (asJson) {
        print(
          jsonEncode({
            ...draft.toJson(),
            'mode': 'ledger',
            'repoRoot': repoRoot,
            'dirtiesRepo': dirtiesRepo,
            'ledgerPath': result.file.path,
            'pending': result.pending,
          }),
        );
      } else {
        print('已写入库侧台账：${result.file.path}（待处理 ${result.pending} 条）');
        if (dirtiesRepo) {
          print('本机 w_tools 检出：$repoRoot（没有建 Issue）');
          stderr.writeln(
            '# 这次写的是本机 w_tools 检出：$repoRoot；该仓库工作区会变脏，'
            '提交前记得 commit / discard',
          );
        }
      }
    } on FeedbackLedgerException catch (e) {
      stderr.writeln(e.message);
      throw CliExit(2);
    }
    return;
  }

  if (channel.hasLedger) {
    stderr.writeln('# 本机有 w_tools 台账（${channel.ledgerDir}）；本次按 --issue 建公开 Issue');
  }

  // 「一次会话 3–5 条」没有会话边界可判，用「每天 N 条公开 Issue」兜住；本地台账不占额度。
  final budget = FeedbackBudget(FeedbackBudget.fileFor(root));
  final maxIssues = resolved.config.feedbackMaxIssuesPerDay;
  if (!budget.allows(maxIssues)) {
    final remaining = budget.remainingFor(maxIssues) ?? 0;
    _refused(
      '今天的公开反馈额度已用完：已用 ${budget.usedToday()} / 上限 $maxIssues / 剩余 $remaining 条。'
      '上限默认 5，可在 ${p.join(root.path, '.w_tools_doctor.yaml')} 的 '
      'feedback.max_issues_per_day 调高（0 = 不限）。'
      '预算文件：${budget.file.path}；本地台账不占额度，可用 --ledger；'
      '或调高上限 / 删除预算文件（会归零）。',
      asJson,
    );
  }

  try {
    final url = createGitHubIssue(draft, repo: args['repo'] as String);
    budget.record();
    if (asJson) {
      print(
        jsonEncode({
          ...draft.toJson(),
          'mode': 'gh',
          'issueUrl': url.toString(),
          'issueBudgetUsed': budget.usedToday(),
          'issueBudgetMax': maxIssues,
        }),
      );
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

/// 拒绝提交（字段不全 / 公开额度用完）：统一退出码 2，`--json` 时给错误信封。
Never _refused(String message, bool asJson) {
  if (asJson) {
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
  throw CliExit(2);
}

/// `feedback.ledger` 配了但不指向 w_tools 仓库：提醒一次，别让它静默失效。
void _warnInvalidOverride(FeedbackChannel channel) {
  final invalid = channel.ledgerOverrideInvalid;
  if (invalid == null) return;
  stderr.writeln(
    '# feedback.ledger 不是 w_tools 仓库检出（需要 pubspec name=w_tools + packages/cli + docs/feedback）：'
    '$invalid；已忽略',
  );
}

/// 没有可用通道：明确说明「什么都没写」，并用 exit 4 让 AI / CI 无法把它当成功。
void _skipped(String name, Directory root, FeedbackChannel channel, bool asJson) {
  final localLedger = channel.ledgerDir;
  if (asJson) {
    print(
      jsonEncode(<String, Object?>{
        'package': name,
        'mode': 'skipped',
        'reason': 'disabled',
        'exitCode': 4,
        ...channel.toJson(),
        'localLedger': localLedger,
      }),
    );
    return;
  }
  print('反馈未提交（exit 4）：当前项目没有开启反馈通道，什么都没有写。');
  print('项目：${root.path}');
  print(
    localLedger == null ? '本机 w_tools 台账：无' : '本机 w_tools 台账：$localLedger（可用 --ledger 直接写）',
  );
  print('开启：.w_tools_doctor.yaml → feedback.enabled: true（开启后本地台账优先，其次 GitHub Issue）');
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
  final resolved = _resolve(root);
  final channel = resolved.channel;
  final maxIssues = resolved.config.feedbackMaxIssuesPerDay;
  final budget = FeedbackBudget(FeedbackBudget.fileFor(root));
  final gh = channel.mode == FeedbackMode.issue ? GhStatus.probe() : null;
  if (asJson) {
    print(
      jsonEncode(<String, Object?>{
        'schema': 'w_tools_cli.feedback/1',
        'schemaVersion': 1,
        ...channel.toJson(),
        if (channel.mode == FeedbackMode.disabled)
          'enableHint': '在 .w_tools_doctor.yaml 写 feedback.enabled: true 后重跑 status',
        'gh': gh?.toJson(),
        'budget': budget.toJson(max: maxIssues),
      }),
    );
    return;
  }
  _warnInvalidOverride(channel);
  switch (channel.mode) {
    case FeedbackMode.ledger:
      final where = channel.isWtoolsRepo ? '本仓库' : '本机 w_tools 检出';
      print('反馈通道：ledger（${channel.ledgerDir}；$where）');
    case FeedbackMode.issue:
      final ghText = gh?.ready == true ? 'gh 已就绪' : 'gh 不可用（未安装 / 未登录）→ 提交会退出 3';
      print('反馈通道：issue（feedback.enabled=true；$ghText）');
    case FeedbackMode.disabled:
      print('反馈通道：disabled（默认不提交；跳过时 exit 4，不写文件）');
      if (channel.ledgerDir != null) {
        print('本机 w_tools 台账：${channel.ledgerDir}（不自动写；--ledger 可显式写）');
      }
      print('开启：.w_tools_doctor.yaml → feedback.enabled: true');
  }
  final remaining = budget.remainingFor(maxIssues);
  final maxText = maxIssues <= 0 ? '不限' : '$maxIssues';
  final remainingText = remaining == null ? '不限' : '$remaining';
  print(
    '公开反馈额度：已用 ${budget.usedToday()} / 上限 $maxText（剩余 $remainingText）；'
    '预算文件：${budget.file.path}',
  );
}

void _search(ArgResults args, Directory root, bool asJson) {
  final query = args.rest.skip(1).join(' ').trim();
  if (query.isEmpty) _usageError('search 需要一个关键词');
  final rawPackage = _packageArg(args, required: false);
  final package = rawPackage == null ? null : feedbackLedgerName(rawPackage);
  if (package != null && !feedbackPackages.contains(package)) {
    _usageError('未知反馈包：$package（可选：${feedbackPackages.join(', ')}）');
  }

  final channel = _channel(root);
  final local = searchLocal(
    root,
    package: package,
    query: query,
    ledgerDir: channel.ledgerDir,
  );
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
    if (channel.ledgerDir == null) {
      print('本机没有 w_tools 台账：本地查重不可用，加 --gh 搜 GitHub issues。');
    }
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
