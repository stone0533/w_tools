import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R4：设计系统（`ui/` 与 `design_system/`）不得依赖业务。
///
/// 项目 UI 与待上移组件都必须保持与业务解耦；依赖 `data/` / `modules/` /
/// `routes/` / `services/` 的组件永远无法复用或上移。
class R4DesignSystemBoundary {
  static const id = 'R4';
  static const title = '设计系统 import 边界';

  static final _forbidden = RegExp(
    r"""import\s+['"][^'"]*\b(data|modules|routes|services)/""",
  );

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    const dirs = <String>{projectUiDirPath, designSystemDirPath};
    final issues = <DoctorIssue>[];
    var found = false;

    for (final dirPath in dirs) {
      final dir = Directory(p.join(ctx.root.path, dirPath));
      if (!dir.existsSync()) continue;
      found = true;
      for (final file in ctx.filesUnder(dirPath)) {
        final lines = ctx.read(file).split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trimLeft().startsWith('//')) continue;
          if (_forbidden.hasMatch(lines[i])) {
            issues.add(
              DoctorIssue(
                rule: id,
                level: DoctorLevel.error,
                file: file,
                line: i + 1,
                message: '设计系统组件 import 了业务层：${lines[i].trim()}',
                hint: '项目 UI / 暂存层只能依赖 dart/flutter/w_tools/get —— 依赖业务就无法复用或上移',
              ),
            );
          }
        }
      }
    }

    if (!found) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '项目里没有设计系统目录',
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
