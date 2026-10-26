/// doctor 的问题级别。
enum DoctorLevel { error, warn, info }

/// 结构化的修复动作，供 AI / 工具直接执行。
class DoctorFix {
  const DoctorFix.run(this.command) : kind = 'run', file = null, path = null, value = null;

  const DoctorFix.edit({required this.file, required this.path, this.value})
    : kind = 'edit',
      command = null;

  /// 目前只有 `run`（执行命令）与 `edit`（改 YAML 字段）。
  final String kind;
  final String? command;
  final String? file;
  final String? path;

  /// `edit` 的目标值；`null` 表示删除该 key。
  final Object? value;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    if (command != null) 'command': command,
    if (file != null) 'file': file,
    if (path != null) 'path': path,
    if (kind == 'edit') 'value': value,
  };
}

/// 一条检查结果。
class DoctorIssue {
  const DoctorIssue({
    required this.rule,
    required this.level,
    required this.message,
    this.file,
    this.line,
    this.hint,
    this.fix,
  });

  /// 规则 id，例如 `R1`
  final String rule;
  final DoctorLevel level;
  final String message;

  /// 相对项目根的路径
  final String? file;
  final int? line;

  /// 怎么改（人读）
  final String? hint;

  /// 机器可执行的修复（可选）
  final DoctorFix? fix;

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
