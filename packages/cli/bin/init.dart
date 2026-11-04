// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/version.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/init_options.dart';
import 'package:w_tools_cli/src/init/init_project.dart';
import 'package:yaml/yaml.dart' show YamlException;

const _usage = '''
w_tools_cli init —— 把 w_tools 的接入约定装进当前项目

用法：dart run w_tools_cli:init [选项]

生成：
  lib/app/w/toolkit.dart            本项目用到的能力清单（聚合入口）
  .w_tools_doctor.yaml              doctor 的可选配置（默认值与内置一致）
  AGENTS.md / CLAUDE.md / ...       w_tools 指令片段（标记块，重复执行原地更新）

  以下仅在 ui / full profile 且未传 --no-ui 时生成：
  lib/app/design_system/README.md   通用组件暂存层规则
  lib/app/ui/README.md              项目永久 UI 规范
  lib/app/ui/app_bars.dart          AppBar 默认样式
  lib/app/ui/app_boxes.dart         盒子装饰预设
  lib/app/ui/app_buttons.dart       按钮样式注册表
  lib/app/ui/app_card.dart          重复卡片入口
  lib/app/ui/app_scaffold.dart      标准页面入口

选项：
  --root=<dir>   项目根目录（默认当前目录）
  --check        只报告缺失、不改文件（CI 用）；内容不同只提示，不算失败
  --check-drift  在 --check 基础上，内容与模板不同也算失败（检查模板是否过期）
  --format=<fmt> text | json（默认 text）
  --json         等价于 --format=json
  --force        覆盖生成物 / 配置（配置先 .bak；默认不动）
  --reset        忽略 .w_tools/init.json，按本次参数与默认值重来
  --force-starters 覆盖 UI / device starter（先 .bak）
  --force-ui     等同 --force-starters（兼容别名）
  --profile=<p>  minimal | ui | api | full（默认 full）
                 profile 决定基础能力；--<feature> / --no-<feature> 覆盖单项
                 minimal / api 不生成 lib/app/ui
{{features}}
  --with-map     兼容别名，等同 --map
  --figma / --no-figma  生成 Figma 取数与页面开发说明（默认关，不影响 toolkit）
  --device / --no-device  生成设备验证工具（tool/device_smoke.dart / docs/agents/device-testing.md /
                        tool/gradle-mirror.init.gradle.example；检测到 w_tools_device 时默认开）
  --no-instructions  不生成/不检查 AGENTS 等 AI 指令文件（优先于 --targets）
  --targets=<l>  指令文件目标，逗号分隔：agents,claude,cursor,copilot（默认取配置 / agents）
  --lang=<l>     zh | en（默认取配置 / zh）
  --version      显示版本
  --help, -h     显示本帮助

示例：
  dart run w_tools_cli:init
  dart run w_tools_cli:init --profile=ui
  dart run w_tools_cli:init --targets=agents,claude --lang=en
  dart run w_tools_cli:init --check-drift

说明：
  .w_tools_doctor.yaml 的有效 banned 会生成到 AGENTS 的“本项目禁用 API”段落。
''';

String _buildUsage() {
  final pairs = <String>[
    for (final spec in initFeatureSpecs) '--${spec.flag} / --no-${spec.flag}',
  ];
  final width = pairs.fold<int>(0, (max, value) => value.length > max ? value.length : max);
  final features = <String>[
    for (var i = 0; i < initFeatureSpecs.length; i++)
      '  ${pairs[i].padRight(width)}  ${initFeatureSpecs[i].label}',
  ].join('\n');
  return _usage.replaceAll('{{features}}', features);
}

/// 把内部带中文说明的条目拆成 `{path, note}`，方便 CI/AI 消费。
List<Map<String, String>> _jsonEntries(List<String> items) {
  return [
    for (final item in items)
      if (item.contains('（'))
        <String, String>{
          'path': item.substring(0, item.indexOf('（')),
          'note': item.substring(item.indexOf('（') + 1, item.length - 1),
        }
      else
        <String, String>{'path': item, 'note': ''},
  ];
}

/// 根据本次结果给出可执行的下一步，而不是无条件 doctor。
List<String> _nextActions(InitReport report) {
  final actions = <String>[];
  final needsDeps = !report.pubspecSnippet.trimLeft().startsWith('# 依赖已齐全');
  if (needsDeps && report.pubspecSnippet.trim().isNotEmpty) {
    actions.add('把 pubspecSnippet 的依赖加入 pubspec.yaml，然后运行 dart pub get');
  }
  if (report.missing.isNotEmpty) {
    actions.add('dart run w_tools_cli:init');
  }
  if (report.drift.isNotEmpty) {
    actions.add('dart run w_tools_cli:init --force');
  }
  if (actions.isEmpty) {
    actions.add('dart run w_tools_cli:doctor');
  }
  return actions;
}

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addFlag('check', negatable: false)
    ..addFlag('check-drift', negatable: false)
    ..addOption('format', defaultsTo: 'text', allowed: <String>['text', 'json'])
    ..addFlag('json', negatable: false)
    ..addFlag('force', negatable: false)
    ..addFlag('force-starters', negatable: false)
    ..addFlag('force-ui', negatable: false)
    ..addFlag('reset', negatable: false)
    ..addOption(
      'profile',
      defaultsTo: 'full',
      allowed: <String>['minimal', 'ui', 'api', 'full'],
    )
    ..addFlag('with-map', negatable: false)
    ..addFlag('figma', negatable: true, defaultsTo: false)
    ..addFlag('device', negatable: true, defaultsTo: false)
    ..addFlag('device-test', negatable: false, hide: true, defaultsTo: false)
    ..addFlag('instructions', negatable: true, defaultsTo: true)
    ..addOption('targets')
    ..addOption('lang');
  for (final spec in initFeatureSpecs) {
    parser.addFlag(spec.flag, negatable: true, defaultsTo: false, help: spec.label);
  }

  CliCommand(
    usage: _buildUsage(),
    parser: parser,
    body: (args) {
      final root = Directory(args['root'] as String? ?? Directory.current.path);
      if (!File('${root.path}/pubspec.yaml').existsSync()) {
        stderr.writeln('找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
        exit(2);
      }

      DoctorConfig config;
      try {
        config = DoctorConfig.load(root);
      } on YamlException catch (e) {
        stderr.writeln('.w_tools_doctor.yaml 解析失败：${e.message}');
        exit(2);
      }

      InitOptions options;
      try {
        options = InitOptions.resolve(root: root, args: args, argv: argv, config: config);
      } on InitOptionsException catch (e) {
        stderr.writeln(e.message);
        exit(2);
      }
      final check = options.check;
      final checkDrift = options.checkDrift;
      final sortedTargets = options.targets.toList()..sort();
      final profile = options.profile;
      final features = options.features;
      final lang = options.lang;
      final figmaEnabled = options.figma;
      final deviceEnabled = options.device;

      if (args.wasParsed('device-test')) {
        stderr.writeln(
          '--device-test 已移除；本次按 --device 生成设备工具，不再生成 UI keep-alive 示例。',
        );
      }
      final report = runInit(
        root,
        force: options.force,
        forceStarters: options.forceStarters,
        check: options.check,
        features: options.features,
        targets: options.targets,
        lang: options.lang,
        figma: options.figma,
        figmaInstall: options.figmaInstall,
        device: options.device,
        manifest: options.toManifest(generator: cliVersion),
      );

      if (outputFormat(args) == 'json') {
        print(
          const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'root': root.path,
            'check': check,
            'checkDrift': checkDrift,
            'schema': 'w_tools_cli.init/1',
            'schemaVersion': 1,
            'profile': profile.name,
            'lang': lang,
            'targets': sortedTargets,
            'features': features.toJson(),
            'figma': figmaEnabled,
            'device': deviceEnabled,
            'forceStarters': options.forceStarters,
            'created': _jsonEntries(report.created),
            'upToDate': _jsonEntries(report.upToDate),
            'drift': _jsonEntries(report.drift),
            'stale': _jsonEntries(report.stale),
            'missing': _jsonEntries(report.missing),
            'needsPubspec': !report.pubspecSnippet.trimLeft().startsWith('# 依赖已齐全'),
            'warnings': report.warnings,
            'pubspecSnippet': report.pubspecSnippet,
            'nextActions': _nextActions(report),
          }),
        );
      } else {
        print('w_tools_cli init${check ? '（check 模式，不写文件）' : ''} · ${root.path}');
        print('profile: ${profile.name}');
        print('features: ${features.summary}');
        print('figma: ${figmaEnabled ? 'yes' : 'no'}');
        print('device: ${deviceEnabled ? 'yes' : 'no'}');
        print('targets: ${sortedTargets.isEmpty ? '（无）' : sortedTargets.join(', ')}');
        print('━' * 56);
        for (final f in report.created) {
          print('✓ $f');
        }
        for (final f in report.upToDate) {
          print('· $f（已是最新）');
        }
        for (final f in report.drift) {
          print('! $f');
        }
        for (final f in report.stale) {
          print('! $f');
        }
        for (final f in report.missing) {
          print('- $f（缺失）');
        }
        for (final w in report.warnings) {
          print('! $w');
        }
        if (report.drift.isNotEmpty) {
          print('→ 覆盖上述 drift：dart run w_tools_cli:init --force');
        }
        print('');
        print('需要在 pubspec.yaml 里加入：');
        print(report.pubspecSnippet);

        final nextActions = _nextActions(report);
        for (final action in nextActions) {
          print('下一步：$action');
        }
      }
      if (check && (report.missing.isNotEmpty || (checkDrift && report.drift.isNotEmpty))) {
        exit(1);
      }
    },
  ).run(argv);
}
