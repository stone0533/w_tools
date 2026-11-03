import '../config.dart';
import '../suppression.dart';
import '../context.dart';
import '../rule.dart';

/// R2：业务代码直接 `import 'package:w_tools_*'`。
///
/// 聚合入口（[DoctorConfig.toolkitEntry]）本身除外 —— 它的职责就是 export 子包。
class R2DirectSubpackageImport {
  static const id = 'R2';
  static const title = '直连子包 import';

  static final _importPattern = RegExp(
    r"""^\s*(?:import|export)\s+['"]package:(w_tools(?:_[a-z0-9_]+)?)/""",
  );

  /// 只用于开发 / 验证的工具包：在 `test/` `tool/` `integration_test/` 里 import 是正常的。
  ///
  /// 典型场景：`tool/main_e2e.dart` 必须直接 import `package:w_tools_e2e/…`
  /// （见 docs/agents/device-testing.md），它不该由 toolkit 导出。
  static const devOnlyPackages = <String>{
    'w_tools_cli',
    'w_tools_figma',
    'w_tools_device',
    'w_tools_e2e',
  };

  /// 开发目录（只在这些目录里放行 [devOnlyPackages]）
  static bool _isDevPath(String file) =>
      file.startsWith('test/') || file.startsWith('tool/') || file.startsWith('integration_test/');

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final issues = <DoctorIssue>[];
    for (final file in ctx.files) {
      // 聚合入口自己就是靠 export 子包工作的
      if (file == config.toolkitEntry) continue;
      // 项目永久 UI 规范层与暂存层允许直接 import 子包
      if (file == projectUiDirPath ||
          file.startsWith('$projectUiDirPath/') ||
          file == designSystemDirPath ||
          file.startsWith('$designSystemDirPath/')) {
        continue;
      }
      final lines = ctx.read(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        final m = _importPattern.firstMatch(lines[i]);
        if (m == null) continue;
        if (Suppression.isIgnored(lines, i, id)) continue;
        final pkg = m.group(1)!;
        if (_isDevPath(file) && devOnlyPackages.contains(pkg)) continue;
        final isMeta = pkg == 'w_tools';
        issues.add(
          DoctorIssue(
            rule: id,
            level: DoctorLevel.error,
            file: file,
            line: i + 1,
            message: isMeta ? '直接 import/export 了聚合包 w_tools' : '直接 import/export 了 $pkg',
            hint: isMeta
                ? '改用具体子包（w_tools_ui / core / …）+ 聚合入口 ${config.toolkitEntry}'
                : '改用聚合入口（如 ${config.toolkitEntry}），换依赖方式时只改一处',
          ),
        );
      }
    }
    return DoctorRuleResult(
      ruleId: id,
      title: title,
      status: issues.isEmpty ? DoctorRuleStatus.pass : DoctorRuleStatus.fail,
      issues: issues,
    );
  }
}
