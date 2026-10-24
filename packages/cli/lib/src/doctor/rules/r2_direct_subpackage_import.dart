import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R2：业务代码直接 `import 'package:w_tools_*'`。
///
/// 聚合入口（[DoctorConfig.toolkitEntry]）本身除外 —— 它的职责就是 export 子包。
class R2DirectSubpackageImport {
  static const id = 'R2';
  static const title = '直连子包 import';

  static final _importPattern = RegExp(r"""^\s*import\s+['"]package:(w_tools(?:_[a-z]+)?)/""");

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final issues = <DoctorIssue>[];
    for (final file in ctx.files) {
      // 聚合入口自己就是靠 export 子包工作的
      if (file == config.toolkitEntry) continue;
      // 暂存层的组件将来要整体搬进包里，允许直接 import 子包
      if (file == config.designSystemDir || file.startsWith('${config.designSystemDir}/')) {
        continue;
      }
      final lines = ctx.read(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        final m = _importPattern.firstMatch(lines[i]);
        if (m == null) continue;
        final pkg = m.group(1)!;
        final isMeta = pkg == 'w_tools';
        issues.add(
          DoctorIssue(
            rule: id,
            level: DoctorLevel.error,
            file: file,
            line: i + 1,
            message: isMeta ? '直接 import 了聚合包 w_tools' : '直接 import 了 $pkg',
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
