// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/doctor/banned_rule.dart';

const _usage = '''
w_tools_cli explain —— 查看某个组件的用途、反例、import 与文档

用法：dart run w_tools_cli:explain <组件名>

示例：
  dart run w_tools_cli:explain WImage
  dart run w_tools_cli:explain WFormDropdown

说明：
  项目 .w_tools_doctor.yaml 配置 banned 时，会提示禁用项、替代方案与原因。

选项：
  --root=<dir>    项目根目录（读取 .w_tools_doctor.yaml；默认当前目录）
  --format=<fmt>  text | json（默认 text）
  --json          等价于 --format=json
  --version       显示版本
  --help, -h      显示本帮助
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
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

      final root = Directory(args['root'] as String? ?? Directory.current.path);
      final exact = findComponent(name);
      final matches = exact != null ? <CatalogEntry>[exact] : searchComponents(name);
      List<BannedRule> banned;
      try {
        banned = _matchingBanned(name, root);
      } on ProjectLoadException catch (e) {
        stderr.writeln(e.message);
        exit(2);
      }
      final asJson = (args['json'] as bool) || args['format'] == 'json';

      if (asJson) {
        print(
          jsonEncode(<String, Object?>{
            'query': name,
            'found': matches.isNotEmpty,
            'components': matches.map((e) => e.toJson()).toList(),
            'banned': banned.map(_bannedJson).toList(),
          }),
        );
        if (matches.isEmpty && banned.isEmpty) exit(1);
        return;
      }

      if (matches.isEmpty) {
        if (banned.isEmpty) {
          print('没有找到 `$name`。试试 `dart run w_tools_cli:list $name`。');
          exit(1);
        }
        print('`$name` 不在组件目录中，但命中本项目禁用项：');
        for (final entry in banned) {
          print(_bannedText(entry));
        }
        return;
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
      for (final entry in banned) {
        print(_bannedText(entry));
      }
    },
  );
}

List<BannedRule> _matchingBanned(String query, Directory root) {
  final config = ProjectFiles.loadConfig(root);
  return config.banned.where((entry) => entry.validate() == null && entry.matches(query)).toList();
}

String _bannedText(BannedRule entry) {
  final lines = <String>['本项目禁用：${entry.id}'];
  if (entry.use != null && entry.use!.trim().isNotEmpty) {
    lines.add('  改用：${entry.use}');
  }
  if (entry.reason != null && entry.reason!.trim().isNotEmpty) {
    lines.add('  原因：${entry.reason}');
  }
  return lines.join('\n');
}

Map<String, Object?> _bannedJson(BannedRule entry) => <String, Object?>{
  'id': entry.id,
  'use': entry.use,
  'reason': entry.reason,
};
