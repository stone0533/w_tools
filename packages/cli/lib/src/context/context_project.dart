import 'dart:io';

import '../catalog/catalog.dart';
import '../common/version.dart';
import '../doctor/config.dart';
import '../doctor/context.dart';
import '../doctor/rule.dart';
import '../doctor/run.dart';
import 'install_info.dart';

/// context JSON 的契约标识 / 版本。
const String contextSchema = 'w_tools.context';
const int contextSchemaVersion = 1;

/// 项目事实快照：给 AI / CI 一份稳定的上下文。
class ProjectSnapshot {
  const ProjectSnapshot({
    required this.facts,
    required this.results,
    required this.repoCheckout,
  });

  final ProjectFacts facts;
  final List<DoctorRuleResult> results;

  /// 是否是 w_tools 仓库自身（不是消费方项目）。
  /// 仓库根会被 R1 当成“依赖了聚合包”，这些是仓库结构，不是接入问题。
  final bool repoCheckout;

  /// `w_tools_cli` 自身的安装位置（供 AI 判断能否直接写库侧反馈）。
  InstallInfo get install => InstallInfo.detect(projectRoot: root);

  Directory get root => facts.ctx.root;
  String get projectName => facts.ctx.name;
  Map<String, String> get packages => facts.packages;
  List<String> get dependencies => facts.dependencies;
  String? get toolkitPath => facts.toolkitPath;
  List<String> get toolkitExports => facts.toolkitExports;
  String get stagingDir => designSystemDirPath;
  int get designSystemFiles => facts.stagingFiles.length;
  int get missingStaged => facts.missingStagedFiles.length;
  bool get isFlutter => facts.isFlutter;

  int get errorCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.error).length;

  int get warnCount =>
      results.expand((r) => r.issues).where((i) => i.level == DoctorLevel.warn).length;

  static ProjectSnapshot load(Directory root, {DoctorConfig? config}) {
    final cfg = config ?? DoctorConfig.load(root);
    final ctx = ProjectContext.load(root, cfg);
    final facts = ctx.facts;
    // 提前触发 lock 解析，让命令层能在 load 阶段捕获 PubspecLockException。
    facts.packages;
    final repoCheckout =
        ctx.name == 'w_tools' && Directory('${root.path}/packages/cli').existsSync();
    return ProjectSnapshot(
      facts: facts,
      // 仓库自身不跑消费方 doctor：R1 会把根包的聚合依赖误报成接入错误。
      results: repoCheckout ? const <DoctorRuleResult>[] : runDoctor(ctx, cfg),
      repoCheckout: repoCheckout,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': contextSchema,
    'schemaVersion': contextSchemaVersion,
    'cliVersion': cliVersion,
    'repoCheckout': repoCheckout,
    'catalogVersion': catalogVersion,
    'project': <String, Object?>{
      'name': projectName,
      'root': root.path,
      'isFlutter': isFlutter,
    },
    'packages': packages,
    'dependencies': dependencies,
    'capabilities': capabilities(),
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
    'install': install.toJson(),
    'doctor': <String, Object?>{
      'skipped': repoCheckout,
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
              if (i.fix != null) 'fix': i.fix!.toJson(),
            },
      ],
    },
    'commands': commands(),
  };

  /// 已安装 w_tools 能力的轻量摘要；空列表表示没有可识别包。
  ///
  /// 只收录消费入口包（6 个聚合子包 + app_getx / map_google / qr）。
  /// `w_tools_app` / `w_tools_map` 是契约层，分别由 app_getx / map_google 代表；
  /// cli / figma / device / e2e 是工具包，都不单列。
  List<Map<String, String>> capabilities() {
    final installed = <String>{...packages.keys, ...dependencies};
    const summaries = <String, String>{
      'w_tools_core': 'WStorage / WToken / WValidator / WLogger',
      'w_tools_async': 'WAsyncController + WAsyncView；纯执行 WAsync.tryRun/run',
      'w_tools_ui': 'WText / WImage / WButton / WScaffold',
      'w_tools_form': 'WForm + 直接字段（WFormTextField 等）',
      'w_tools_api': 'WApiConfig + DioRegistry + WLogInterceptor',
      'w_tools_toast': 'WToast.showXxx + WToastStyle',
      'w_tools_app_getx': 'WApp + WAppPlugin + GetX 路由',
      'w_tools_map_google': 'WMap + WMapZone',
      'w_tools_qr': 'WQrView / WQrController',
    };
    return [
      for (final entry in summaries.entries)
        if (installed.contains(entry.key))
          <String, String>{'package': entry.key, 'summary': entry.value},
    ];
  }

  Map<String, String> commands() {
    final result = <String, String>{
      'context': 'dart run w_tools_cli:w_tools context --format=json',
      'doctor': 'dart run w_tools_cli:w_tools doctor --json',
      'list': 'dart run w_tools_cli:w_tools list <关键词> --format=prompt',
      'explain': 'dart run w_tools_cli:w_tools explain <组件名> --format=prompt',
      'initCheck': 'dart run w_tools_cli:w_tools init --check-drift',
      'feedbackStatus': 'dart run w_tools_cli:w_tools feedback status',
      'feedbackSubmit':
          'dart run w_tools_cli:w_tools feedback submit --package=<包> --title=<标题> --stdin',
      'feedbackLint': 'dart run w_tools_cli:w_tools feedback lint --include-inbox',
      'analyze': isFlutter ? 'flutter analyze' : 'dart analyze',
      'test': isFlutter ? 'flutter test' : 'dart test',
    };
    if (packages.containsKey('w_tools_device')) {
      result.addAll(<String, String>{
        'deviceList': 'dart run w_tools_device:device list',
        'deviceShot': 'dart run w_tools_device:device shot --out=/tmp/shot.png',
        'deviceForeground': 'dart run w_tools_device:device foreground --android',
      });
    }
    return result;
  }

  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('# w_tools 项目上下文')
      ..writeln()
      ..writeln('- 项目：`$projectName`')
      ..writeln(repoCheckout ? '- 模式：仓库检出（跳过消费方 doctor 规则）' : '- 模式：消费方项目')
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
      ..writeln(
        repoCheckout ? '- 当前检查：已跳过（仓库自身）' : '- 当前检查：$errorCount error / $warnCount warning',
      );
    final caps = capabilities();
    if (caps.isNotEmpty) {
      b
        ..writeln()
        ..writeln('## 能力')
        ..writeln();
      for (final cap in caps) {
        b.writeln('- `${cap['package']}`：${cap['summary']}');
      }
    }
    b
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
        'catalog v$catalogVersion 共 ${catalog.length} 条；用 `dart run w_tools_cli:w_tools list <关键词>` 或 '
        '`dart run w_tools_cli:w_tools explain <组件名>` 查询。',
      );
    return b.toString();
  }

  String toPrompt({int maxTokens = 0}) {
    // 优先级：标题/项目/入口/检查/命令最高；已装包和目录最容易被截
    final lines = <String>[
      '# w_tools 项目上下文（给 AI）',
      '项目: $projectName',
      repoCheckout ? '模式: 仓库检出（跳过消费方 doctor 规则）' : '模式: 消费方项目',
      'w_tools_cli: $cliVersion / catalog v$catalogVersion',
      'toolkit: ${toolkitPath ?? '（未初始化）'}'
          '${toolkitExports.isEmpty ? '' : '（导出 ${toolkitExports.join(', ')}）'}',
      repoCheckout ? '当前: 仓库检出，跳过消费方 doctor 规则' : '当前: $errorCount error / $warnCount warning',
      '命令: ${commands().entries.map((e) => '${e.key}=${e.value}').join(' | ')}',
      '直接依赖: ${dependencies.isEmpty ? '（无）' : dependencies.join(', ')}',
      '规则: ${doctorRuleIds.map((id) => '$id=${doctorRuleLevels[id]}').join(' ')}',
      '暂存层: $stagingDir（$designSystemFiles 个文件，$missingStaged 个缺 STAGED）',
      '已装(w_tools/直接依赖): ${_installed()}',
      if (capabilities().isNotEmpty)
        '能力: ${capabilities().map((e) => '${e['package']}=${e['summary']}').join(' | ')}',
      '组件: ${catalog.length} 条，用 list/explain 查，不要凭记忆造组件名',
    ];
    if (maxTokens <= 0) return lines.join('\n');
    // 中文约 1 字/token，按 2 字符/token 留余量，而不是 4
    final budget = maxTokens * 2;
    final out = StringBuffer();
    var truncated = false;
    for (final line in lines) {
      final remaining = budget - out.length;
      if (remaining <= 1) {
        truncated = true;
        break;
      }
      if (line.length + 1 > remaining) {
        out.writeln('${line.substring(0, remaining - 1)}…');
        truncated = true;
        break;
      }
      out.writeln(line);
    }
    if (truncated) out.writeln('…（已截断，完整内容用 --format=json）');
    return out.toString();
  }

  String _installed() {
    const workspaceMissing = '（仓库检出：workspace 包不在 pubspec.lock，见直接依赖）';
    if (packages.isEmpty) {
      return repoCheckout ? workspaceMissing : '（未解析到 pubspec.lock）';
    }
    final direct = dependencies.toSet();
    final entries =
        packages.entries
            .where((e) => e.key.startsWith('w_tools_') || direct.contains(e.key))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    // 仓库检出时根依赖都解析到 path 包，可能一条都匹配不到；不要输出空的「已安装：」。
    if (entries.isEmpty) return repoCheckout ? workspaceMissing : '（无）';
    return entries.map((e) => '`${e.key} ${e.value}`').join('、');
  }
}
