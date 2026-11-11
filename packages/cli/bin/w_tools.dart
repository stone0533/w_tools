// ignore_for_file: avoid_print

import 'dart:io';

import 'package:w_tools_cli/src/common/version.dart';

import 'context.dart' as context;
import 'doctor.dart' as doctor;
import 'explain.dart' as explain;
import 'feedback.dart' as feedback;
import 'init.dart' as init;
import 'list.dart' as list;

import 'package:w_tools_cli/src/upgrade/upgrade_command.dart' as upgrade;

const _usage = '''
w_tools_cli —— w_tools 项目工具

用法：
  dart run w_tools_cli:w_tools <command> [options]

命令：
  init       把 w_tools 接入项目
  doctor     检查项目是否遵守接入约定
  context    输出项目事实（AI / CI）
  list       查组件目录
  explain    解释一个组件
  upgrade    把 w_tools 系依赖抬到 pub 最新
  feedback   提交 w_tools 反馈

兼容入口仍保留：dart run w_tools_cli:init / doctor / ...
''';

Future<void> main(List<String> argv) async {
  if (argv.isEmpty || argv.first == '--help' || argv.first == '-h') {
    stdout.write(_usage);
    exitCode = argv.isEmpty ? 2 : 0;
    return;
  }
  if (argv.contains('--version')) {
    print(cliVersion);
    return;
  }
  final command = argv.first;
  final rest = argv.sublist(1);
  switch (command) {
    case 'init':
      exitCode = init.run(rest).exitCode;
    case 'doctor':
      exitCode = doctor.run(rest).exitCode;
    case 'context':
      exitCode = context.run(rest).exitCode;
    case 'list':
      exitCode = list.run(rest).exitCode;
    case 'explain':
      exitCode = explain.run(rest).exitCode;
    case 'upgrade':
      exitCode = (await upgrade.run(rest)).exitCode;
    case 'feedback':
      exitCode = feedback.run(rest).exitCode;
    default:
      stderr.writeln('未知命令：$command\n');
      stderr.write(_usage);
      exitCode = 2;
  }
}
