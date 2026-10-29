import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../catalog/catalog.dart';
import '../common/pubspec_lock.dart';
import '../common/version.dart';
import '../doctor/config.dart';
import '../doctor/context.dart';
import '../doctor/rule.dart';
import '../doctor/run.dart';

/// 项目事实快照：给 AI / CI 一份稳定的上下文。
class ProjectSnapshot {
  ProjectSnapshot({
    required this.root,
    required this.projectName,
    required this.packages,
    required this.dependencies,
    required this.toolkitPath,
    required this.toolkitExports,
    required this.designSystemDir,
    required this.designSystemFiles,
    required this.missingStaged,
    required this.results,
  });

  final Directory root;
  final String projectName;

  /// `pubspec.lock` 里解析出的 w_tools_* 版本
  final Map<String, String> packages;

  /// pubspec 里直接依赖的 w_tools_* 子包
  final List<String> dependencies;

  final String? toolkitPath;
  final List<String> toolkitExports;

  final String designSystemDir;
  final int designSystemFiles;
  final int missingStaged;

  final List<DoctorRuleResult> results;

  int get errorCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.error).length;

  int get warnCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.warn).length;

  static ProjectSnapshot load(Directory root) {
    final config = DoctorConfig.load(root);
    final ctx = ProjectContext.load(root, config);

    final locked = readLockedVersions(root);
    final packages = <String, String>{
      for (final e in locked.entries)
        if (e.key.startsWith('w_tools')) e.key: e.value,
    };

    final deps = <String>[];
    final depsNode = ctx.pubspec['dependencies'];
    if (depsNode is YamlMap) {
      deps.addAll(
        depsNode.keys.map((e) => '$e').where((e) => e.startsWith('w_tools')).toList(),
      );
    }
    deps.sort();

    String? toolkitPath;
    var exports = <String>[];
    final toolkitFile = File(p.join(root.path, config.toolkitEntry));
    if (toolkitFile.existsSync()) {
      toolkitPath = config.toolkitEntry;
      final pattern = RegExp(r"""export\s+'package:(w_tools_[a-z]+)/""");
      exports =
          pattern
              .allMatches(toolkitFile.readAsStringSync())
              .map((m) => m.group(1)!)
              .toSet()
              .toList()
            ..sort();
    }

    final designFiles = ctx.filesUnder(config.designSystemDir).toList();
    var missingStaged = 0;
    for (final file in designFiles) {
      if (!file.endsWith('.dart')) continue;
      final head = ctx.read(file).split('\n').take(10).join('\n');
      if (!head.contains('// STAGED:')) missingStaged++;
    }

    return ProjectSnapshot(
      root: root,
      projectName: ctx.name,
      packages: packages,
      dependencies: deps,
      toolkitPath: toolkitPath,
      toolkitExports: exports,
      designSystemDir: config.designSystemDir,
      designSystemFiles: designFiles.length,
      missingStaged: missingStaged,
      results: runDoctor(ctx, config),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'cliVersion': cliVersion,
    'catalogVersion': catalogVersion,
    'project': <String, Object?>{
      'name': projectName,
      'root': root.path,
    },
    'packages': packages,
    'dependencies': dependencies,
    'toolkit': <String, Object?>{
      'path': toolkitPath,
      'exports': toolkitExports,
    },
    'designSystem': <String, Object?>{
      'dir': designSystemDir,
      'files': designSystemFiles,
      'missingStaged': missingStaged,
    },
    'rules': <Map<String, Object?>>[
      for (final id in doctorRuleIds) <String, Object?>{'id': id, 'level': doctorRuleLevels[id]},
    ],
    'doctor': <String, Object?>{
      'error': errorCount,
      'warn': warnCount,
      'issues': <Map<String, Object?>>[
        for (final r in results)
          for (final i in r.issues)
            <String, Object?>{
              'rule': i.rule,
              'level': i.level.name,
              'file': i.file,
              'line': i.line,
              'message': i.message,
              'hint': i.hint,
            },
      ],
    },
    'commands': commands(),
  };

  Map<String, String> commands() => <String, String>{
    'context': 'dart run w_tools_cli:context --format=json',
    'doctor': 'dart run w_tools_cli:doctor --json',
    'initCheck': 'dart run w_tools_cli:init --check-drift',
    'analyze': 'flutter analyze',
    'test': 'flutter test',
  };

  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('# w_tools 项目上下文')
      ..writeln()
      ..writeln('- 项目：`$projectName`')
      ..writeln('- w_tools_cli：`$cliVersion`（catalog v$catalogVersion）')
      ..writeln('- 已安装：${_installed()}')
      ..writeln(
        '- 直接依赖：${dependencies.isEmpty ? '（无）' : dependencies.map((e) => '`$e`').join('、')}',
      )
      ..writeln(
        '- toolkit：${toolkitPath ?? '（未初始化）'}'
        '${toolkitExports.isEmpty ? '' : '，导出 ${toolkitExports.map((e) => '`$e`').join('、')}'}',
      )
      ..writeln('- 暂存层：`$designSystemDir`（$designSystemFiles 个文件，$missingStaged 个缺 `// STAGED:`）')
      ..writeln('- 规则：${doctorRuleIds.map((id) => '`$id ${doctorRuleLevels[id]}`').join(' ')}')
      ..writeln('- 当前检查：$errorCount error / $warnCount warning')
      ..writeln()
      ..writeln('## 命令')
      ..writeln()
      ..writeln('```bash');
    commands().forEach((k, v) => b.writeln('# $k\n$v'));
    b
      ..writeln('```')
      ..writeln()
      ..writeln('## 组件目录')
      ..writeln()
      ..writeln(
        '$catalogVersion 版共 ${catalog.length} 条；用 `dart run w_tools_cli:list <关键词>` 或 '
        '`dart run w_tools_cli:explain <组件名>` 查询。',
      );
    return b.toString();
  }

  String toPrompt({int maxTokens = 0}) {
    final lines = <String>[
      '# w_tools 项目上下文（给 AI）',
      '项目: $projectName',
      'w_tools_cli: $cliVersion / catalog v$catalogVersion',
      '已装: ${_installed()}',
      '直接依赖: ${dependencies.isEmpty ? '（无）' : dependencies.join(', ')}',
      'toolkit: ${toolkitPath ?? '（未初始化）'}'
          '${toolkitExports.isEmpty ? '' : '（导出 ${toolkitExports.join(', ')}）'}',
      '暂存层: $designSystemDir（$designSystemFiles 个文件，$missingStaged 个缺 STAGED）',
      '规则: ${doctorRuleIds.map((id) => '$id=${doctorRuleLevels[id]}').join(' ')}',
      '当前: $errorCount error / $warnCount warning',
      '命令: ${commands().entries.map((e) => '${e.key}=${e.value}').join(' | ')}',
      '组件: ${catalog.length} 条，用 list/explain 查，不要凭记忆造组件名',
    ];
    if (maxTokens <= 0) return lines.join('\n');
    final budget = maxTokens * 4;
    final out = StringBuffer();
    for (final line in lines) {
      if (out.length + line.length + 1 > budget) break;
      out.writeln(line);
    }
    if (out.length < lines.join('\n').length) out.writeln('…（已截断，完整内容用 --format=json）');
    return out.toString();
  }

  String _installed() {
    if (packages.isEmpty) return '（未解析到 pubspec.lock）';
    final entries = packages.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '`${e.key} ${e.value}`').join('、');
  }
}
