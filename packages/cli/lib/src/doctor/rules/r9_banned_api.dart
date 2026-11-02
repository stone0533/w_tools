import '../banned_rule.dart';
import '../config.dart';
import '../context.dart';
import '../rule.dart';
import '../suppression.dart';
import '../text_scan.dart';

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
    final validEntries = <BannedRule>[];
    for (final entry in config.banned) {
      final error = entry.validate();
      if (error == null) {
        validEntries.add(entry);
        continue;
      }
      if (seenErrors.add(error)) {
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

    for (final file in TextScan.files(ctx)) {
      for (final line in file.codeLines) {
        for (final entry in validEntries) {
          if (!entry.appliesTo(file.path)) continue;
          if (!entry.matches(line.text)) continue;
          if (Suppression.isIgnored(file.lines, line.index, id)) continue;

          final use = entry.use?.trim();
          final reason = entry.reason?.trim();
          issues.add(
            DoctorIssue(
              rule: id,
              level: entry.level,
              file: file.path,
              line: line.lineNumber,
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
