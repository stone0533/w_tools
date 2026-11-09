import 'config.dart';
import 'context.dart';
import 'rule.dart';
import 'rules/r1_meta_dependency.dart';
import 'rules/r2_direct_subpackage_import.dart';
import 'rules/r3_hardcoded_colors.dart';
import 'rules/r4_design_system_boundary.dart';
import 'rules/r5_staged_marker.dart';
import 'rules/r6_banned_units.dart';
import 'rules/r7_toolkit_consistency.dart';
import 'rules/r8_generated_stale.dart';
import 'rules/r9_banned_api.dart';

/// 一条规则的元数据 + 执行函数。
///
/// 新增规则只改这一处 + 规则文件；`doctor`、`context`、`--only` 都从这里派生，
/// 不再维护 ids / levels / checks 三份表。
class DoctorRule {
  const DoctorRule({
    required this.id,
    required this.title,
    required this.level,
    required this.summaryZh,
    required this.summaryEn,
    required this.check,
  });

  final String id;
  final String title;
  final DoctorLevel level;
  final String summaryZh;
  final String summaryEn;
  final DoctorRuleResult Function(ProjectContext, DoctorConfig) check;
}

const List<DoctorRule> doctorRules = <DoctorRule>[
  DoctorRule(
    id: R1MetaDependency.id,
    title: R1MetaDependency.title,
    level: DoctorLevel.error,
    summaryZh: '聚合包依赖',
    summaryEn: 'Aggregate package dependency',
    check: R1MetaDependency.check,
  ),
  DoctorRule(
    id: R2DirectSubpackageImport.id,
    title: R2DirectSubpackageImport.title,
    level: DoctorLevel.error,
    summaryZh: '直连子包 import',
    summaryEn: 'Direct subpackage import',
    check: R2DirectSubpackageImport.check,
  ),
  DoctorRule(
    id: R3HardcodedColors.id,
    title: R3HardcodedColors.title,
    level: DoctorLevel.warn,
    summaryZh: '硬编码语义色',
    summaryEn: 'Hardcoded semantic colors',
    check: R3HardcodedColors.check,
  ),
  DoctorRule(
    id: R4DesignSystemBoundary.id,
    title: R4DesignSystemBoundary.title,
    level: DoctorLevel.error,
    summaryZh: '设计系统边界',
    summaryEn: 'Design-system boundary',
    check: R4DesignSystemBoundary.check,
  ),
  DoctorRule(
    id: R5StagedMarker.id,
    title: R5StagedMarker.title,
    level: DoctorLevel.warn,
    summaryZh: 'STAGED 标记',
    summaryEn: 'STAGED marker',
    check: R5StagedMarker.check,
  ),
  DoctorRule(
    id: R6BannedUnits.id,
    title: R6BannedUnits.title,
    level: DoctorLevel.warn,
    summaryZh: '禁用 .h / .r',
    summaryEn: 'Banned .h / .r units',
    check: R6BannedUnits.check,
  ),
  DoctorRule(
    id: R7ToolkitConsistency.id,
    title: R7ToolkitConsistency.title,
    level: DoctorLevel.error,
    summaryZh: 'toolkit 一致性',
    summaryEn: 'Toolkit consistency',
    check: R7ToolkitConsistency.check,
  ),
  DoctorRule(
    id: R8GeneratedStale.id,
    title: R8GeneratedStale.title,
    level: DoctorLevel.warn,
    summaryZh: '生成物版本',
    summaryEn: 'Generated-file version',
    check: R8GeneratedStale.check,
  ),
  DoctorRule(
    id: R9BannedApi.id,
    title: R9BannedApi.title,
    level: DoctorLevel.warn,
    summaryZh: '项目禁用 API',
    summaryEn: 'Project-banned APIs',
    check: R9BannedApi.check,
  ),
];

final List<String> doctorRuleIds = <String>[for (final r in doctorRules) r.id];

final Map<String, String> doctorRuleLevels = <String, String>{
  for (final r in doctorRules) r.id: r.level.name,
};

/// 未在 `rules` 中启用的规则统一用这个理由。
const String doctorDisabledSkipReason = '未在 rules 中启用';

/// 跑全部规则，或只跑 [only]。
///
/// 未启用的规则**不执行检查**，但仍以 [DoctorRuleStatus.skipped] 出现在结果里：
/// 读 JSON / Markdown 的一方必须能区分「规则没启用」和「规则不存在」。
/// 只按 [only] 过滤时，点名的未启用规则同样返回一条 skipped。
List<DoctorRuleResult> runDoctor(ProjectContext ctx, DoctorConfig config, {Set<String>? only}) {
  final enabled = config.enabledRules;
  return <DoctorRuleResult>[
    for (final rule in doctorRules)
      if (only == null || only.contains(rule.id))
        if (enabled.contains(rule.id))
          rule.check(ctx, config)
        else
          DoctorRuleResult(
            ruleId: rule.id,
            title: rule.title,
            status: DoctorRuleStatus.skipped,
            skipReason: doctorDisabledSkipReason,
          ),
  ];
}
