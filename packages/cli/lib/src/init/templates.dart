import '../common/version.dart';
import '../doctor/banned_rule.dart';
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
    List<BannedRule> banned = const <BannedRule>[],
  }) {
    final en = lang == 'en';
    String part(String zh, String enText) => en ? enText : zh;

    final valid = banned.where((entry) => entry.validate() == null).toList();
    final bannedLines = <String>[
      if (valid.isNotEmpty) '',
      if (valid.isNotEmpty) '### 本项目禁用 API',
      for (final entry in valid)
        '- `${entry.id}`：`${entry.pattern}`'
            '${[
                  if (entry.use?.trim().isNotEmpty == true) '改用 `${entry.use}`',
                  if (entry.reason?.trim().isNotEmpty == true) '原因：${entry.reason}',
                ].isEmpty ? '' : '（${[
                    if (entry.use?.trim().isNotEmpty == true) '改用 `${entry.use}`',
                    if (entry.reason?.trim().isNotEmpty == true) '原因：${entry.reason}',
                  ].join('；')}）'}',
    ];

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
      ...bannedLines,
      part(generated.agentsClosing, generated.agentsClosingEn),
    ];
    return parts
        .join('\n\n')
        .replaceAll('{{version}}', cliVersion)
        .replaceAll('{{app}}', app)
        .trimRight();
  }
}
