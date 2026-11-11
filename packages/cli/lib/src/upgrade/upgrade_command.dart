// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' show YamlMap;

import '../common/cli.dart';
import '../common/project_pubspec.dart';
import '../common/pubspec_lock.dart';
import 'hosted.dart';
import 'pubspec_edit.dart';
import 'upgrade_plan.dart';
import 'upgrade_report.dart';

const _usage = '''
w_tools_cli upgrade —— 把 w_tools 系依赖抬到 hosted 上的最新版本

用法：dart run w_tools_cli:w_tools upgrade [选项]

只处理 w_tools / w_tools_*；其它依赖（包括刻意钉死的版本）一律不动。

选项：
  --root=<dir>        项目根目录（默认当前目录）
  --check             只检查不写文件；有可升级 / lock 落后时退出 1
  --dry-run           打印将要写入的改动，不写文件、不跑 pub
  --major             允许跨 major（0.x 包跨 minor 也算跨 major）；默认只报告
  --only=<a,b>        只处理指名的包（配合 --major 可只放开某几个）
  --no-get            只改 pubspec，不跑 pub get
  --hosted=<url>      覆盖 hosted 源（默认 PUB_HOSTED_URL，再退回 pub.dev）
  --format=<fmt>      text | json | prompt（默认 text）
  --json              等价于 --format=json
  --strict            跨 major / 被 SDK 挡住也算落后（配合 --check）
  --version           显示版本
  --help, -h          显示本帮助

退出码：
  0  成功（含「已是最新」）
  1  --check 发现落后（--strict 时包含跨 major / SDK 不兼容）
  2  参数或项目错误（无 pubspec、workspace 项目、pub get 失败）
  3  hosted 源不可用 / 跑不了 pub

示例：
  dart run w_tools_cli:w_tools upgrade --check
  dart run w_tools_cli:w_tools upgrade --dry-run
  dart run w_tools_cli:w_tools upgrade
  dart run w_tools_cli:w_tools upgrade --major --only=w_tools_ui

说明：
  默认只抬「同 caret 窗口」的包，并跑一次 pub get；pub get 失败会还原 pubspec.yaml。
  w_tools_cli 自己被抬后，需要用新版本重跑 init 刷新生成物（命令会打印 next）。
''';

/// 跑 pub 的注入点：测试用它模拟「解析冲突」而不真的联网。
typedef PubRunner =
    ProcessResult Function(String executable, List<String> arguments, String workingDirectory);

ProcessResult _runPub(String executable, List<String> arguments, String workingDirectory) =>
    Process.runSync(executable, arguments, workingDirectory: workingDirectory);

/// 查询最新版本是异步的，而 [Command] 的 body 是同步的：
/// 同步部分只做参数 / 项目校验，真正的流程挂到 [pending]，由这里 await。
Future<CommandResult> run(
  List<String> argv, {
  LatestFetcher? fetcher,
  PubRunner? pubRunner,
}) async {
  Future<int>? pending;
  final result = Command(
    usage: _usage,
    parser: _parser(),
    body: (args) {
      pending = _execute(args, fetcher, pubRunner ?? _runPub);
    },
  ).run(argv);
  final work = pending;
  if (work == null) return result; // --help / --version / 参数错误
  return CommandResult(await work);
}

ArgParser _parser() => cliParser()
  ..addOption('root')
  ..addFlag('check', negatable: false)
  ..addFlag('dry-run', negatable: false)
  ..addFlag('major', negatable: false)
  ..addOption('only')
  ..addFlag('get', defaultsTo: true)
  ..addOption('hosted')
  ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json', 'prompt'])
  ..addFlag('json', negatable: false)
  ..addFlag('strict', negatable: false);

Future<int> _execute(ArgResults args, LatestFetcher? injected, PubRunner runPub) async {
  try {
    return await _runUpgrade(args, injected, runPub);
  } on CliExit catch (e) {
    return e.code;
  } on HostedException catch (e) {
    return _fail(args, 'hosted 源不可用：${e.message}', 3);
  } on PubspecLockException catch (e) {
    return _fail(args, e.message, 2);
  } catch (error) {
    return _fail(args, 'upgrade 失败：$error', 3);
  }
}

/// 异步阶段不能再抛给 [runCli] 的兜底，这里把 [failCli] 的 CliExit 收成退出码。
int _fail(ArgResults args, String message, int code) {
  var result = code;
  try {
    failCli(args, message, code: code);
  } on CliExit catch (e) {
    result = e.code;
  }
  return result;
}

Future<int> _runUpgrade(ArgResults args, LatestFetcher? injected, PubRunner runPub) async {
  final format = outputFormat(args);
  final root = Directory(args['root'] as String? ?? Directory.current.path);
  final pubspecFile = File('${root.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    failCli(args, '找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
  }
  final source = pubspecFile.readAsStringSync();
  final pubspec = ProjectPubspec.load(root);
  if (pubspec.parseError != null) {
    failCli(args, 'pubspec.yaml 解析失败：${pubspec.parseError}');
  }
  if (pubspec.raw['resolution'] == 'workspace') {
    failCli(args, '这是 workspace 项目（resolution: workspace）：包版本来自本地 workspace，不适用 upgrade');
  }
  if (pubspec.declaredName == 'w_tools' && Directory('${root.path}/packages/cli').existsSync()) {
    failCli(args, '这是 w_tools 仓库自身：子包版本由仓库维护，不适用 upgrade');
  }

  final names = <String>{
    ...pubspec.dependencies.keys,
    ...pubspec.devDependencies.keys,
  }.where(isWToolsDependency).toList()..sort();
  final only = _parseOnly(args, names);

  final fetcher = injected ?? HttpLatestFetcher(hosted: args['hosted'] as String?);
  final targets = only.isEmpty ? names : names.where(only.contains).toList();
  final latest = targets.isEmpty ? const <String, LatestRelease?>{} : await fetcher.fetch(targets);

  final plan = buildPlan(
    hosted: fetcher.hosted,
    dependencies: pubspec.dependencies,
    devDependencies: pubspec.devDependencies,
    locked: readLockedVersions(root),
    latest: latest,
    overrides: _overrides(pubspec),
    allowMajor: args['major'] as bool,
    only: only,
  );

  final check = args['check'] as bool;
  final dryRun = args['dry-run'] as bool;
  final strict = args['strict'] as bool;
  final mode = check ? 'check' : (dryRun ? 'dry-run' : 'write');
  final projectName = pubspec.declaredName ?? '(未命名项目)';

  var written = <String, String>{};
  String? pubCommand;
  int? pubExit;
  String? pubOutput;
  var restored = false;

  if (mode == 'write') {
    final writable = plan.writable.toList();
    if (writable.isNotEmpty) {
      final edit = raiseConstraints(source, <String, String>{
        for (final pkg in writable) pkg.name: pkg.target!,
      });
      if (edit.missed.isNotEmpty) {
        failCli(args, 'pubspec.yaml 里找不到这些依赖的约束行：${edit.missed.join('、')}（请手工处理）');
      }
      if (edit.applied.isEmpty) {
        failCli(args, '没有可写入的改动（pubspec 可能已被改过，重跑一次）');
      }
      pubspecFile.writeAsStringSync(edit.text);
      written = edit.applied;
    }

    final lockBehind = plan.packages.any((p) => p.lockBehind);
    if (args['get'] as bool && (written.isNotEmpty || lockBehind)) {
      final executable = pubspec.isFlutter ? 'flutter' : 'dart';
      pubCommand = '$executable pub get';
      final ProcessResult result;
      try {
        result = runPub(executable, <String>['pub', 'get'], root.path);
      } on ProcessException catch (e) {
        if (written.isNotEmpty) pubspecFile.writeAsStringSync(source);
        failCli(args, '跑不了 $pubCommand：${e.message}（可加 --no-get 跳过）', code: 3);
      }
      pubExit = result.exitCode;
      if (result.exitCode != 0) {
        // 解析冲突不是「项目坏了」，但也不能留下半改的 pubspec。
        if (written.isNotEmpty) pubspecFile.writeAsStringSync(source);
        restored = true;
        final tail = _tail('${result.stdout}\n${result.stderr}');
        pubOutput = tail.isEmpty ? '（pub 没有输出）' : tail;
      }
    }
  } else if (mode == 'dry-run') {
    // 预览也要打印 diff，但一个字都不写。
    written = <String, String>{for (final pkg in plan.writable) pkg.name: pkg.target!};
  }

  final findings = plan.hasFindings || (strict && plan.hasRisks);
  final outcome = UpgradeOutcome(
    projectName: projectName,
    mode: mode,
    written: written,
    pubCommand: pubCommand,
    pubExit: pubExit,
    pubOutput: pubOutput,
    restored: restored,
    next: _next(
      plan: plan,
      mode: mode,
      written: written,
      ranPub: pubCommand != null,
      findings: findings,
      restored: restored,
      isFlutter: pubspec.isFlutter,
    ),
  );

  switch (format) {
    case 'json':
      print(outcome.toJsonText(plan));
    case 'prompt':
      print(outcome.toPrompt(plan));
    default:
      print(outcome.toText(plan));
  }

  if (restored) return 2;
  if (check) return findings ? 1 : 0;
  return 0;
}

Set<String> _overrides(ProjectPubspec pubspec) {
  final overrides = pubspec.raw['dependency_overrides'];
  if (overrides is! YamlMap) return const <String>{};
  return <String>{for (final key in overrides.keys) '$key'};
}

Set<String> _parseOnly(ArgResults args, List<String> names) {
  final raw = args['only'] as String?;
  if (raw == null) return const <String>{};
  final only = <String>{
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  };
  if (only.isEmpty) failCli(args, '--only 需要至少一个包名（如 --only=w_tools_ui）');
  final unknown = only.difference(names.toSet());
  if (unknown.isNotEmpty) {
    failCli(
      args,
      '--only 里的包不是 w_tools 系依赖：${unknown.join('、')}'
      '（可选：${names.join('、')}）',
    );
  }
  return only;
}

String _tail(String output, {int lines = 12}) {
  final all = output.trim().split('\n').where((line) => line.trim().isNotEmpty).toList();
  if (all.length <= lines) return all.join('\n');
  return all.sublist(all.length - lines).join('\n');
}

List<String> _next({
  required UpgradePlan plan,
  required String mode,
  required Map<String, String> written,
  required bool ranPub,
  required bool findings,
  required bool restored,
  required bool isFlutter,
}) {
  if (restored) {
    return <String>['先按 pub 输出解决版本冲突（或加 --only=<包> 分批），再重跑 upgrade'];
  }
  final next = <String>[];
  if (written.isNotEmpty && !ranPub) {
    next.add('${isFlutter ? 'flutter' : 'dart'} pub get');
  }
  if (written.containsKey('w_tools_cli')) {
    next.add('用新 CLI 刷新生成物：dart run w_tools_cli:w_tools init --force');
    next.add('再自检：dart run w_tools_cli:w_tools doctor --format=json');
  }
  if (mode == 'check' && findings) {
    next.add('写入并安装：dart run w_tools_cli:w_tools upgrade');
  }
  if (mode == 'dry-run' && plan.writable.isNotEmpty) {
    next.add('真正写入：dart run w_tools_cli:w_tools upgrade');
  }
  if (plan.count(UpgradeStatus.majorBlocked) > 0) {
    next.add('跨 major 的包确认后加 --major（或用 --only=<包> 单独放开）');
  }
  return next;
}
