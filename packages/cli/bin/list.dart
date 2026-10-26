// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/common/cli.dart';

const _usage = '''
w_tools_cli list —— 按关键词查组件目录

用法：dart run w_tools_cli:list [关键词]

示例：
  dart run w_tools_cli:list 下拉
  dart run w_tools_cli:list WImage

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
      final query = args.rest.join(' ').trim();
      final results = searchComponents(query);
      final asJson = (args['json'] as bool) || args['format'] == 'json';

      if (asJson) {
        print(
          jsonEncode(<String, Object?>{
            'query': query,
            'count': results.length,
            'components': results.map((e) => e.toJson()).toList(),
          }),
        );
        return;
      }

      print('w_tools_cli list · catalog v$catalogVersion · ${results.length} 个结果');
      if (results.isEmpty) {
        print('没有匹配。换个关键词，或运行 `dart run w_tools_cli:list` 看全部。');
        return;
      }
      for (final entry in results) {
        print('${entry.name}  [${entry.package}]  ${entry.useFor}');
      }
      print('');
      print('用 `dart run w_tools_cli:explain <组件名>` 看用法和反例。');
    },
  );
}
