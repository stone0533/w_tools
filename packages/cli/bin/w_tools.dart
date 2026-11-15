// ignore_for_file: avoid_print

import 'dart:io';

import 'package:w_tools_cli/src/catalog/list_command.dart' as list;
import 'package:w_tools_cli/src/command_registry.dart';
import 'package:w_tools_cli/src/common/version.dart';
import 'package:w_tools_cli/src/context/command.dart' as context;
import 'package:w_tools_cli/src/doctor/command.dart' as doctor;
import 'package:w_tools_cli/src/explain/explain_command.dart' as explain;
import 'package:w_tools_cli/src/feedback/feedback_command.dart' as feedback;
import 'package:w_tools_cli/src/init/command.dart' as init;
import 'package:w_tools_cli/src/upgrade/upgrade_command.dart' as upgrade;

final _usage =
    '''
w_tools_cli —— w_tools 项目工具

用法：
  dart run w_tools_cli:w_tools <command> [options]

命令：
${commandUsageLines()}
''';

Future<void> main(List<String> argv) async {
  if (argv.isEmpty || argv.first == '--help' || argv.first == '-h') {
    stdout.write(_usage);
    exitCode = argv.isEmpty ? 2 : 0;
    return;
  }
  // 只认顶层 `w_tools --version`；不要扫描整个 argv（`w_tools init --version`
  // 应该交给 init 自己处理，而不是静默跳过 init 只打印版本）。
  if (argv.first == '--version') {
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
