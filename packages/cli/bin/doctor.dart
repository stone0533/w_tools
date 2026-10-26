// ignore_for_file: avoid_print

import 'dart:io';

import 'package:w_tools_cli/src/common/cli.dart';
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
  --force             配合 --write-config 覆盖已有文件
  --version           显示版本
  --help, -h          显示本帮助
''';

/// 已知规则 id；`--only` 里出现未知 id 直接报错，避免 CI 写错后静默通过。
final Set<String> _knownRuleIds = doctorRuleIds.toSet();

void main(List<String> argv) {
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

  runCli(
    argv,
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
        only = onlyRaw
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();
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

      final results = runDoctor(ctx, config, only: only);
      final reporter = DoctorReporter(
        projectName: ctx.name,
        fileCount: ctx.files.length,
        strict: args['strict'] as bool,
      );
      final format = (args['json'] as bool) ? 'json' : (args['format'] as String);
      switch (format) {
        case 'json':
          reporter.printJson(results);
        case 'markdown':
          reporter.printMarkdown(results);
        default:
          reporter.printHuman(results);
      }
      exit(reporter.exitCode(results));
    },
  );
}
