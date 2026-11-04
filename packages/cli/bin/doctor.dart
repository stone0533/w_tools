// ignore_for_file: avoid_print

import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
import 'package:w_tools_cli/src/common/project_loader.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';
import 'package:w_tools_cli/src/doctor/reporter.dart';
import 'package:w_tools_cli/src/doctor/run.dart';
import 'package:yaml/yaml.dart' show YamlException;

const _usage = '''
w_tools_cli doctor —— 扫描消费方项目是否符合 w_tools 的接入约定

用法：dart run w_tools_cli:doctor [选项]

选项：
  --root=<dir>        项目根目录（默认当前目录）
  --format=<fmt>      输出格式：human | json | markdown（默认 human）
  --json              等价于 --format=json（兼容旧用法）
  --strict            warning 也视为失败（默认关）
  --only=<R1,R2>      只跑指定规则
  --include-tests     同时扫描 test/ 与 tool/
  --print-config      打印带注释的默认配置（可直接粘贴成 .w_tools_doctor.yaml）
  --write-config      把默认配置写到 <root>/.w_tools_doctor.yaml（已存在则跳过）
  --force             配合 --write-config 覆盖已有文件（覆盖前写 .bak）
  --version           显示版本
  --help, -h          显示本帮助

示例：
  dart run w_tools_cli:doctor
  dart run w_tools_cli:doctor --format=markdown
  dart run w_tools_cli:doctor --only=R1,R9 --strict --json
  dart run w_tools_cli:doctor --print-config

说明：
  R9 读取 .w_tools_doctor.yaml 的 banned；未配置时跳过。
''';

/// 已知规则 id；`--only` 里出现未知 id 直接报错，避免 CI 写错后静默通过。
final Set<String> _knownRuleIds = doctorRuleIds.toSet();

CommandResult run(List<String> argv) {
  final parser = cliParser()
    ..addOption('root')
    ..addFlag('json', negatable: false)
    ..addFlag('strict', negatable: false)
    ..addFlag('include-tests', negatable: false)
    ..addOption('only')
    ..addOption('format', defaultsTo: 'human', allowed: <String>['human', 'json', 'markdown'])
    ..addFlag('print-config', negatable: false)
    ..addFlag('write-config', negatable: false)
    ..addFlag('force', negatable: false);

  final result = Command(
    usage: _usage,
    parser: parser,
    body: (args) {
      final root = Directory(args['root'] as String? ?? Directory.current.path);

      // 纯输出操作，不依赖当前目录是不是一个 Dart 项目
      if (args['print-config'] as bool) {
        stdout.write(renderDefaultConfig());
        return;
      }

      if (!File('${root.path}/pubspec.yaml').existsSync()) {
        failCli(args, '找不到 pubspec.yaml：${root.path}（用 --root=<dir> 指定项目根）');
      }

      if (args['write-config'] as bool) {
        final target = File('${root.path}/${DoctorConfig.fileName}');
        final exists = target.existsSync();
        if (exists && !(args['force'] as bool)) {
          failCli(args, '${DoctorConfig.fileName} 已存在（加 --force 覆盖）');
        }
        // 这个文件是项目手工维护的 palette / banned / ignore，覆盖前必须留底。
        if (exists) {
          final backup = File('${target.path}.bak');
          backup.writeAsStringSync(target.readAsStringSync());
          stderr.writeln('已备份原配置到 ${DoctorConfig.fileName}.bak');
        }
        target.writeAsStringSync(renderDefaultConfig());
        print('已写入 ${DoctorConfig.fileName}');
        return;
      }

      Set<String>? only;
      final onlyRaw = args['only'] as String?;
      if (onlyRaw != null) {
        if (onlyRaw.trim().isEmpty) {
          failCli(args, '--only 需要至少一个规则 id（如 --only=R1,R2）');
        }
        only = onlyRaw
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();
        final unknown = only.difference(_knownRuleIds);
        if (unknown.isNotEmpty) {
          failCli(args, '未知规则：${unknown.join(', ')}（可选：${_knownRuleIds.join(', ')}）');
        }
      }

      DoctorConfig config;
      try {
        config = ProjectFiles.loadConfig(root);
      } on ProjectLoadException catch (e) {
        failCli(args, e.message);
      }
      if (only != null) {
        // --only=R6 时也要真的打开 R6，否则它的开关逻辑会把它跳过
        config = config.copyWith(enabledRules: only);
      }

      ProjectContext ctx;
      try {
        ctx = ProjectContext.load(root, config, includeTests: args['include-tests'] as bool);
      } on YamlException catch (e) {
        failCli(args, 'pubspec.yaml 解析失败：${e.message}');
      }

      final results = runDoctor(ctx, config, only: only);
      final reporter = DoctorReporter(
        projectName: ctx.name,
        fileCount: ctx.files.length,
        strict: args['strict'] as bool,
      );
      final format = outputFormat(args, fallback: 'human');
      switch (format) {
        case 'json':
          reporter.printJson(results);
        case 'markdown':
          reporter.printMarkdown(results);
        default:
          reporter.printHuman(results);
      }
      throw CliExit(reporter.exitCode(results));
    },
  ).run(argv);
  return result;
}

void main(List<String> argv) {
  exitCode = run(argv).exitCode;
}
