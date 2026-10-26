// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/common/cli.dart';

const _usage = '''
w_tools_cli explain —— 查看某个组件的用途、反例、import 与文档

用法：dart run w_tools_cli:explain <组件名>

示例：
  dart run w_tools_cli:explain WImage
  dart run w_tools_cli:explain WFormDropdown

选项：
  --format=<fmt>  text | json（默认 text）
  --json          等价于 --format=json
  --version       显示版本
  --help, -h      显示本帮助
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json'])
    ..addFlag('json', negatable: false);

  runCli(
    argv,
    usage: _usage,
    parser: parser,
    body: (args) {
      final name = args.rest.join(' ').trim();
      if (name.isEmpty) {
        stderr.writeln('用法：dart run w_tools_cli:explain <组件名>\n');
        stderr.writeln(_usage);
        exit(2);
      }

      final exact = findComponent(name);
      final matches = exact != null ? <CatalogEntry>[exact] : searchComponents(name);
      final asJson = (args['json'] as bool) || args['format'] == 'json';

      if (asJson) {
        print(
          jsonEncode(<String, Object?>{
            'query': name,
            'found': matches.isNotEmpty,
            'components': matches.map((e) => e.toJson()).toList(),
          }),
        );
        if (matches.isEmpty) exit(1);
        return;
      }

      if (matches.isEmpty) {
        print('没有找到 `$name`。试试 `dart run w_tools_cli:list $name`。');
        exit(1);
      }
      if (matches.length > 1) {
        print('匹配到多个，缩小关键词：');
        for (final e in matches) {
          print('  ${e.name}  [${e.package}]');
        }
        return;
      }

      final e = matches.single;
      print('${e.name}  (${e.package})');
      print('分组：${e.section}');
      print('用途：${e.useFor}');
      if (e.dontUseFor != null) print('不要用于：${e.dontUseFor}');
      print("import '${e.importPath}';");
      print('文档：${e.docs}');
    },
  );
}
