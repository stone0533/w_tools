// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/context/context_project.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/common/pubspec_lock.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:yaml/yaml.dart' show YamlException;

const _usage = '''
w_tools_cli context —— 输出项目事实（给 AI / CI 的一份稳定上下文）

用法：dart run w_tools_cli:w_tools context [选项]

选项：
  --root=<dir>        项目根目录（默认当前目录）
  --format=<fmt>      json | markdown | prompt（默认 markdown）
  --json              等价于 --format=json
  --max-tokens=<n>    prompt 格式的近似 token 上限（0 = 不截断）
  --version           显示版本
  --help, -h          显示本帮助

示例：
  dart run w_tools_cli:w_tools context --format=prompt
  dart run w_tools_cli:w_tools context --format=json
''';

CommandResult run(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('format', defaultsTo: 'markdown', allowed: <String>['json', 'markdown', 'prompt'])
    ..addFlag('json', negatable: false)
    ..addOption('max-tokens', defaultsTo: '0');

  final result = Command(
    usage: _usage,
    parser: parser,
    body: (args) {
      final rawMaxTokens = args['max-tokens'] as String;
      final maxTokens = int.tryParse(rawMaxTokens);
      if (maxTokens == null || maxTokens < 0) {
        failCli(args, '--max-tokens 需要非负整数：$rawMaxTokens');
      }

      final root = Directory(args['root'] as String? ?? Directory.current.path);
      if (!File('${root.path}/pubspec.yaml').existsSync()) {
        failCli(args, '找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
      }

      DoctorConfig config;
      try {
        config = ProjectFiles.loadConfig(root);
      } on ProjectLoadException catch (e) {
        failCli(args, e.message);
      }

      ProjectSnapshot snapshot;
      try {
        snapshot = ProjectSnapshot.load(root, config: config);
      } on PubspecLockException catch (e) {
        failCli(args, e.message);
      } on YamlException catch (e) {
        failCli(args, 'pubspec.yaml 解析失败：${e.message}');
      }

      switch (outputFormat(args, fallback: 'markdown')) {
        case 'json':
          print(const JsonEncoder.withIndent('  ').convert(snapshot.toJson()));
        case 'prompt':
          print(snapshot.toPrompt(maxTokens: maxTokens));
        default:
          print(snapshot.toMarkdown());
      }
    },
  ).run(argv);
  return result;
}

void main(List<String> argv) {
  exitCode = run(argv).exitCode;
}
