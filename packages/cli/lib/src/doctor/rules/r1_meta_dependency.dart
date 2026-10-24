import 'package:yaml/yaml.dart';

import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R1：`dependencies` 里出现聚合包 `w_tools`（会拖进 google_maps_flutter）。
///
/// `dev_dependencies` 里的不算（doctor 自己就靠它引入）；
/// `dependency_overrides` 里出现只给 warn（开发期合法）。
class R1MetaDependency {
  static const id = 'R1';
  static const title = '聚合包依赖';

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final issues = <DoctorIssue>[];

    final deps = ctx.pubspec['dependencies'];
    if (deps is YamlMap && deps.containsKey('w_tools')) {
      issues.add(
        const DoctorIssue(
          rule: id,
          level: DoctorLevel.error,
          file: 'pubspec.yaml',
          message: 'dependencies 里出现聚合包 w_tools：它会拖进 w_tools_map 的 google_maps_flutter 原生 SDK',
          hint: '改成具体子包（w_tools_core / ui / form / app / api / toast）；需要地图才加 w_tools_map',
        ),
      );
    }

    final overrides = ctx.pubspec['dependency_overrides'];
    if (overrides is YamlMap && overrides.containsKey('w_tools')) {
      issues.add(
        const DoctorIssue(
          rule: id,
          level: DoctorLevel.warn,
          file: 'pubspec.yaml',
          message: 'dependency_overrides 里出现了聚合包 w_tools（开发期临时覆盖请记得删除）',
          hint: '开发期建议只覆盖具体子包，例如 w_tools_ui: path: …',
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
