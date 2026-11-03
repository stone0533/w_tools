import '../config.dart';
import '../context.dart';
import '../rule.dart';
import '../suppression.dart';

/// R5：暂存层文件缺少 `// STAGED:` 标记。
class R5StagedMarker {
  static const id = 'R5';
  static const title = '暂存层 STAGED 标记';

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final facts = ctx.facts;
    if (!facts.hasStagingDirectory) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '项目里没有暂存层目录',
      );
    }

    final issues = <DoctorIssue>[];
    for (final file in facts.missingStagedFiles) {
      final lines = ctx.read(file).split('\n');
      if (Suppression.isFileIgnored(lines, id)) continue;
      issues.add(
        DoctorIssue(
          rule: id,
          level: DoctorLevel.warn,
          file: file,
          message: '前 10 行没有 // STAGED: 标记',
          hint: '加上 // STAGED: 待上移到 w_tools_ui，方便统计还有多少没上移',
        ),
      );
    }

    return DoctorRuleResult(
      ruleId: id,
      title: title,
      status: issues.isEmpty ? DoctorRuleStatus.pass : DoctorRuleStatus.fail,
      issues: issues,
    );
  }
}
