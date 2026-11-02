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
    required this.check,
  });

  final String id;
  final String title;
  final DoctorLevel level;
  final DoctorRuleResult Function(ProjectContext, DoctorConfig) check;
}

const List<DoctorRule> doctorRules = <DoctorRule>[
  DoctorRule(
    id: R1MetaDependency.id,
    title: R1MetaDependency.title,
    level: DoctorLevel.error,
    check: R1MetaDependency.check,
  ),
  DoctorRule(
    id: R2DirectSubpackageImport.id,
    title: R2DirectSubpackageImport.title,
    level: DoctorLevel.error,
    check: R2DirectSubpackageImport.check,
  ),
  DoctorRule(
    id: R3HardcodedColors.id,
    title: R3HardcodedColors.title,
    level: DoctorLevel.warn,
    check: R3HardcodedColors.check,
  ),
  DoctorRule(
    id: R4DesignSystemBoundary.id,
    title: R4DesignSystemBoundary.title,
    level: DoctorLevel.error,
    check: R4DesignSystemBoundary.check,
  ),
  DoctorRule(
    id: R5StagedMarker.id,
    title: R5StagedMarker.title,
    level: DoctorLevel.warn,
    check: R5StagedMarker.check,
  ),
  DoctorRule(
    id: R6BannedUnits.id,
    title: R6BannedUnits.title,
    level: DoctorLevel.warn,
    check: R6BannedUnits.check,
  ),
  DoctorRule(
    id: R7ToolkitConsistency.id,
    title: R7ToolkitConsistency.title,
    level: DoctorLevel.error,
    check: R7ToolkitConsistency.check,
  ),
  DoctorRule(
    id: R8GeneratedStale.id,
    title: R8GeneratedStale.title,
    level: DoctorLevel.warn,
    check: R8GeneratedStale.check,
  ),
  DoctorRule(
    id: R9BannedApi.id,
    title: R9BannedApi.title,
    level: DoctorLevel.warn,
    check: R9BannedApi.check,
  ),
];

final List<String> doctorRuleIds = <String>[for (final r in doctorRules) r.id];

final Map<String, String> doctorRuleLevels = <String, String>{
  for (final r in doctorRules) r.id: r.level.name,
};

/// 跑全部规则，或只跑 [only]。
List<DoctorRuleResult> runDoctor(ProjectContext ctx, DoctorConfig config, {Set<String>? only}) {
  final selected = only == null
      ? doctorRules
      : doctorRules.where((r) => only.contains(r.id)).toList();
  return <DoctorRuleResult>[
    for (final rule in selected) rule.check(ctx, config),
  ];
}

/// AGENTS 规则速查表用的短描述：[zh, en]。
const Map<String, List<String>> doctorRuleSummaries = <String, List<String>>{
  'R1': <String>['聚合包依赖', 'Aggregate package dependency'],
  'R2': <String>['直连子包 import', 'Direct subpackage import'],
  'R3': <String>['硬编码语义色', 'Hardcoded semantic colors'],
  'R4': <String>['设计系统边界', 'Design-system boundary'],
  'R5': <String>['STAGED 标记', 'STAGED marker'],
  'R6': <String>['禁用 .h / .r（默认关）', 'Banned .h / .r units (opt-in)'],
  'R7': <String>['toolkit 一致性', 'Toolkit consistency'],
  'R8': <String>['生成物版本', 'Generated-file version'],
  'R9': <String>['项目禁用 API（配置驱动）', 'Project-banned APIs (configured)'],
};
