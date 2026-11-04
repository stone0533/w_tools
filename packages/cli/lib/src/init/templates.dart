import '../common/version.dart';
import '../doctor/banned_rule.dart';
import '../doctor/run.dart';
import '../layout.dart';
import 'features.dart';
import 'templates.g.dart' as generated;

/// `init` 用的模板内容。
///
/// **唯一来源是仓库根目录的 `templates/`**（人可读、可 diff、可复制）。
/// 这里只是把生成好的常量取出来，不再有第二份手写内容。
///
/// 为什么是「生成常量」而不是运行时读文件：
/// `Isolate.resolvePackageUri` 在 flutter_test 里会抛 `Unsupported operation`，
/// 消费方执行 `dart run w_tools_cli:init` 时也可能拿不到可靠路径。
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

  static String _doctorRuleTable(bool en) {
    final header = en ? '| Rule | Checks |' : '| 规则 | 检查 |';
    final divider = '| --- | --- |';
    final rows = <String>[
      for (final rule in doctorRules) '| ${rule.id} | ${en ? rule.summaryEn : rule.summaryZh} |',
    ];
    return <String>[header, divider, ...rows].join('\n');
  }

  static String agentsBlock({
    String lang = 'zh',
    String app = 'app',
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
    List<BannedRule> banned = const <BannedRule>[],
  }) {
    final en = lang == 'en';
    String part(String zh, String enText) => en ? enText : zh;

    final valid = banned.where((entry) => entry.validate() == null).toList();
    final bannedLines = <String>[];
    if (valid.isNotEmpty) {
      bannedLines
        ..add('')
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
      part(generated.agentsFeedback, generated.agentsFeedbackEn),
      part(generated.agentsClosing, generated.agentsClosingEn),
    ];
    return parts
        .join('\n\n')
        .replaceAll('{{version}}', cliVersion)
        .replaceAll('{{app}}', app)
        .replaceAll(
          '{{figmaInstall}}',
          figmaInstall ?? 'dart pub add dev:w_tools_figma',
        )
        .replaceAll('{{doctorRules}}', _doctorRuleTable(en))
        .trimRight();
  }
}
