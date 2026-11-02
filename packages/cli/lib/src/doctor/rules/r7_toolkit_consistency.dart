import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R7：toolkit 入口的 export 与 pubspec 依赖不一致。
///
/// AI 最容易犯的错：在 toolkit 里加了一个 `export`，但 pubspec 没加对应子包；
/// 或者删了依赖却忘了删 export（项目从此编译不过）。
class R7ToolkitConsistency {
  static const id = 'R7';
  static const title = 'toolkit 与依赖一致';

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final facts = ctx.facts;
    if (facts.toolkitPath == null) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '没有 toolkit 入口（未运行 init）',
      );
    }

    final exports = facts.toolkitExports.toSet();
    final deps = facts.subpackageDependencies.toSet();
    final toolkitEntry = facts.toolkitPath!;

    final issues = <DoctorIssue>[
      for (final exported in exports.difference(deps))
        DoctorIssue(
          rule: id,
          level: DoctorLevel.error,
          file: toolkitEntry,
          message: 'toolkit 导出了 $exported，但 pubspec 没有依赖它',
          hint: '在 pubspec.yaml 的 dependencies 里加 $exported，或删掉这行 export',
          fix: DoctorFix.edit(
            file: 'pubspec.yaml',
            path: 'dependencies.$exported',
            value: 'any',
          ),
        ),
      for (final dep in deps.difference(exports))
        DoctorIssue(
          rule: id,
          level: DoctorLevel.info,
          file: 'pubspec.yaml',
          message: '依赖了 $dep，但 toolkit 没有导出它',
          hint: '如果业务代码要用它，在 $toolkitEntry 里加一行 export',
        ),
    ];

    return DoctorRuleResult(
      ruleId: id,
      title: title,
      status: issues.isEmpty ? DoctorRuleStatus.pass : DoctorRuleStatus.fail,
      issues: issues,
    );
  }
}
