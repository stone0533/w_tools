// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:w_tools_cli/src/init/init_project.dart';

const _usage = '''
w_tools_cli init —— 把 w_tools 的接入约定装进当前项目

用法：dart run w_tools_cli:init [选项]

生成：
  lib/app/w/toolkit.dart            本项目用到的能力清单（聚合入口）
  lib/app/design_system/README.md   通用组件暂存层规则
  .w_tools_doctor.yaml              doctor 的可选配置（全注释，不改变行为）
  AGENTS.md                         w_tools 片段（标记块，重复执行会原地更新）

选项：
  --root=<dir>   项目根目录（默认当前目录）
  --check        只报告缺失、不改文件（CI 用）；内容不同只提示，不算失败
  --check-drift  在 --check 基础上，内容与模板不同也算失败（检查模板是否过期）
  --force        覆盖已存在的不同文件（默认不动）
  --no-qr        不导出 w_tools_qr（不用扫码）
  --with-map     导出 w_tools_map（会引入 google_maps_flutter）
  --help, -h     显示本帮助
''';

void main(List<String> argv) {
  final parser = ArgParser()
    ..addOption('root')
    ..addFlag('check', negatable: false)
    ..addFlag('check-drift', negatable: false)
    ..addFlag('force', negatable: false)
    ..addFlag('qr', negatable: true, defaultsTo: true)
    ..addFlag('with-map', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln('参数错误：${e.message}\n$_usage');
    exit(2);
  }

  if (args['help'] as bool) {
    print(_usage);
    return;
  }

  final root = Directory(args['root'] as String? ?? Directory.current.path);
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
    exit(2);
  }

  final checkDrift = args['check-drift'] as bool;
  final check = (args['check'] as bool) || checkDrift;
  final report = runInit(
    root,
    force: args['force'] as bool,
    check: check,
    withQr: args['qr'] as bool,
    withMap: args['with-map'] as bool,
  );

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

  if (check && (report.missing.isNotEmpty || (checkDrift && report.drift.isNotEmpty))) {
    exit(1);
  }
}
