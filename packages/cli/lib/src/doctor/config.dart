import 'dart:io';

import 'package:yaml/yaml.dart';

import '../layout.dart';
import 'banned_rule.dart';
import 'rule.dart';

/// doctor 的配置（`.w_tools_doctor.yaml`）。
///
/// 优先级：CLI 参数 > 配置文件 > 内置默认。
/// 内置默认**不含调色板**（R3 需要项目自己声明语义色，避免把某个项目的色值当通用规则）。
/// 固定路径：init 生成物与 doctor 检查必须使用同一套目录。
const String projectUiDirPath = ProjectLayout.projectUiDir;
const String designSystemDirPath = ProjectLayout.designSystemDir;

class DoctorConfig {
  DoctorConfig({
    this.toolkitEntry = ProjectLayout.toolkitEntry,
    this.palette = const <String>[],
    this.colorMinCount = 3,
    this.enabledRules = const <String>{'R1', 'R2', 'R3', 'R4', 'R5', 'R9'},
    this.ignore = const <String>[],
    this.banned = const <BannedRule>[],
    this.aiTargets = const <String>['agents'],
    this.aiLanguage = 'zh',
    this.aiFigma = 'auto',
  });

  /// R2 的白名单：这个文件里允许 import 子包（它就是聚合入口）
  final String toolkitEntry;

  /// R3 的语义色调色板（十六进制，大小写不敏感，可带/不带 `#`）。为空时 R3 跳过。
  final List<String> palette;

  /// R3 阈值：同一颜色出现次数达到此值才报
  final int colorMinCount;

  /// 启用的规则 id（R6 默认不启用）
  final Set<String> enabledRules;

  /// 忽略的路径前缀（相对项目根，按 startsWith 匹配）
  final List<String> ignore;

  /// 项目级禁用 API；空列表时 R9 跳过。
  final List<BannedRule> banned;

  /// init 默认生成哪些指令文件：agents / claude / cursor / copilot
  final List<String> aiTargets;

  /// init 默认语言：zh / en
  final String aiLanguage;

  /// init 是否生成 Figma 片段：auto / true / false。
  /// auto 时由项目 pubspec 是否依赖 w_tools_figma 决定。
  final String aiFigma;

  /// 配置文件名（项目根）
  static const fileName = '.w_tools_doctor.yaml';

  static DoctorConfig load(Directory root) {
    final file = File('${root.path}/$fileName');
    if (!file.existsSync()) return DoctorConfig();
    return parse(file.readAsStringSync());
  }

  /// 从 YAML 文本解析；非 Map 或字段缺失时退回默认值。
  ///
  /// YAML 语法错误会抛 [YamlException]，由调用方处理。
  static DoctorConfig parse(String yamlText) {
    final raw = loadYaml(yamlText);
    if (raw is! YamlMap) return DoctorConfig();

    final rules = <String>{'R1', 'R2', 'R3', 'R4', 'R5', 'R9'};
    final rulesNode = raw['rules'];
    if (rulesNode is YamlMap) {
      rulesNode.forEach((k, v) {
        if (v == true) rules.add('$k');
        if (v == false) rules.remove('$k');
        if (k == 'R6' && v is YamlMap && v['enabled'] == true) rules.add('R6');
      });
    }

    // R3 的两种写法：顶层 colors，或 rules.R3
    var palette = <String>[];
    var minCount = 3;
    final colorsNode = raw['colors'];
    if (colorsNode is YamlMap) {
      final p = colorsNode['palette'];
      if (p is YamlList) palette = p.map((e) => '$e').toList();
      final m = colorsNode['min_count'];
      if (m is int) minCount = m;
    }
    final r3 = raw['rules'] is YamlMap ? (raw['rules'] as YamlMap)['R3'] : null;
    if (r3 is YamlMap) {
      final p = r3['palette'];
      if (p is YamlList) palette = p.map((e) => '$e').toList();
      final m = r3['min_count'];
      if (m is int) minCount = m;
    }

    final banned = <BannedRule>[];
    final bannedNode = raw['banned'];
    if (bannedNode is YamlList) {
      for (var i = 0; i < bannedNode.length; i++) {
        final node = bannedNode[i];
        if (node is! YamlMap) {
          banned.add(
            BannedRule(
              id: 'banned-${i + 1}',
              pattern: '',
              mode: BannedPatternMode.literal,
              use: null,
              reason: null,
              level: DoctorLevel.warn,
              paths: const <String>[],
              ignore: const <String>[],
              error: 'banned 第 ${i + 1} 项不是 map',
            ),
          );
          continue;
        }
        final modeText = '${node['mode'] ?? 'literal'}';
        final mode = switch (modeText) {
          'regex' => BannedPatternMode.regex,
          'literal' => BannedPatternMode.literal,
          _ => BannedPatternMode.literal,
        };
        final levelText = '${node['level'] ?? 'warn'}';
        final level = switch (levelText) {
          'error' => DoctorLevel.error,
          'info' => DoctorLevel.info,
          _ => DoctorLevel.warn,
        };
        final paths = node['paths'] is YamlList
            ? (node['paths'] as YamlList).map((e) => '$e').toList()
            : const <String>[];
        final ignores = node['ignore'] is YamlList
            ? (node['ignore'] as YamlList).map((e) => '$e').toList()
            : const <String>[];
        final rule = BannedRule(
          id: '${node['id'] ?? 'banned-${i + 1}'}',
          pattern: '${node['pattern'] ?? ''}',
          mode: mode,
          use: node['use']?.toString(),
          reason: node['reason']?.toString(),
          level: level,
          paths: paths,
          ignore: ignores,
          error: modeText != 'literal' && modeText != 'regex'
              ? 'banned 条目 `${node['id'] ?? i + 1}` 的 mode 必须是 literal 或 regex'
              : null,
        );
        banned.add(rule);
      }
    }

    final ignoreNode = raw['ignore'];
    var aiTargets = const <String>['agents'];
    var aiLanguage = 'zh';
    var aiFigma = 'auto';
    final aiNode = raw['ai'];
    if (aiNode is YamlMap) {
      final t = aiNode['targets'];
      if (t is YamlList) aiTargets = t.map((e) => '$e').toList();
      final l = aiNode['language'];
      if (l is String) aiLanguage = l;
      final f = aiNode['figma'];
      if (f is bool) {
        aiFigma = f ? 'true' : 'false';
      } else if (f is String && const <String>{'auto', 'true', 'false'}.contains(f)) {
        aiFigma = f;
      }
    }

    return DoctorConfig(
      toolkitEntry: (raw['toolkit_entry'] as String?) ?? 'lib/app/w/toolkit.dart',
      palette: palette,
      colorMinCount: minCount,
      enabledRules: rules,
      ignore: ignoreNode is YamlList ? ignoreNode.map((e) => '$e').toList() : const <String>[],
      banned: banned,
      aiTargets: aiTargets,
      aiLanguage: aiLanguage,
      aiFigma: aiFigma,
    );
  }

  DoctorConfig copyWith({
    String? toolkitEntry,
    List<String>? palette,
    int? colorMinCount,
    Set<String>? enabledRules,
    List<String>? ignore,
    List<BannedRule>? banned,
    List<String>? aiTargets,
    String? aiLanguage,
    String? aiFigma,
  }) {
    return DoctorConfig(
      toolkitEntry: toolkitEntry ?? this.toolkitEntry,
      palette: palette ?? this.palette,
      colorMinCount: colorMinCount ?? this.colorMinCount,
      enabledRules: enabledRules ?? this.enabledRules,
      ignore: ignore ?? this.ignore,
      banned: banned ?? this.banned,
      aiTargets: aiTargets ?? this.aiTargets,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      aiFigma: aiFigma ?? this.aiFigma,
    );
  }
}

/// 把**代码里的默认值**渲染成带注释的 YAML 配置文件。
///
/// 为什么要生成而不是手写一份模板：手写的模板会和默认值漂移。
/// 这里所有「生效的值」都来自 [DoctorConfig] 的默认实例，
/// 由 `test/config_render_test.dart` 保证「渲染出来的文本能解析回同一份默认值」。
String renderDefaultConfig() {
  final defaults = DoctorConfig();
  final buf = StringBuffer()
    ..writeln('# 由 `dart run w_tools_cli:doctor --print-config` 生成。')
    ..writeln('# 这个文件是可选的：没有它，doctor 就按下面的默认值运行；')
    ..writeln('# 把它写下来只是把可选开关摊开，方便团队按项目调整。')
    ..writeln('toolkit_entry: ${defaults.toolkitEntry}')
    ..writeln()
    ..writeln('colors:')
    ..writeln('  # R3 语义色检查：palette 留空 = 跳过该规则。')
    ..writeln('  # 填上项目的语义色才会检查（同一颜色出现 min_count 次以上才报）。')
    ..writeln('  # palette: ["#3F3F3F", "#545454", "#EAEAEA"]')
    ..writeln('  min_count: ${defaults.colorMinCount}')
    ..writeln()
    ..writeln('rules:')
    ..writeln('  # R6 是**项目专用**规则（禁用 .h / .r 尺寸单位），需要时打开：')
    ..writeln('  # R6: true')
    ..writeln()
    ..writeln('ai:')
    ..writeln('  # init 生成哪些指令文件：agents / claude / cursor / copilot')
    ..writeln('  # targets: [agents, claude]')
    ..writeln('  # language: en')
    ..writeln('  figma: ${defaults.aiFigma}')
    ..writeln('  # auto: pubspec 依赖 w_tools_figma 时生成 Figma 片段；也可设为 true/false')
    ..writeln()
    ..writeln('# 跳过的路径前缀（相对项目根）')
    ..writeln('ignore: []')
    ..writeln('#  - lib/app/generated/')
    ..writeln()
    ..writeln('# 项目级禁用 API（可重复；空列表不检查）：')
    ..writeln('banned: []')
    ..writeln('#  - id: no-raw-image')
    ..writeln("#    pattern: 'Image\\.asset\\('")
    ..writeln('#    mode: regex')
    ..writeln("#    use: 'WImage.asset'")
    ..writeln("#    reason: '项目要求统一图片入口'")
    ..writeln('#    level: warn')
    ..writeln("#    paths: ['lib/app/modules/**']")
    ..writeln("#    ignore: ['lib/app/ui/**']")
    ..writeln()
    ..writeln('# 未来可继承团队基线（当前版本尚未支持）：')
    ..writeln('# include: ../.w_tools_doctor.yaml');
  return buf.toString();
}
