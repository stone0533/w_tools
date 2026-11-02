import '../config.dart';
import '../context.dart';
import '../rule.dart';
import '../suppression.dart';

/// R9：项目级禁用 API。
///
/// 规则本身不认识任何业务 API；所有条目来自 `.w_tools_doctor.yaml` 的 `banned`。
/// 这样禁用清单只有一份来源，不会和文档手写清单漂移。
class R9BannedApi {
  static const id = 'R9';
  static const title = '项目禁用 API';

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    if (!config.enabledRules.contains(id)) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未启用（rules.R9: false）',
      );
    }
    if (config.banned.isEmpty) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '未配置 banned（可选）',
      );
    }

    final issues = <DoctorIssue>[];
    final seenErrors = <String>{};
    for (final entry in config.banned) {
      final error = entry.validate();
      if (error != null && seenErrors.add(error)) {
        issues.add(
          DoctorIssue(
            rule: id,
            level: DoctorLevel.error,
            file: DoctorConfig.fileName,
            message: error,
            hint: '修正 .w_tools_doctor.yaml 的 banned 配置',
          ),
        );
      }
    }

    for (final file in ctx.files) {
      final lines = ctx.read(file).split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;

        for (final entry in config.banned) {
          if (entry.validate() != null) continue;
          if (!entry.appliesTo(file)) continue;
          if (!entry.matches(line)) continue;
          if (Suppression.isIgnored(lines, i, id)) continue;

          final use = entry.use?.trim();
          final reason = entry.reason?.trim();
          issues.add(
            DoctorIssue(
              rule: id,
              level: entry.level,
              file: file,
              line: i + 1,
              message: '命中禁用 API：${entry.id}',
              hint: <String>[
                if (use != null && use.isNotEmpty) '改用：$use',
                if (reason != null && reason.isNotEmpty) '原因：$reason',
              ].join('；'),
            ),
          );
        }
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
