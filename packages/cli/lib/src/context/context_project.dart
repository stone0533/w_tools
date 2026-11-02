import 'dart:io';

import '../catalog/catalog.dart';
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
    required this.stagingDir,
    required this.designSystemFiles,
    required this.missingStaged,
    required this.isFlutter,
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

  final String stagingDir;
  final int designSystemFiles;
  final int missingStaged;

  /// 项目是否直接依赖 Flutter SDK；决定 analyze / test 命令。
  final bool isFlutter;

  final List<DoctorRuleResult> results;

  int get errorCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.error).length;

  int get warnCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.warn).length;

  static ProjectSnapshot load(Directory root, {DoctorConfig? config}) {
    final cfg = config ?? DoctorConfig.load(root);
    final ctx = ProjectContext.load(root, cfg);
    final facts = ctx.facts;

    return ProjectSnapshot(
      root: root,
      projectName: ctx.name,
      packages: facts.packages,
      dependencies: facts.dependencies,
      toolkitPath: facts.toolkitPath,
      toolkitExports: facts.toolkitExports,
      stagingDir: designSystemDirPath,
      designSystemFiles: facts.stagingFiles.length,
      missingStaged: facts.missingStagedFiles.length,
      isFlutter: facts.isFlutter,
      results: runDoctor(ctx, cfg),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'cliVersion': cliVersion,
    'catalogVersion': catalogVersion,
    'project': <String, Object?>{
      'name': projectName,
      'root': root.path,
      'isFlutter': isFlutter,
    },
    'packages': packages,
    'dependencies': dependencies,
    'toolkit': <String, Object?>{
      'path': toolkitPath,
      'exports': toolkitExports,
    },
    'designSystem': <String, Object?>{
      'dir': stagingDir,
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
    'analyze': isFlutter ? 'flutter analyze' : 'dart analyze',
    'test': isFlutter ? 'flutter test' : 'dart test',
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
      ..writeln(
        '- 暂存层：`$stagingDir`（$designSystemFiles 个文件，$missingStaged 个缺 `// STAGED:`）',
      )
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
      '暂存层: $stagingDir（$designSystemFiles 个文件，$missingStaged 个缺 STAGED）',
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
