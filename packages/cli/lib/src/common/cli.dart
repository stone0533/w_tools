import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'version.dart';

/// 所有入口共用的解析器：`--version` / `--help` 自动带上。
ArgParser cliParser() => ArgParser()
  ..addFlag('version', negatable: false)
  ..addFlag('help', abbr: 'h', negatable: false);

/// 命令执行结果；`0` 成功，`1` findings，`2` 参数/配置，`3` 外部不可用。
class CommandResult {
  const CommandResult(this.exitCode);

  final int exitCode;

  static const ok = CommandResult(0);
}

/// 命令体主动中止时抛出，由 [runCli] 转为 [CommandResult]，不直接杀进程。
class CliExit implements Exception {
  const CliExit(this.code);

  final int code;
}

/// 统一处理参数解析、`--help`、`--version` 与错误退出码（2）。
CommandResult runCli(
  List<String> argv, {
  required String usage,
  required ArgParser parser,
  required void Function(ArgResults args) body,
}) {
  final wantsJson = _wantsJson(argv);
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
    throw const CliExit(2);
  }

  try {
    final ArgResults args;
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
      return CommandResult.ok;
    }
    if (args['help'] as bool) {
      print(usage);
      return CommandResult.ok;
    }
    try {
      body(args);
    } on CliExit {
      rethrow;
    } catch (error) {
      // 任何未预期异常都不应以「255 + 栈」结束：统一成错误信封 + 稳定退出码。
      _failUnexpected(args, error);
    }
    return CommandResult.ok;
  } on CliExit catch (e) {
    return CommandResult(e.code);
  }
}

/// 参数解析失败前就要判断要不要 JSON 错误；`--format json` 与 `--format=json` 都算。
bool _wantsJson(List<String> argv) {
  for (var i = 0; i < argv.length; i++) {
    final arg = argv[i];
    if (arg == '--json' || arg == '--format=json') return true;
    if (arg == '--format' && i + 1 < argv.length && argv[i + 1] == 'json') return true;
  }
  return false;
}

/// 把未捕获异常映射成 CLI 错误：配置/文件问题 2，外部工具/未知问题 3。
Never _failUnexpected(ArgResults args, Object error) {
  final (message, code) = switch (error) {
    ProcessException e => ('外部命令不可用：${e.message}', 3),
    FileSystemException e => ('文件操作失败：${e.path ?? ''}', 2),
    YamlException e => ('YAML 解析失败：${e.message}', 2),
    TypeError() => ('配置类型错误：$error', 2),
    _ => ('内部错误：$error', 3),
  };
  failCli(args, message, code: code);
}

/// 命令体统一的失败出口：`--json` 时输出 JSON，而不是只写 stderr。
Never failCli(ArgResults args, String message, {int code = 2}) {
  final json =
      (args.options.contains('json') && args['json'] == true) ||
      (args.options.contains('format') && args['format'] == 'json');
  if (json) {
    stdout.writeln(
      jsonEncode({
        'schema': 'w_tools_cli.error/1',
        'ok': false,
        'error': message,
      }),
    );
  } else {
    stderr.writeln(message);
  }
  throw CliExit(code);
}

/// 统一的机器输出格式：`--json` 是 `--format=json` 的别名。
String outputFormat(ArgResults args, {String fallback = 'text'}) {
  if (args.options.contains('json') && args['json'] == true) return 'json';
  return (args['format'] as String?) ?? fallback;
}

/// 一个子命令的声明：usage + parser + body，入口只负责选择命令。
///
/// 保留 [runCli] 作为执行器；后续可让 body 返回退出码、在进程内组合命令。
class Command {
  const Command({
    required this.usage,
    required this.parser,
    required this.body,
  });

  final String usage;
  final ArgParser parser;
  final void Function(ArgResults) body;

  CommandResult run(List<String> argv) => runCli(argv, usage: usage, parser: parser, body: body);
}
