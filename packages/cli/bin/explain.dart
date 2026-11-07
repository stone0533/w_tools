// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/catalog/catalog.dart';
import 'package:w_tools_cli/src/explain/render_explain.dart';
import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/common/pubspec_lock.dart';
import 'package:w_tools_cli/src/doctor/banned_rule.dart';

const _usage = '''
w_tools_cli explain —— 查看某个组件的用途、反例、import 与文档

用法：dart run w_tools_cli:w_tools explain <组件名>

示例：
  dart run w_tools_cli:w_tools explain WImage
  dart run w_tools_cli:w_tools explain WFormDropdown

说明：
  项目 .w_tools_doctor.yaml 配置 banned 时，会提示禁用项、替代方案与原因。

选项：
  --root=<dir>    项目根目录（读取 .w_tools_doctor.yaml；默认当前目录）
  --format=<fmt>  text | json | prompt（默认 text）
  --json          等价于 --format=json
  --version       显示版本
  --help, -h      显示本帮助
''';

CommandResult run(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json', 'prompt'])
    ..addFlag('json', negatable: false);

  final result = Command(
    usage: _usage,
    parser: parser,
    body: (args) {
      final name = args.rest.join(' ').trim();
      if (name.isEmpty) {
        if (outputFormat(args) == 'json') {
          failCli(args, '用法：dart run w_tools_cli:w_tools explain <组件名>');
        }
        stderr.writeln('用法：dart run w_tools_cli:w_tools explain <组件名>\n');
        stderr.writeln(_usage);
        throw CliExit(2);
      }

      final root = Directory(args['root'] as String? ?? Directory.current.path);
      // 已安装版本用于标注 API 文档；解析失败不阻塞 explain。
      var lockedVersions = const <String, String>{};
      try {
        lockedVersions = readLockedVersions(root);
      } on PubspecLockException catch (e) {
        stderr.writeln('${e.message}（explain 继续，但无法标注包版本）');
      }
      // 聚合入口只在“真实消费方项目”里生成；仓库自身/无 pubspec 时退回 catalog import
      String? aggregateImport;
      try {
        final project = ProjectFiles.loadProject(root);
        if (File('${root.path}/${project.toolkitEntry}').existsSync()) {
          aggregateImport = project.packageImport;
        }
      } on ProjectLoadException {
        // explain 不应因为当前目录不是 Dart 项目而失败
      }
      final exact = findComponent(name);
      final matches = exact != null ? <CatalogEntry>[exact] : searchComponents(name);
      List<BannedRule> banned;
      try {
        banned = _matchingBanned(name, root);
      } on ProjectLoadException catch (e) {
        failCli(args, e.message);
      }
      final asJson = (args['json'] as bool) || args['format'] == 'json';
      final asPrompt = args['format'] == 'prompt';

      if (asJson) {
        print(
          jsonEncode(<String, Object?>{
            'schema': 'w_tools_cli.explain/1',
            'schemaVersion': 1,
            'query': name,
            'found': matches.length == 1,
            'ambiguous': matches.length > 1,
            'import': aggregateImport,
            'packageVersion': matches.length == 1 ? lockedVersions[matches.single.package] : null,
            'docsUrl': matches.length == 1 ? docsUrlFor(matches.single) : null,
            'apiDocsUrl': matches.length == 1
                ? apiDocsUrlFor(matches.single, lockedVersions[matches.single.package])
                : null,
            'components': matches.map((e) => e.toJson()).toList(),
            'banned': banned.map(_bannedJson).toList(),
          }),
        );
        if (matches.length > 1) throw CliExit(1);
        if (matches.isEmpty && banned.isEmpty) throw CliExit(1);
        return;
      }

      if (matches.isEmpty) {
        if (banned.isEmpty) {
          print('没有找到 `$name`。试试 `dart run w_tools_cli:w_tools list $name`。');
          throw CliExit(1);
        }
        print('`$name` 不在组件目录中，但命中本项目禁用项：');
        for (final entry in banned) {
          print(_bannedText(entry));
        }
        return;
      }
      if (matches.length > 1) {
        print(asPrompt ? '匹配到多个，请缩小关键词：' : '匹配到多个，缩小关键词：');
        for (final e in matches) {
          print('  ${e.name}  [${e.package}]');
        }
        throw CliExit(1);
      }

      final e = matches.single;
      final packageVersion = lockedVersions[e.package];
      if (asPrompt) {
        print(
          renderExplainPrompt(
            e,
            importPath: aggregateImport ?? e.importPath,
            docsUrl: docsUrlFor(e),
            exampleUrl: exampleUrl(e.package),
            packageVersion: packageVersion,
            apiDocsUrl: apiDocsUrlFor(e, packageVersion),
          ),
        );
        for (final entry in banned) {
          print(_bannedText(entry));
        }
        return;
      }
      print('${e.name}  (${e.package})');
      if (packageVersion != null) print('包版本：${e.package} $packageVersion');
      print('分组：${e.section}');
      print('用途：${e.useFor}');
      if (e.dontUseFor != null) print('不要用于：${e.dontUseFor}');
      if (e.usage != null) {
        print('用法：');
        print(e.usage);
      }
      if (e.pitfalls.isNotEmpty) {
        print('注意：');
        for (final pitfall in e.pitfalls) {
          print('  - $pitfall');
        }
      }
      if (e.related.isNotEmpty) print('相关：${e.related.join(' / ')}');
      if (aggregateImport != null) {
        print("import '$aggregateImport';");
        print('说明：业务代码统一走聚合入口；子包 import 仅限 lib/app/ui、lib/app/design_system、toolkit 内。');
      } else {
        print("import '${e.importPath}';");
      }
      final example = exampleUrl(e.package);
      if (example != null) print('示例：$example');
      print('文档：${docsUrlFor(e)}');
      final apiDocs = apiDocsUrlFor(e, packageVersion);
      if (apiDocs != null) print('API 文档：$apiDocs');
      for (final entry in banned) {
        print(_bannedText(entry));
      }
    },
  ).run(argv);
  return result;
}

void main(List<String> argv) {
  exitCode = run(argv).exitCode;
}

List<BannedRule> _matchingBanned(String query, Directory root) {
  final config = ProjectFiles.loadConfig(root);
  return config.banned.where((entry) => entry.validate() == null && entry.matches(query)).toList();
}

String docsUrlFor(CatalogEntry entry) {
  final base = docsUrl(entry.docs);
  final anchor = entry.docsAnchor;
  if (anchor == null || anchor.trim().isEmpty) return base;
  return '$base#${anchor.trim()}';
}

String docsUrl(String docs) {
  if (docs.startsWith('http://') || docs.startsWith('https://')) return docs;
  // 仓库文档固定在 main：可能领先于消费方已安装版本；版本信息另由 API 文档给出。
  return 'https://github.com/stone0533/w_tools/blob/main/${docs.replaceFirst(RegExp(r'^/'), '')}';
}

String? apiDocsUrlFor(CatalogEntry entry, String? version) {
  if (version == null || version.trim().isEmpty) return null;
  return 'https://pub.dev/documentation/${entry.package}/${version.trim()}/';
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

/// 有 example/ 的包；新增包时在这里补一条。
const _examplePackages = <String, String>{
  'w_tools_ui': 'packages/ui/example',
  'w_tools_form': 'packages/form/example',
  'w_tools_async': 'packages/async/example',
  'w_tools_core': 'packages/core/example',
  'w_tools_api': 'packages/api/example',
  'w_tools_toast': 'packages/toast/example',
  'w_tools_qr': 'packages/qr/example',
  'w_tools_map_google': 'packages/map_google/example',
  'w_tools_app_getx': 'packages/app_getx/example',
  'w_tools_cli': 'packages/cli/example',
  'w_tools_device': 'packages/device/example',
  'w_tools_figma': 'packages/figma/example',
  'w_tools_e2e': 'packages/e2e/example',
};

String? exampleUrl(String package) {
  final path = _examplePackages[package];
  if (path == null) return null;
  return 'https://github.com/stone0533/w_tools/tree/main/$path';
}
