import '../common/version.dart';
import '../doctor/banned_rule.dart';
import '../doctor/rules/r2_direct_subpackage_import.dart';
import '../layout.dart';
import 'conditional_template.dart';
import 'features.dart';
import 'targets.dart';
import 'templates.g.dart' as generated;

/// `init` 用的模板内容。
///
/// **唯一来源是仓库根目录的 `templates/`**（人可读、可 diff、可复制）。
/// 这里只是把生成好的常量取出来，不再有第二份手写内容。
///
/// 为什么是「生成常量」而不是运行时读文件：
/// `Isolate.resolvePackageUri` 在 flutter_test 里会抛 `Unsupported operation`，
/// 消费方执行 `dart run w_tools_cli:w_tools init` 时也可能拿不到可靠路径。
/// 生成物由 `test/templates_fresh_test.dart` 挡住漂移。
class InitTemplates {
  InitTemplates._();

  /// 聚合入口模板：剔除带 `@optional:qr` / `@optional:map` 标记的行。
  static String toolkit({required InitFeatures features}) {
    final out = <String>[];
    final enabled = features.enabled.toSet();
    for (final line in generated.toolkitTemplate.split('\n')) {
      final match = RegExp(r'@optional:([a-z]+)').firstMatch(line);
      if (match != null && !enabled.contains(match.group(1))) continue;
      out.add(line);
    }
    return out.join('\n').replaceAll('{{version}}', cliVersion);
  }

  static String designSystemReadme({String lang = 'zh'}) =>
      (lang == 'en' ? generated.designSystemReadmeEn : generated.designSystemReadme).replaceAll(
        '{{version}}',
        cliVersion,
      );

  /// 设备验证文档骨架（通用命令，项目相关信息由用户补）。
  static String deviceTestingDoc({required String projectName}) =>
      generated.deviceTestingDoc.replaceAll('{{projectName}}', projectName);

  static String deviceGradleMirror() => generated.deviceGradleMirror;

  static String appBars() => generated.appBarsTemplate.replaceAll('{{version}}', cliVersion);

  static String appBoxes() => generated.appBoxesTemplate.replaceAll('{{version}}', cliVersion);

  static String appCard() => generated.appCardTemplate.replaceAll('{{version}}', cliVersion);

  static String appScaffold() =>
      generated.appScaffoldTemplate.replaceAll('{{version}}', cliVersion);

  static String uiReadme({String lang = 'zh'}) =>
      (lang == 'en' ? generated.uiReadmeEn : generated.uiReadme).replaceAll(
        '{{version}}',
        cliVersion,
      );

  static String appButtons() => generated.appButtonsTemplate.replaceAll('{{version}}', cliVersion);

  /// 消费方 AI 任务提示词；生成到 `.w_tools/AI_PROMPTS.md`。
  ///
  /// [rulesFiles] 是本次 `init` 实际写入的指令文件（AGENTS.md / CLAUDE.md / …）。
  /// [toolkitImport] 是项目聚合入口的 package import，写进固定前缀，避免 AI 猜路径。
  /// [isFlutter] / [usesAggregate] 决定工具链命令与依赖说明，纯 Dart 或旧聚合包
  /// 项目不会被要求执行 `flutter` 或删除已有聚合依赖。
  static String aiPrompts({
    String lang = 'zh',
    InitFeatures features = InitFeatures.full,
    String rulesFiles = 'AGENTS.md',
    String toolkitImport = 'package:app/app/w/toolkit.dart',
    bool isFlutter = true,
    bool usesAggregate = false,
  }) {
    final enabled = features.enabled.toSet();
    final en = lang == 'en';
    final analyze = isFlutter ? 'flutter analyze' : 'dart analyze';
    final test = isFlutter ? 'flutter test' : 'dart test';
    final pubUpgrade = isFlutter ? 'flutter pub upgrade' : 'dart pub upgrade';
    final testFramework = isFlutter ? 'flutter_test' : 'test';
    final integrationTest = isFlutter ? 'flutter test integration_test/...' : 'dart test test/...';
    final dependencyNote = usesAggregate
        ? (en
              ? 'This project uses the aggregate `w_tools` package for legacy compatibility; '
                    'keep it as-is and add new dependencies as sub-packages only.'
              : '本项目已使用聚合包 `w_tools`（旧项目兼容）；保持现状，新依赖只加具体子包。')
        : (en
              ? 'This project depends on specific sub-packages; '
                    'add new dependencies as sub-packages only.'
              : '本项目依赖具体子包；新依赖只加具体子包。');

    final rendered = ConditionalTemplate.render(
      en ? generated.aiPromptsEn : generated.aiPrompts,
      enabled,
    );
    return rendered
        .replaceAll('{{version}}', cliVersion)
        .replaceAll('{{rulesFiles}}', rulesFiles)
        .replaceAll('{{toolkitImport}}', toolkitImport)
        .replaceAll('{{dependencyNote}}', dependencyNote)
        .replaceAll('{{analyze}}', analyze)
        .replaceAll('{{test}}', test)
        .replaceAll('{{pubUpgrade}}', pubUpgrade)
        .replaceAll('{{testFramework}}', testFramework)
        .replaceAll('{{integrationTest}}', integrationTest);
  }

  /// 指令文件清单（`AGENTS.md / CLAUDE.md / …`）：AI_PROMPTS 与 R8 共用。
  static String rulesFiles(Set<String> targets) {
    final files = <String>{
      for (final target in targets)
        if (targetFiles[target] != null) targetFiles[target]!,
    }.toList()..sort();
    return files.isEmpty ? 'AGENTS.md' : files.join(' / ');
  }

  /// 聚合入口的 package import：R8 回放生成内容时也要用同一套换算。
  static String toolkitImport(String app, String toolkitEntry) =>
      toolkitEntry.startsWith('lib/') ? 'package:$app/${toolkitEntry.substring(4)}' : toolkitEntry;

  /// UI / 暂存层生成物：路径 → (内容, 是否 starter)。
  ///
  /// 写入与 stale 检测都从这里派生，避免两处各列一遍文件。
  static Map<String, ({String content, bool starter})> uiStarters({String lang = 'zh'}) {
    return <String, ({String content, bool starter})>{
      '${ProjectLayout.designSystemDir}/README.md': (
        content: designSystemReadme(lang: lang),
        starter: false,
      ),
      '${ProjectLayout.projectUiDir}/README.md': (
        content: uiReadme(lang: lang),
        starter: true,
      ),
      '${ProjectLayout.projectUiDir}/app_bars.dart': (content: appBars(), starter: true),
      '${ProjectLayout.projectUiDir}/app_boxes.dart': (content: appBoxes(), starter: true),
      '${ProjectLayout.projectUiDir}/app_buttons.dart': (content: appButtons(), starter: true),
      '${ProjectLayout.projectUiDir}/app_card.dart': (content: appCard(), starter: true),
      '${ProjectLayout.projectUiDir}/app_scaffold.dart': (content: appScaffold(), starter: true),
    };
  }

  /// 指令文件末尾的「项目规则」占位：**写在标记块之外**，`init` 不会覆盖。
  ///
  /// 之前这块占位写在标记块内，标题还会把后面所有组件约定一起吞掉；
  /// 现在只在新建文件时追加一次，重复执行不会重复插入。
  static String projectRulesStub({String lang = 'zh'}) => lang == 'en'
      ? '## Project rules\n\n'
            '<!-- This section lives outside the w_tools block; `init` never overwrites it. -->\n'
      : '## 项目规则\n\n'
            '<!-- 本节在 w_tools 标记块之外，写项目自己的约定；`init` 不会覆盖这里。 -->\n';

  /// R2 的 import 例外：从 doctor 规则里的**同一份常量**渲染，避免第三次手写。
  static String importExceptions({required bool en, required String toolkitEntry}) {
    final devOnly = R2DirectSubpackageImport.devOnlyPackages.toList()..sort();
    final dirs = <String>[
      '`$toolkitEntry`',
      '`${ProjectLayout.projectUiDir}/`',
      '`${ProjectLayout.designSystemDir}/`',
    ];
    if (en) {
      return 'allowed: ${dirs.join(', ')};\n'
          '  ${devOnly.join(' / ')} are also allowed under '
          '`test/` / `tool/` / `integration_test/`';
    }
    return '允许 ${dirs.join('、')}；\n'
        '  `test/` `tool/` `integration_test/` 下另允许 ${devOnly.join(' / ')}';
  }

  static String agentsBlock({
    String lang = 'zh',
    String app = 'app',
    bool isFlutter = true,
    bool withUi = true,
    bool withApp = true,
    bool withForm = true,
    bool withApi = true,
    bool withAsync = true,
    bool withToast = true,
    bool withQr = true,
    bool withMap = true,
    bool withFigma = false,
    bool withDevice = false,
    String? figmaInstall,
    String toolkitEntry = ProjectLayout.toolkitEntry,
    List<BannedRule> banned = const <BannedRule>[],
  }) {
    final en = lang == 'en';
    String part(String zh, String enText) => en ? enText : zh;

    final valid = banned.where((entry) => entry.validate() == null).toList();
    final bannedLines = <String>[];
    if (valid.isNotEmpty) {
      bannedLines
        ..add(en ? '### Project-banned APIs' : '### 本项目禁用 API')
        ..add(
          en
              ? 'R9 only matches registered patterns; unregistered APIs or new forms still require human review.'
              : 'R9 只匹配已登记的 pattern；未登记的 API / 新形态仍需人工评审。',
        );
      for (final entry in valid) {
        final details = <String>[
          if (entry.use?.trim().isNotEmpty == true) en ? 'use `${entry.use}`' : '改用 `${entry.use}`',
          if (entry.reason?.trim().isNotEmpty == true)
            en ? 'reason: ${entry.reason}' : '原因：${entry.reason}',
        ];
        final suffix = details.isEmpty
            ? ''
            : en
            ? ' (${details.join('; ')})'
            : '（${details.join('；')}）';
        bannedLines.add(
          en
              ? '- `${entry.id}`: `${entry.pattern}`$suffix'
              : '- `${entry.id}`：`${entry.pattern}`$suffix',
        );
      }
    }

    // 顺序 = 阅读顺序：怎么用 → 硬规则 → 每包一行 → 禁用 API → 完成前。
    // 每包只有一行「一句话规则 + 细节入口」；组件事实在 catalog / explain 里，不在这里复写。
    final parts = <String>[
      part(generated.agentsBase, generated.agentsBaseEn),
      if (withUi) part(generated.agentsUi, generated.agentsUiEn),
      if (withForm) part(generated.agentsForm, generated.agentsFormEn),
      if (withApi) part(generated.agentsApi, generated.agentsApiEn),
      if (withApp) part(generated.agentsApp, generated.agentsAppEn),
      if (withAsync) part(generated.agentsAsync, generated.agentsAsyncEn),
      if (withToast) part(generated.agentsToast, generated.agentsToastEn),
      part(generated.agentsCore, generated.agentsCoreEn),
      if (withQr) part(generated.agentsQr, generated.agentsQrEn),
      if (withMap) part(generated.agentsMap, generated.agentsMapEn),
      if (withFigma) part(generated.agentsFigma, generated.agentsFigmaEn),
      if (withDevice) part(generated.agentsDevice, generated.agentsDeviceEn),
      ...bannedLines,
      part(generated.agentsClosing, generated.agentsClosingEn),
    ];
    return parts
        .map((part) => part.trim())
        .join('\n\n')
        .replaceAll('{{version}}', cliVersion)
        .replaceAll(
          '{{toolkitImport}}',
          '$app/${toolkitEntry.startsWith('lib/') ? toolkitEntry.substring(4) : toolkitEntry}',
        )
        .replaceAll('{{toolkitEntry}}', toolkitEntry)
        .replaceAll('{{projectUiDir}}', ProjectLayout.projectUiDir)
        .replaceAll('{{designSystemDir}}', ProjectLayout.designSystemDir)
        .replaceAll(
          '{{importExceptions}}',
          importExceptions(en: en, toolkitEntry: toolkitEntry),
        )
        .replaceAll('{{analyze}}', isFlutter ? 'flutter analyze' : 'dart analyze')
        .replaceAll('{{test}}', isFlutter ? 'flutter test' : 'dart test')
        .replaceAll(
          '{{figmaInstall}}',
          figmaInstall ?? 'dart pub add dev:w_tools_figma',
        )
        .trimRight();
  }
}
