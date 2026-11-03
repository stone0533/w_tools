// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/context/install_info.dart';
import 'package:w_tools_cli/src/feedback/feedback_lint.dart';
import 'package:w_tools_cli/src/feedback/feedback_path.dart';

const _usage = '''
w_tools_cli feedback —— 反馈该写到哪 / 写对没有

用法：
  dart run w_tools_cli:feedback path [--package=<包>] [--json]
  dart run w_tools_cli:feedback lint [--include-inbox] [--json]

子命令：
  path   输出反馈该写到的文件（有库仓库 → 库侧；否则 → 本项目收件箱）
  lint   校验字段齐全、状态合法、已闭环带版本号（可加 --include-inbox 连收件箱一起查）

选项：
  --root=<dir>        项目根（默认当前目录）
  --package=<包>      path 用：库侧单包文件名（figma / cli / device / e2e …）
  --include-inbox     lint 用：连同 docs/agents/feedback.md 一起校验（仓库检出时也查）
  --stale-days=<n>    lint 用：待处理超过 n 天给警告（默认 30，0 = 关闭）
  --json              机器可读输出
  -h, --help          显示本帮助

示例：
  dart run w_tools_cli:feedback path --package=figma
  dart run w_tools_cli:feedback lint --include-inbox
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('package')
    ..addFlag('include-inbox', negatable: false)
    ..addOption('stale-days', defaultsTo: '30')
    ..addFlag('json', negatable: false);

  runCli(
    argv,
    usage: _usage,
    parser: parser,
    body: (args) {
      final rest = args.rest;
      final sub = rest.isEmpty ? 'path' : rest.first;
      final root = Directory(args['root'] as String? ?? Directory.current.path);
      final asJson = args['json'] as bool;

      switch (sub) {
        case 'path':
          final package = args['package'] as String?;
          if (package != null && !RegExp(r'^[a-z0-9_]+$').hasMatch(package)) {
            stderr.writeln('--package 只允许小写字母/数字/下划线：$package');
            exit(2);
          }
          final target = FeedbackTarget.resolve(
            projectRoot: root,
            package: package,
          );
          if (asJson) {
            print(jsonEncode(target.toJson()));
          } else {
            print(target.path);
            if (!target.isLibrary) {
              stderr.writeln('# 不是仓库检出：反馈写本项目收件箱（docs/agents/feedback.md）');
            } else if (!target.exists) {
              stderr.writeln('# 文件还不存在，首次反馈时新建（可照 docs/feedback/TEMPLATE.md）');
            }
          }
        case 'lint':
          final staleDays = int.tryParse(args['stale-days'] as String) ?? 30;
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
            // 无条件检查收件箱：仓库检出时它同样可能存在待同步条目
            final inboxPath = p.join(root.path, 'docs', 'agents', 'feedback.md');
            if (File(inboxPath).existsSync()) paths.add(inboxPath);
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
        default:
          stderr.writeln('未知子命令：$sub（可用：path / lint）');
          exit(2);
      }
    },
  );
}
