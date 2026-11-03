// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/init_project.dart';
import 'package:w_tools_cli/src/init/manifest.dart';
import 'package:w_tools_cli/src/init/targets.dart';
import 'package:yaml/yaml.dart' show YamlException, YamlMap, loadYaml;

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
  --json         输出机器可读结果（CI / AI 用）
  --force        覆盖生成物 / 配置（配置先 .bak；默认不动）
  --force-starters 覆盖 UI / device starter（先 .bak）
  --force-ui     等同 --force-starters（兼容别名）
  --profile=<p>  minimal | ui | api | full（默认 full）
                 profile 决定基础能力；--<feature> / --no-<feature> 覆盖单项
                 minimal / api 不生成 lib/app/ui
{{features}}
  --with-map     兼容别名，等同 --map
  --figma / --no-figma  生成 Figma 取数与页面开发说明（默认关，不影响 toolkit）
  --device / --no-device  生成设备验证脚手架（integration_test 冒烟 / tool/device_smoke.dart /
                        docs/agents/device-testing.md / tool/gradle-mirror.init.gradle；默认关）
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

({bool present, String? constraint}) _figmaDependency(Directory root) {
  final file = File('${root.path}/pubspec.yaml');
  if (!file.existsSync()) return (present: false, constraint: null);
  try {
    final raw = loadYaml(file.readAsStringSync());
    for (final key in const <String>['dependencies', 'dev_dependencies']) {
      final deps = raw is YamlMap ? raw[key] : null;
      if (deps is! YamlMap || !deps.containsKey('w_tools_figma')) continue;
      final value = deps['w_tools_figma'];
      return (present: true, constraint: value is String ? value : null);
    }
  } on YamlException {
    return (present: false, constraint: null);
  }
  return (present: false, constraint: null);
}

String? _figmaInstallLine(Directory root) {
  final dep = _figmaDependency(root);
  if (!dep.present) return null;
  if (dep.constraint == null) return '# w_tools_figma 已通过 path/git 安装';
  return 'dart pub add dev:w_tools_figma:${dep.constraint}';
}

bool _resolveFigma(
  Directory root,
  DoctorConfig config, {
  required bool explicit,
  required bool flag,
}) {
  if (explicit) return flag;
  return switch (config.aiFigma) {
    'true' => true,
    'false' => false,
    _ => _figmaDependency(root).present,
  };
}

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addFlag('check', negatable: false)
    ..addFlag('check-drift', negatable: false)
    ..addFlag('json', negatable: false)
    ..addFlag('force', negatable: false)
    ..addFlag('force-starters', negatable: false)
    ..addFlag('force-ui', negatable: false)
    ..addOption(
      'profile',
      defaultsTo: 'full',
      allowed: <String>['minimal', 'ui', 'api', 'full'],
    )
    ..addFlag('with-map', negatable: false)
    ..addFlag('figma', negatable: true, defaultsTo: false)
    ..addFlag('device', negatable: true, defaultsTo: false)
    ..addFlag('instructions', negatable: true, defaultsTo: true)
    ..addOption('targets')
    ..addOption('lang');
  for (final spec in initFeatureSpecs) {
    parser.addFlag(spec.flag, negatable: true, defaultsTo: false, help: spec.label);
  }

  runCli(
    argv,
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

      final checkDrift = args['check-drift'] as bool;
      final check = (args['check'] as bool) || checkDrift;
      final manifest = check ? InitManifest.load(root) : null;

      final targetsRaw = args['targets'] as String?;
      final targets = args['instructions'] as bool
          ? (targetsRaw != null && targetsRaw.trim().isNotEmpty
                ? targetsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
                : (manifest?.targets.toSet() ?? config.aiTargets.toSet()))
          : <String>{};
      final sortedTargets = targets.toList()..sort();
      final unknown = targets.difference(targetFiles.keys.toSet());
      if (unknown.isNotEmpty) {
        stderr.writeln('未知 targets：${unknown.join(', ')}（可选：${targetFiles.keys.join(', ')}）');
        exit(2);
      }

      final lang = args.wasParsed('lang')
          ? args['lang'] as String
          : (manifest?.lang ?? config.aiLanguage);
      if (lang != 'zh' && lang != 'en') {
        stderr.writeln('未知语言：$lang（可选：zh, en）');
        exit(2);
      }

      final profileName = args.wasParsed('profile')
          ? args['profile'] as String
          : (manifest?.profile ?? args['profile'] as String);
      final profile = InitProfile.values.firstWhere(
        (p) => p.name == profileName,
      );
      for (final spec in initFeatureSpecs) {
        final yes = '--${spec.flag}';
        final no = '--no-${spec.flag}';
        if (argv.contains(yes) && argv.contains(no)) {
          stderr.writeln('$yes 与 $no 不能同时使用');
          exit(2);
        }
      }
      if (argv.contains('--figma') && argv.contains('--no-figma')) {
        stderr.writeln('--figma 与 --no-figma 不能同时使用');
        exit(2);
      }
      if (argv.contains('--device') && argv.contains('--no-device')) {
        stderr.writeln('--device 与 --no-device 不能同时使用');
        exit(2);
      }
      var features = manifest != null && !args.wasParsed('profile')
          ? InitFeatures.fromJson(manifest.profile, manifest.features)
          : InitFeatures.forProfile(profile);
      for (final spec in initFeatureSpecs) {
        if (args.wasParsed(spec.flag)) {
          features = features.withFeature(spec.feature, args[spec.flag] as bool);
        }
      }
      if (args['with-map'] as bool) {
        if (args.wasParsed('map') && args['map'] == false) {
          stderr.writeln('--with-map 与 --no-map 不能同时使用');
          exit(2);
        }
        features = features.withFeature(InitFeature.map, true);
      }
      final figmaEnabled = args.wasParsed('figma')
          ? args['figma'] as bool
          : (manifest?.figma ?? _resolveFigma(root, config, explicit: false, flag: false));
      final deviceEnabled = args.wasParsed('device')
          ? args['device'] as bool
          : (manifest?.device ?? false);
      final initManifest = InitManifest(
        profile: profile.name,
        features: features.toJson(),
        targets: sortedTargets,
        lang: lang,
        figma: figmaEnabled,
        device: deviceEnabled,
      );
      final report = runInit(
        root,
        force: args['force'] as bool,
        forceStarters: (args['force-starters'] as bool) || (args['force-ui'] as bool),
        check: check,
        features: features,
        targets: targets,
        lang: lang,
        figma: figmaEnabled,
        figmaInstall: _figmaInstallLine(root),
        device: deviceEnabled,
        manifest: initManifest,
      );

      if (args['json'] as bool) {
        print(
          const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'root': root.path,
            'check': check,
            'checkDrift': checkDrift,
            'profile': profile.name,
            'targets': sortedTargets,
            'features': features.toJson(),
            'figma': figmaEnabled,
            'device': deviceEnabled,
            'forceStarters': (args['force-starters'] as bool) || (args['force-ui'] as bool),
            'created': report.created,
            'upToDate': report.upToDate,
            'drift': report.drift,
            'stale': report.stale,
            'missing': report.missing,
            'warnings': report.warnings,
            'pubspecSnippet': report.pubspecSnippet,
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
        print('');
        print('需要在 pubspec.yaml 里加入：');
        print(report.pubspecSnippet);
        print('下一步：dart run w_tools_cli:doctor');
      }
      if (check && (report.missing.isNotEmpty || (checkDrift && report.drift.isNotEmpty))) {
        exit(1);
      }
    },
  );
}
