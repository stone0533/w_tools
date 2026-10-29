// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/init_project.dart';
import 'package:w_tools_cli/src/init/targets.dart';
import 'package:yaml/yaml.dart' show YamlException;

const _usage = '''
w_tools_cli init —— 把 w_tools 的接入约定装进当前项目

用法：dart run w_tools_cli:init [选项]

生成：
  lib/app/w/toolkit.dart            本项目用到的能力清单（聚合入口）
  lib/app/design_system/README.md   通用组件暂存层规则
  lib/app/ui/README.md              项目永久 UI 规范
  lib/app/ui/app_bars.dart          AppBar 默认样式
  lib/app/ui/app_boxes.dart         盒子装饰预设
  lib/app/ui/app_buttons.dart       按钮样式注册表
  lib/app/ui/app_card.dart          重复卡片入口
  lib/app/ui/app_scaffold.dart      标准页面入口
  .w_tools_doctor.yaml              doctor 的可选配置（默认值与内置一致）
  AGENTS.md / CLAUDE.md / ...       w_tools 片段（标记块，重复执行会原地更新）

选项：
  --root=<dir>   项目根目录（默认当前目录）
  --check        只报告缺失、不改文件（CI 用）；内容不同只提示，不算失败
  --check-drift  在 --check 基础上，内容与模板不同也算失败（检查模板是否过期）
  --json         输出机器可读结果（CI / AI 用）
  --force        覆盖已存在的不同文件（默认不动）
  --profile=<p>  minimal | ui | api | full（默认 full）
  --no-qr        不导出 w_tools_qr（--profile=full 时默认导出）
  --with-map     导出 w_tools_map（会引入 google_maps_flutter）
  --no-ui        不生成 lib/app/ui 与 design_system 规范，也不导出 w_tools_ui
  --targets=<l>  指令文件目标，逗号分隔：agents,claude,cursor,copilot（默认取配置 / agents）
  --lang=<l>     zh | en（默认取配置 / zh）
  --version      显示版本
  --help, -h     显示本帮助
''';

void main(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addFlag('check', negatable: false)
    ..addFlag('check-drift', negatable: false)
    ..addFlag('json', negatable: false)
    ..addFlag('force', negatable: false)
    ..addOption(
      'profile',
      defaultsTo: 'full',
      allowed: <String>['minimal', 'ui', 'api', 'full'],
    )
    ..addFlag('qr', negatable: true, defaultsTo: true)
    ..addFlag('with-map', negatable: false)
    ..addFlag('ui', negatable: true, defaultsTo: true)
    ..addOption('targets')
    ..addOption('lang');

  runCli(
    argv,
    usage: _usage,
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

      final targetsRaw = args['targets'] as String?;
      final targets = targetsRaw == null || targetsRaw.trim().isEmpty
          ? config.aiTargets.toSet()
          : targetsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
      final unknown = targets.difference(targetFiles.keys.toSet());
      if (unknown.isNotEmpty) {
        stderr.writeln('未知 targets：${unknown.join(', ')}（可选：${targetFiles.keys.join(', ')}）');
        exit(2);
      }

      final lang = (args['lang'] as String?) ?? config.aiLanguage;
      if (lang != 'zh' && lang != 'en') {
        stderr.writeln('未知语言：$lang（可选：zh, en）');
        exit(2);
      }

      final checkDrift = args['check-drift'] as bool;
      final check = (args['check'] as bool) || checkDrift;
      final profile = InitProfile.values.firstWhere(
        (p) => p.name == args['profile'],
      );
      var features = InitFeatures.forProfile(profile);
      if (args.wasParsed('ui')) {
        features = features.copyWith(ui: args['ui'] as bool);
      }
      if (args.wasParsed('qr')) {
        features = features.copyWith(qr: args['qr'] as bool);
      }
      if (args['with-map'] as bool) {
        features = features.copyWith(map: true);
      }
      final report = runInit(
        root,
        force: args['force'] as bool,
        check: check,
        features: features,
        targets: targets,
        lang: lang,
      );

      if (args['json'] as bool) {
        print(
          const JsonEncoder.withIndent('  ').convert(<String, Object?>{
            'root': root.path,
            'check': check,
            'checkDrift': checkDrift,
            'profile': profile.name,
            'features': <String, bool>{
              'core': features.core,
              'app': features.app,
              'form': features.form,
              'ui': features.ui,
              'api': features.api,
              'toast': features.toast,
              'qr': features.qr,
              'map': features.map,
            },
            'created': report.created,
            'upToDate': report.upToDate,
            'drift': report.drift,
            'missing': report.missing,
            'warnings': report.warnings,
            'pubspecSnippet': report.pubspecSnippet,
          }),
        );
      } else {
        print('w_tools_cli init${check ? '（check 模式，不写文件）' : ''} · ${root.path}');
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
