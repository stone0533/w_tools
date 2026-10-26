// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/context/context_project.dart';
import 'package:yaml/yaml.dart' show YamlException;

const _usage = '''
w_tools_cli context —— 输出项目事实（给 AI / CI 的一份稳定上下文）

用法：dart run w_tools_cli:context [选项]

选项：
  --root=<dir>        项目根目录（默认当前目录）
  --format=<fmt>      json | markdown | prompt（默认 markdown）
  --max-tokens=<n>    prompt 格式的近似 token 上限（0 = 不截断）
  --version           显示版本
  --help, -h          显示本帮助

示例：
  dart run w_tools_cli:context --format=prompt
  dart run w_tools_cli:context --format=json
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('format', defaultsTo: 'markdown', allowed: <String>['json', 'markdown', 'prompt'])
    ..addOption('max-tokens', defaultsTo: '0');

  runCli(
    argv,
    usage: _usage,
    parser: parser,
    body: (args) {
      final rawMaxTokens = args['max-tokens'] as String;
      final maxTokens = int.tryParse(rawMaxTokens);
      if (maxTokens == null || maxTokens < 0) {
        stderr.writeln('--max-tokens 需要非负整数：$rawMaxTokens');
        exit(2);
      }

      final root = Directory(args['root'] as String? ?? Directory.current.path);
      if (!File('${root.path}/pubspec.yaml').existsSync()) {
        stderr.writeln('找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
        exit(2);
      }

      ProjectSnapshot snapshot;
      try {
        snapshot = ProjectSnapshot.load(root);
      } on YamlException catch (e) {
        stderr.writeln('pubspec 解析失败：${e.message}');
        exit(2);
      }

      switch (args['format'] as String) {
        case 'json':
          print(const JsonEncoder.withIndent('  ').convert(snapshot.toJson()));
        case 'prompt':
          print(snapshot.toPrompt(maxTokens: maxTokens));
        default:
          print(snapshot.toMarkdown());
      }
    },
  );
}
