import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../doctor/config.dart';
import 'targets.dart';
import 'templates.dart';

/// 子包版本约束。必须与仓库 `packages/*/pubspec.yaml` 的当前版本一致，
/// 由 `test/init_test.dart` 读取仓库 pubspec 校验（防止版本漂移）。
const _subpackageConstraints = <String, String>{
  'w_tools_core': '^1.0.1',
  'w_tools_app': '^1.0.0',
  'w_tools_form': '^1.0.1',
  'w_tools_ui': '^2.0.0',
  'w_tools_api': '^1.0.0',
  'w_tools_toast': '^1.0.0',
  'w_tools_qr': '^1.0.0',
  'w_tools_map': '^1.2.0',
};

/// CLI 自己的版本约束（消费方放在 dev_dependencies）
const _cliConstraint = '^1.1.0';

/// `init` 的执行结果（供 CLI 打印）。
class InitReport {
  InitReport();

  /// 本次写入/更新的文件
  final created = <String>[];

  /// check 模式下缺失、因而需要补的产物 —— 只有它会让 `init --check` 返回非 0
  final missing = <String>[];

  /// 已存在但内容与模板不同的产物：只提示，不算失败（`--force` 才更新）
  final drift = <String>[];

  /// 已存在且内容一致（或属于项目自己的配置）
  final upToDate = <String>[];

  final warnings = <String>[];

  /// 需要人工加到 pubspec 的依赖片段
  String pubspecSnippet = '';
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
  bool check = false,
  bool withQr = true,
  bool withMap = false,
  bool withUi = true,
  Set<String> targets = const <String>{'agents'},
  String lang = 'zh',
}) {
  final report = InitReport();
  final app = _projectName(root);

  void write(
    String rel,
    String content, {
    bool projectConfig = false,
    bool starter = false,
  }) {
    final file = File(p.join(root.path, rel));
    if (file.existsSync()) {
      // 项目自己的配置 / 可自定义的起始文件：存在即视为完成，内容不做比对
      if ((projectConfig || starter) && !force) {
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
      if (!force) {
        report.drift.add('$rel（已存在且内容不同，未改动）');
        return;
      }
      if (projectConfig) {
        report.warnings.add('覆盖了 $rel：原有的自定义配置会丢失');
      } else if (starter) {
        report.warnings.add('覆盖了 $rel：原有的自定义内容会丢失');
      }
      file.writeAsStringSync(content);
      report.created.add('$rel（已覆盖）');
      return;
    }
    if (check) {
      report.missing.add(rel);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    report.created.add(rel);
  }

  write(
    'lib/app/w/toolkit.dart',
    InitTemplates.toolkit(withQr: withQr, withMap: withMap, withUi: withUi),
  );
  if (withUi) {
    write(
      'lib/app/design_system/README.md',
      InitTemplates.designSystemReadme(lang: lang),
    );
    write('lib/app/ui/README.md', InitTemplates.uiReadme(lang: lang), starter: true);
    write('lib/app/ui/app_bars.dart', InitTemplates.appBars(), starter: true);
    write('lib/app/ui/app_boxes.dart', InitTemplates.appBoxes(), starter: true);
    write('lib/app/ui/app_buttons.dart', InitTemplates.appButtons(), starter: true);
    write('lib/app/ui/app_card.dart', InitTemplates.appCard(), starter: true);
    write('lib/app/ui/app_scaffold.dart', InitTemplates.appScaffold(), starter: true);
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
      block: InitTemplates.agentsBlock(lang: lang, app: app, withUi: withUi),
      createdPrefix: target == 'cursor'
          ? '---\ndescription: w_tools conventions\nglobs:\n---\n\n'
          : '',
    );
  }

  report.pubspecSnippet = _snippet(
    root,
    report,
    withQr: withQr,
    withMap: withMap,
    withUi: withUi,
  );
  return report;
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
      report.drift.add('$rel（标记块内容与模板不同）');
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
  required bool withQr,
  required bool withMap,
  required bool withUi,
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
    'w_tools_app',
    'w_tools_form',
    if (withUi) 'w_tools_ui',
    'w_tools_api',
    'w_tools_toast',
    if (withQr) 'w_tools_qr',
    if (withMap) 'w_tools_map',
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
