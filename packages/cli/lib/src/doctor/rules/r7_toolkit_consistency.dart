import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

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

  static final _export = RegExp(r"""export\s+'package:(w_tools_[a-z]+)/""");

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final file = File(p.join(ctx.root.path, config.toolkitEntry));
    if (!file.existsSync()) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '没有 toolkit 入口（未运行 init）',
      );
    }

    final exports = _export.allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toSet();
    final deps = <String>{};
    final depsNode = ctx.pubspec['dependencies'];
    if (depsNode is YamlMap) {
      deps.addAll(depsNode.keys.map((e) => '$e').where((e) => e.startsWith('w_tools_')));
    }

    final issues = <DoctorIssue>[];
    for (final exported in exports.difference(deps)) {
      issues.add(
        DoctorIssue(
          rule: id,
          level: DoctorLevel.error,
          file: config.toolkitEntry,
          message: 'toolkit 导出了 $exported，但 pubspec 没有依赖它',
          hint: '在 pubspec.yaml 的 dependencies 里加 $exported，或删掉这行 export',
          fix: DoctorFix.edit(
            file: 'pubspec.yaml',
            path: 'dependencies.$exported',
            value: 'any',
          ),
        ),
      );
    }
    for (final dep in deps.difference(exports)) {
      if (dep == 'w_tools') continue;
      issues.add(
        DoctorIssue(
          rule: id,
          level: DoctorLevel.info,
          file: 'pubspec.yaml',
          message: '依赖了 $dep，但 toolkit 没有导出它',
          hint: '如果业务代码要用它，在 ${config.toolkitEntry} 里加一行 export',
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
