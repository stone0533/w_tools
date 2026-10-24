/// doctor 的问题级别。
enum DoctorLevel { error, warn, info }

/// 一条检查结果。
class DoctorIssue {
  const DoctorIssue({
    required this.rule,
    required this.level,
    required this.message,
    this.file,
    this.line,
    this.hint,
  });

  /// 规则 id，例如 `R1`
  final String rule;
  final DoctorLevel level;
  final String message;

  /// 相对项目根的路径
  final String? file;
  final int? line;

  /// 怎么改
  final String? hint;

  String get location => file == null ? '' : (line == null ? file! : '$file:$line');
}

/// 一条规则的执行结果（含「跳过」态）。
enum DoctorRuleStatus { pass, fail, skipped }

class DoctorRuleResult {
  const DoctorRuleResult({
    required this.ruleId,
    required this.title,
    required this.status,
    this.issues = const <DoctorIssue>[],
    this.skipReason,
  });

  final String ruleId;
  final String title;
  final DoctorRuleStatus status;
  final List<DoctorIssue> issues;
  final String? skipReason;
}
