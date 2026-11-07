import 'dart:convert';
import 'dart:io';
// ignore_for_file: avoid_print

import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/common/cli.dart';

const _usage = '''
w_tools_cli list —— 按关键词查组件目录

用法：dart run w_tools_cli:w_tools list [关键词]

示例：
  dart run w_tools_cli:w_tools list          # 列出全部
  dart run w_tools_cli:w_tools list 下拉
  dart run w_tools_cli:w_tools list WImage

选项：
  --package=<pkg> 只列该包，可写 w_tools_ui 或 ui
  --format=<fmt>  text | json | prompt（默认 text）
  --json          等价于 --format=json
  --version       显示版本
  --help, -h      显示本帮助
''';

CommandResult run(List<String> argv) {
  final parser = cliParser()
    ..addOption('package')
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json', 'prompt'])
    ..addFlag('json', negatable: false);

  final result = Command(
    usage: _usage,
    parser: parser,
    body: (args) {
      final query = args.rest.join(' ').trim();
      final packageOpt = args['package'] as String?;
      final package = packageOpt != null ? _normalizePackage(packageOpt) : _packageFromQuery(query);
      final results = package != null
          ? catalog.where((entry) => entry.package == package).toList()
          : searchComponents(query);
      final label = package != null ? 'package=$package' : 'query=${query.isEmpty ? '*' : query}';
      final asJson = (args['json'] as bool) || args['format'] == 'json';
      final asPrompt = args['format'] == 'prompt';

      if (asJson) {
        print(
          jsonEncode(<String, Object?>{
            'schema': 'w_tools_cli.list/1',
            'schemaVersion': 1,
            'query': query,
            'package': package,
            'count': results.length,
            'components': results.map((e) => e.toJson()).toList(),
          }),
        );
        if (results.isEmpty) throw CliExit(1);
        return;
      }

      if (asPrompt) {
        print('# w_tools catalog v$catalogVersion · $label');
        for (final entry in results) {
          print('- ${entry.name} [${entry.package}]: ${entry.useFor}');
          if (entry.usage != null) {
            print('  ${entry.usage!.split('\n').first}');
          }
        }
        if (results.isEmpty) throw CliExit(1);
        return;
      }

      print('w_tools_cli list · catalog v$catalogVersion · $label · ${results.length} 个结果');
      if (results.isEmpty) {
        if (package != null && _toolPackages.contains(package)) {
          final name = package.substring('w_tools_'.length);
          print('工具包不在组件目录里：看 docs/agents/$name.md 与 packages/$name/README.md。');
        } else {
          print('没有匹配。换个关键词，或运行 `dart run w_tools_cli:w_tools list` 看全部。');
        }
        throw CliExit(1);
      }
      for (final entry in results) {
        print('${entry.name}  [${entry.package}]  ${entry.useFor}');
      }
      print('');
      print('用 `dart run w_tools_cli:w_tools explain <组件名>` 看用法和反例。');
    },
  ).run(argv);
  return result;
}

void main(List<String> argv) {
  exitCode = run(argv).exitCode;
}

/// 工具包没有 catalog 条目（教学在 docs/agents 与 README），空结果时给专门提示。
const _toolPackages = <String>{
  'w_tools_cli',
  'w_tools_figma',
  'w_tools_device',
  'w_tools_e2e',
};

String _normalizePackage(String value) {
  final v = value.trim();
  return v.startsWith('w_tools_') ? v : 'w_tools_$v';
}

/// 位置参数是包名时按包过滤（`list ui` / `list form`），否则按关键词搜索。
String? _packageFromQuery(String query) {
  if (query.isEmpty || query.contains(' ')) return null;
  final normalized = _normalizePackage(query);
  return catalog.any((entry) => entry.package == normalized) ? normalized : null;
}
