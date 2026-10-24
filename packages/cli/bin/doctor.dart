// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' show YamlException;
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';
import 'package:w_tools_cli/src/doctor/reporter.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';
import 'package:w_tools_cli/src/doctor/rules/r1_meta_dependency.dart';
import 'package:w_tools_cli/src/doctor/rules/r2_direct_subpackage_import.dart';
import 'package:w_tools_cli/src/doctor/rules/r3_hardcoded_colors.dart';
import 'package:w_tools_cli/src/doctor/rules/r4_design_system_boundary.dart';
import 'package:w_tools_cli/src/doctor/rules/r5_staged_marker.dart';
import 'package:w_tools_cli/src/doctor/rules/r6_banned_units.dart';

const _usage = '''
w_tools_cli doctor —— 扫描消费方项目是否符合 w_tools 的接入约定

用法：dart run w_tools_cli:doctor [选项]

选项：
  --root=<dir>        项目根目录（默认当前目录）
  --json              输出 JSON（给 CI 解析）
  --strict            warning 也视为失败（默认关）
  --only=<R1,R2>      只跑指定规则
  --include-tests     同时扫描 test/ 与 tool/
  --print-config      打印带注释的默认配置（可直接粘贴成 .w_tools_doctor.yaml）
  --write-config      把默认配置写到 <root>/.w_tools_doctor.yaml（已存在则跳过）
  --force             配合 --write-config 覆盖已有文件
  --help, -h          显示本帮助
''';

/// 已知规则 id；`--only` 里出现未知 id 直接报错，避免 CI 写错后静默通过。
const _knownRuleIds = <String>{'R1', 'R2', 'R3', 'R4', 'R5', 'R6'};

void main(List<String> argv) {
  final parser = ArgParser()
    ..addOption('root')
    ..addFlag('json', negatable: false)
    ..addFlag('strict', negatable: false)
    ..addFlag('include-tests', negatable: false)
    ..addOption('only')
    ..addFlag('print-config', negatable: false)
    ..addFlag('write-config', negatable: false)
    ..addFlag('force', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln('参数错误：${e.message}\n');
    stderr.writeln(_usage);
    exit(2);
  }

  if (args['help'] as bool) {
    print(_usage);
    return;
  }

  final root = Directory(args['root'] as String? ?? Directory.current.path);

  // 纯输出操作，不依赖当前目录是不是一个 Dart 项目
  if (args['print-config'] as bool) {
    stdout.write(renderDefaultConfig());
    return;
  }

  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
    exit(2);
  }

  if (args['write-config'] as bool) {
    final target = File('${root.path}/${DoctorConfig.fileName}');
    if (target.existsSync() && !(args['force'] as bool)) {
      stderr.writeln('${DoctorConfig.fileName} 已存在（加 --force 覆盖）');
      exit(1);
    }
    target.writeAsStringSync(renderDefaultConfig());
    print('已写入 ${DoctorConfig.fileName}');
    return;
  }

  Set<String>? only;
  final onlyRaw = args['only'] as String?;
  if (onlyRaw != null) {
    if (onlyRaw.trim().isEmpty) {
      stderr.writeln('--only 需要至少一个规则 id（如 --only=R1,R2）');
      exit(2);
    }
    only = onlyRaw.split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toSet();
    final unknown = only.difference(_knownRuleIds);
    if (unknown.isNotEmpty) {
      stderr.writeln('未知规则：${unknown.join(', ')}（可选：${_knownRuleIds.join(', ')}）');
      exit(2);
    }
  }

  DoctorConfig config;
  try {
    config = DoctorConfig.load(root);
  } on YamlException catch (e) {
    stderr.writeln('${DoctorConfig.fileName} 解析失败：${e.message}');
    exit(2);
  }
  if (only != null) {
    // --only=R6 时也要真的打开 R6，否则它的开关逻辑会把它跳过
    config = config.copyWith(enabledRules: only);
  }

  ProjectContext ctx;
  try {
    ctx = ProjectContext.load(root, config, includeTests: args['include-tests'] as bool);
  } on YamlException catch (e) {
    stderr.writeln('pubspec.yaml 解析失败：${e.message}');
    exit(2);
  }

  final checks = <String, DoctorRuleResult Function(ProjectContext, DoctorConfig)>{
    R1MetaDependency.id: R1MetaDependency.check,
    R2DirectSubpackageImport.id: R2DirectSubpackageImport.check,
    R3HardcodedColors.id: R3HardcodedColors.check,
    R4DesignSystemBoundary.id: R4DesignSystemBoundary.check,
    R5StagedMarker.id: R5StagedMarker.check,
    R6BannedUnits.id: R6BannedUnits.check,
  };

  final ids = only ?? checks.keys;
  final results = <DoctorRuleResult>[
    for (final id in ids) checks[id]!(ctx, config),
  ];

  final reporter = DoctorReporter(
    projectName: ctx.name,
    fileCount: ctx.files.length,
    strict: args['strict'] as bool,
  );
  if (args['json'] as bool) {
    reporter.printJson(results);
  } else {
    reporter.printHuman(results);
  }
  exit(reporter.exitCode(results));
}
