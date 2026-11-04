import 'dart:convert';
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
  final wantsJson = argv.contains('--json') || argv.contains('--format=json');
  Never usageError(String message) {
    if (wantsJson) {
      stdout.writeln(
        jsonEncode({
          'schema': 'w_tools_cli.error/1',
          'ok': false,
          'error': message,
        }),
      );
    } else {
      stderr.writeln('参数错误：$message\n');
      stderr.writeln(usage);
    }
    exit(2);
  }

  ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    usageError(e.message);
  }
  if (parser.options.containsKey('format') &&
      args.wasParsed('json') &&
      args.wasParsed('format') &&
      args['format'] != 'json') {
    usageError('--json 与 --format=${args['format']} 冲突');
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

/// 统一的机器输出格式：`--json` 是 `--format=json` 的别名。
String outputFormat(ArgResults args, {String fallback = 'text'}) {
  if (args.options.contains('json') && args['json'] == true) return 'json';
  return (args['format'] as String?) ?? fallback;
}

/// 一个子命令的声明：usage + parser + body，入口只负责选择命令。
///
/// 保留 [runCli] 作为执行器；后续可让 body 返回退出码、在进程内组合命令。
class CliCommand {
  const CliCommand({
    required this.usage,
    required this.parser,
    required this.body,
  });

  final String usage;
  final ArgParser parser;
  final void Function(ArgResults) body;

  void run(List<String> argv) => runCli(argv, usage: usage, parser: parser, body: body);
}
