import 'dart:io';

import 'package:args/args.dart';

import 'version.dart';

/// 所有入口共用的解析器：`--version` / `--help` 自动带上。
ArgParser cliParser() => ArgParser()
  ..addFlag('version', negatable: false)
  ..addFlag('help', abbr: 'h', negatable: false);

/// 统一处理参数解析、`--help`、`--version` 与错误退出码（2）。
void runCli(
  List<String> argv, {
  required String usage,
  required ArgParser parser,
  required void Function(ArgResults args) body,
}) {
  ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln('参数错误：${e.message}\n');
    stderr.writeln(usage);
    exit(2);
  }
  if (args['version'] as bool) {
    print(cliVersion);
    return;
  }
  if (args['help'] as bool) {
    print(usage);
    return;
  }
  body(args);
}
