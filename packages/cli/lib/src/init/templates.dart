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
  static String toolkit({required bool withQr, required bool withMap}) {
    final out = <String>[];
    for (final line in generated.toolkitTemplate.split('\n')) {
      if (line.contains('@optional:qr') && !withQr) continue;
      if (line.contains('@optional:map') && !withMap) continue;
      out.add(line);
    }
    return out.join('\n');
  }

  static String designSystemReadme() => generated.designSystemReadme;

  static String agentsBlock() => generated.agentsSnippet;
}
