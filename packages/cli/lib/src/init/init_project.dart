import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../doctor/config.dart';
import 'features.dart';
import 'manifest.dart';
import 'targets.dart';
import '../layout.dart';
import 'templates.dart';

/// 子包版本约束。必须与仓库 `packages/*/pubspec.yaml` 的当前版本一致，
/// 由 `test/init_test.dart` 读取仓库 pubspec 校验（防止版本漂移）。
const _subpackageConstraints = <String, String>{
  'w_tools_core': '^2.4.0',
  'w_tools_async': '^2.1.0',
  'w_tools_app': '^1.0.1',
  'w_tools_form': '^3.2.0',
  'w_tools_ui': '^4.7.0',
  'w_tools_api': '^2.0.0',
  'w_tools_toast': '^1.3.0',
  'w_tools_qr': '^1.1.0',
  'w_tools_map': '^1.3.1',
};

/// CLI 自己的版本约束（消费方放在 dev_dependencies）
const _cliConstraint = '^1.9.0';

/// `init` 的执行结果（供 CLI 打印）。
class InitReport {
  InitReport();

  /// 本次写入/更新的文件
  final created = <String>[];

  /// check 模式下缺失、因而需要补的产物 —— 只有它会让 `init --check` 返回非 0
  final missing = <String>[];

  /// 已存在但内容与模板不同的产物：只提示，不算失败（`--force` 才更新）
  final drift = <String>[];

  /// 当前 profile 不生成、但仍存在的旧 UI 生成物（只报告，不删除）
  final stale = <String>[];

  /// 已存在且内容一致（或属于项目自己的配置）
  final upToDate = <String>[];

  final warnings = <String>[];

  /// 需要人工加到 pubspec 的依赖片段
  String pubspecSnippet = '';
}

String _normalizeExport(String line) =>
    line.trim().replaceAll('"', "'").replaceAll(RegExp(r'\s+'), ' ');

/// 旧版 toolkit 没有 marker：只自动迁移模板之外的 export 行。
List<String> _extraExports(String existing, String generated) {
  final generatedLines = generated
      .split('\n')
      .where((line) => line.trim().startsWith('export '))
      .map(_normalizeExport)
      .toSet();
  final extras = <String>[];
  for (final line in existing.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('export ')) continue;
    final normalized = _normalizeExport(trimmed);
    if (generatedLines.contains(normalized) || extras.contains(normalized)) continue;
    extras.add(trimmed);
  }
  return extras;
}

/// 就地初始化一个消费方项目：生成聚合入口、暂存层 README、AGENTS 片段。
///
/// 原则：
/// - **不覆盖已有文件**（除非 [force]）
/// - **不改 pubspec**（只返回片段，由人粘）
/// - [check] 模式**只检查缺失**，不写任何文件；内容不同只提示，不判失败
///   （否则用户自定义的 `.w_tools_doctor.yaml` 会让 CI 永远红）
InitReport runInit(
  Directory root, {
  bool force = false,
  bool forceStarters = false,
  bool check = false,
  InitFeatures features = InitFeatures.full,
  Set<String> targets = const <String>{'agents'},
  String lang = 'zh',
  bool figma = false,
  String? figmaInstall,
  bool device = false,
  InitManifest? manifest,
}) {
  final report = InitReport();
  final app = _projectName(root);
  // --check 只读：迁移会移动文件，必须跳过（旧文件由 InitManifest.load 回退读取）
  if (!check && InitManifest.migrateLegacy(root)) {
    report.warnings.add('已把 .w_tools_init.json 迁到 ${InitManifest.fileName}');
  }

  String backup(File file) {
    final base = File('${file.path}.bak');
    if (!base.existsSync()) {
      file.copySync(base.path);
      return p.basename(base.path);
    }
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final alt = File('${file.path}.bak.$stamp');
    file.copySync(alt.path);
    return p.basename(alt.path);
  }

  void write(
    String rel,
    String content, {
    bool projectConfig = false,
    bool starter = false,
    bool markedBlock = false,
    bool metadata = false,
  }) {
    final file = File(p.join(root.path, rel));
    if (file.existsSync()) {
      if (metadata) {
        final same = file.readAsStringSync() == content;
        if (same) {
          report.upToDate.add(rel);
          return;
        }
        if (check) {
          report.drift.add('$rel（内容不同，未改动）');
          return;
        }
        // manifest 是本次 init 的运行记录，不受 --force 限制。
        file.writeAsStringSync(content);
        report.created.add('$rel（已更新）');
        return;
      }
      if (markedBlock) {
        final existing = file.readAsStringSync();
        final begin = existing.indexOf('// w_tools:begin');
        final end = existing.indexOf('// w_tools:end');
        if (begin >= 0 && end > begin) {
          final next =
              '${existing.substring(0, begin)}${content.trimRight()}${existing.substring(end + '// w_tools:end'.length)}';
          if (next == existing) {
            report.upToDate.add(rel);
            return;
          }
          if (check) {
            report.drift.add('$rel（内容不同：标记块与模板不同）');
            return;
          }
          if (!force) {
            report.drift.add('$rel（标记块内容不同，未改动）');
            return;
          }
          file.writeAsStringSync(next);
          report.created.add('$rel（已覆盖）');
          return;
        }
        // 旧文件没有 marker：--force 前备份，首次迁移为 marker block。
        if (check || !force) {
          report.drift.add('$rel（内容不同：缺少 w_tools:begin/end 标记块）');
          return;
        }
        final extras = _extraExports(existing, content);
        final name = backup(file);
        final migrated = extras.isEmpty
            ? content
            : '${content.trimRight()}\n\n// migrated from legacy toolkit\n${extras.join('\n')}\n';
        file.writeAsStringSync(migrated);
        report.warnings.add(
          extras.isEmpty
              ? '覆盖了 $rel：旧文件无标记块，原内容已备份到 $name'
              : '覆盖了 $rel：旧文件无标记块，已迁移 ${extras.length} 个自定义 export；'
                    '其余自定义代码仍在 $name',
        );
        report.created.add('$rel（已覆盖）');
        return;
      }
      // 项目配置（.w_tools_doctor.yaml）：内容由项目手工维护（palette / banned / ignore），
      // --force 覆盖前先备份，避免把项目配置直接抹掉。
      if (projectConfig) {
        if (!force) {
          report.upToDate.add(rel);
          return;
        }
        if (file.readAsStringSync() == content) {
          report.upToDate.add(rel);
          return;
        }
        final backup = File('${file.path}.bak');
        backup.writeAsStringSync(file.readAsStringSync());
        file.writeAsStringSync(content);
        report.warnings.add('覆盖了 $rel：原内容已备份到 ${p.basename(backup.path)}');
        report.created.add('$rel（已覆盖）');
        return;
      }
      // 可自定义的起始文件：存在即视为完成；只有 --force-starters 才覆盖
      if (starter && !forceStarters) {
        report.upToDate.add(rel);
        return;
      }
      if (file.readAsStringSync() == content) {
        report.upToDate.add(rel);
        return;
      }
      if (check) {
        report.drift.add('$rel（内容不同，未改动）');
        return;
      }
      if (!force && !(starter && forceStarters)) {
        report.drift.add('$rel（已存在且内容不同，未改动）');
        return;
      }
      if (projectConfig) {
        report.warnings.add('覆盖了 $rel：原有的自定义配置会丢失');
      } else if (starter) {
        final name = backup(file);
        report.warnings.add('覆盖了 $rel：原内容已备份到 $name');
      }
      file.writeAsStringSync(content);
      report.created.add('$rel（已覆盖）');
      return;
    }
    if (check) {
      // `--check` 只检查用户可见的生成物：
      // - `.w_tools/init.json` 是内部运行记录，不是项目产物；
      // - `.w_tools_doctor.yaml` 是可选配置（不写也按默认运行）。
      if (!metadata && !projectConfig) report.missing.add(rel);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    report.created.add(rel);
  }

  if (device) {
    write(
      'integration_test/app_smoke_test.dart',
      InitTemplates.deviceAppSmokeTest(),
      starter: true,
    );
    write('tool/device_smoke.dart', InitTemplates.deviceSmokeScript(), starter: true);
    write(
      'docs/agents/device-testing.md',
      InitTemplates.deviceTestingDoc(
        projectName: app,
        androidAppId: _androidApplicationId(root),
      ),
      starter: true,
    );
    write(
      'tool/gradle-mirror.init.gradle.example',
      InitTemplates.deviceGradleMirror(),
      starter: true,
    );
  }

  // 读回项目配置：banned 要生成进 AGENTS，toolkit 路径也可能被项目改过。
  // 配置损坏时不阻塞 init。
  var projectConfig = DoctorConfig();
  try {
    projectConfig = DoctorConfig.load(root);
  } on Object {
    report.warnings.add('${DoctorConfig.fileName} 解析失败，本次按空 banned 生成 AGENTS');
  }

  write(
    projectConfig.toolkitEntry,
    InitTemplates.toolkit(features: features),
    markedBlock: true,
  );
  if (features.ui) {
    write(
      '${ProjectLayout.designSystemDir}/README.md',
      InitTemplates.designSystemReadme(lang: lang),
    );
    write(
      '${ProjectLayout.projectUiDir}/README.md',
      InitTemplates.uiReadme(lang: lang),
      starter: true,
    );
    write('${ProjectLayout.projectUiDir}/app_bars.dart', InitTemplates.appBars(), starter: true);
    write('${ProjectLayout.projectUiDir}/app_boxes.dart', InitTemplates.appBoxes(), starter: true);
    write(
      '${ProjectLayout.projectUiDir}/app_buttons.dart',
      InitTemplates.appButtons(),
      starter: true,
    );
    write('${ProjectLayout.projectUiDir}/app_card.dart', InitTemplates.appCard(), starter: true);
    write(
      '${ProjectLayout.projectUiDir}/app_scaffold.dart',
      InitTemplates.appScaffold(),
      starter: true,
    );
  }
  // doctor 的默认配置：带注释，值与内置默认一致，只是把开关摊开。
  // 它是项目配置而不是生成物：存在就不再比对内容。
  write(DoctorConfig.fileName, renderDefaultConfig(), projectConfig: true);
  for (final target in targets) {
    final rel = targetFiles[target];
    if (rel == null) continue;
    _upsertBlock(
      root,
      rel,
      report,
      check: check,
      block: InitTemplates.agentsBlock(
        lang: lang,
        app: app,
        withUi: features.ui,
        withApp: features.app,
        withForm: features.form,
        withApi: features.api,
        withAsync: features.asyncFeature,
        withToast: features.toast,
        withQr: features.qr,
        withMap: features.map,
        withFigma: figma,
        withDevice: device,
        figmaInstall: figmaInstall,
        banned: projectConfig.banned,
      ),
      createdPrefix: target == 'cursor'
          ? '---\ndescription: w_tools conventions\nglobs:\n---\n\n'
          : '',
    );
  }

  _collectStale(report, root, features, targets);
  // --check 只读：manifest 是本次 init 的运行记录，check 模式下不写、也不参与 drift
  // （否则 CLI 升级后 generator 版本变化会让 --check-drift 永远红）。
  if (!check && manifest != null) {
    write(InitManifest.fileName, manifest.encode(), metadata: true);
  }
  report.pubspecSnippet = _snippet(
    root,
    report,
    features: features,
  );
  return report;
}

const _uiStarterFiles = <String>[
  '${ProjectLayout.designSystemDir}/README.md',
  '${ProjectLayout.projectUiDir}/README.md',
  '${ProjectLayout.projectUiDir}/app_bars.dart',
  '${ProjectLayout.projectUiDir}/app_boxes.dart',
  '${ProjectLayout.projectUiDir}/app_buttons.dart',
  '${ProjectLayout.projectUiDir}/app_card.dart',
  '${ProjectLayout.projectUiDir}/app_scaffold.dart',
];

void _collectStale(
  InitReport report,
  Directory root,
  InitFeatures features,
  Set<String> targets,
) {
  if (!features.ui) {
    for (final rel in _uiStarterFiles) {
      if (File(p.join(root.path, rel)).existsSync()) {
        report.stale.add('$rel（当前 profile 不生成，未删除）');
      }
    }
  }

  for (final entry in targetFiles.entries) {
    if (targets.contains(entry.key)) continue;
    final file = File(p.join(root.path, entry.value));
    if (!file.existsSync()) continue;
    if (!file.readAsStringSync().contains('<!-- w_tools:begin -->')) continue;
    report.stale.add('${entry.value}（当前 targets 未包含 ${entry.key}，未删除）');
  }
}

String _projectName(Directory root) {
  final file = File(p.join(root.path, 'pubspec.yaml'));
  if (!file.existsSync()) return 'app';
  try {
    final raw = loadYaml(file.readAsStringSync());
    if (raw is YamlMap) return (raw['name'] as String?) ?? 'app';
  } on YamlException {
    // pubspec 写坏时回退到 app；真正的解析警告由 _snippet 报出
  }
  return 'app';
}

void _upsertBlock(
  Directory root,
  String rel,
  InitReport report, {
  required bool check,
  required String block,
  String createdPrefix = '',
}) {
  final file = File(p.join(root.path, rel));
  final blockText = block.trim();
  const begin = '<!-- w_tools:begin -->';
  const end = '<!-- w_tools:end -->';

  if (!file.existsSync()) {
    if (check) {
      report.missing.add(rel);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$createdPrefix$blockText\n');
    report.created.add(rel);
    return;
  }

  final content = file.readAsStringSync();
  final b = content.indexOf(begin);
  final e = content.indexOf(end);

  if (b >= 0 && e > b) {
    // 已有标记块 → 原地替换（幂等，标记块由 w_tools 管理）
    final next = content.replaceRange(b, e + end.length, blockText);
    if (next == content) {
      report.upToDate.add(rel);
      return;
    }
    if (check) {
      report.drift.add('$rel（内容不同：标记块与模板不同）');
      return;
    }
    file.writeAsStringSync(next);
    report.created.add('$rel（已更新标记块）');
    return;
  }

  if (b >= 0) {
    // 有 begin 没 end：不猜，交给人修，避免越写越乱
    if (check) {
      report.missing.add('$rel（标记块缺少 w_tools:end）');
    } else {
      report.drift.add('$rel（标记块不完整：缺少 w_tools:end）');
      report.warnings.add('$rel 的标记块不完整，未改动；请手工补齐 end 标记后重跑');
    }
    return;
  }

  if (check) {
    report.missing.add('$rel（缺少 w_tools 标记块）');
    return;
  }
  file.writeAsStringSync('${content.trimRight()}\n\n$blockText\n');
  report.created.add('$rel（已追加 w_tools 片段）');
}

String _snippet(
  Directory root,
  InitReport report, {
  required InitFeatures features,
}) {
  final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
  var name = 'app';
  var existing = <String>{};
  var existingDev = <String>{};
  var hasDeps = false;
  var hasDev = false;
  if (pubspecFile.existsSync()) {
    try {
      final raw = loadYaml(pubspecFile.readAsStringSync());
      if (raw is YamlMap) {
        name = (raw['name'] as String?) ?? name;
        final deps = raw['dependencies'];
        if (deps is YamlMap) {
          hasDeps = true;
          existing = deps.keys.map((e) => '$e').toSet();
        }
        final dev = raw['dev_dependencies'];
        if (dev is YamlMap) {
          hasDev = true;
          existingDev = dev.keys.map((e) => '$e').toSet();
        }
      }
    } on YamlException catch (e) {
      report.warnings.add('pubspec.yaml 解析失败，依赖片段按默认值生成：${e.message}');
    }
  }

  final pkgs = <String>[
    'w_tools_core',
    if (features.app) 'w_tools_app',
    if (features.form) 'w_tools_form',
    if (features.ui) 'w_tools_ui',
    if (features.api) 'w_tools_api',
    if (features.toast) 'w_tools_toast',
    if (features.qr) 'w_tools_qr',
    if (features.map) 'w_tools_map',
    if (features.asyncFeature) 'w_tools_async',
  ];

  final depLines = <String>[
    for (final pkg in pkgs)
      if (!existing.contains(pkg)) '$pkg: ${_subpackageConstraints[pkg]}',
  ];
  final devLines = <String>[
    if (!existingDev.contains('w_tools_cli')) 'w_tools_cli: $_cliConstraint',
  ];
  if (depLines.isEmpty && devLines.isEmpty) {
    return '# 依赖已齐全，无需修改 pubspec.yaml\n';
  }

  final buf = StringBuffer()..writeln('dependencies 已存在时只追加缩进行，不要重复 section 头。');
  void addSection(String title, List<String> lines, bool exists) {
    if (lines.isEmpty) return;
    buf.writeln(exists ? '# 追加到已有的 $title: 下' : '$title:');
    for (final line in lines) {
      buf.writeln('  $line');
    }
    buf.writeln();
  }

  addSection('dependencies', depLines, hasDeps);
  addSection('dev_dependencies', devLines, hasDev);
  return buf.toString();
}

/// 从 `android/app/build.gradle(.kts)` 里读 applicationId（读不到返回 null）。
String? _androidApplicationId(Directory root) {
  for (final name in const ['build.gradle', 'build.gradle.kts']) {
    final file = File(p.join(root.path, 'android', 'app', name));
    if (!file.existsSync()) continue;
    final m = RegExp(
      r'''applicationId\s*=?\s*["']([^"']+)["']''',
    ).firstMatch(file.readAsStringSync());
    if (m != null) return m.group(1);
  }
  return null;
}
