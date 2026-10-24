import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R6：项目专用 —— 禁用尺寸单位 `.h` / `.r`。
///
/// 默认**不启用**（这是某个项目的规范，不是 w_tools 的通用规则）；
/// 在 `.w_tools_doctor.yaml` 里用 `rules: { R6: true }` 打开。
class R6BannedUnits {
  static const id = 'R6';
  static const title = '禁用尺寸单位';

  static final _pattern = RegExp(r'\b\d+(\.\d+)?\.(h|r)\b');

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    if (!config.enabledRules.contains(id)) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未启用（项目专用规则，在配置 rules.R6: true 打开）',
      );
    }

    final issues = <DoctorIssue>[];
    for (final file in ctx.files) {
      final lines = ctx.read(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        final m = _pattern.firstMatch(lines[i]);
        if (m == null) continue;
        issues.add(
          DoctorIssue(
            rule: id,
            level: DoctorLevel.warn,
            file: file,
            line: i + 1,
            message: '使用了 .${m.group(2)} 单位',
            hint: '只用 .w / .sp / .sw / .sh',
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
