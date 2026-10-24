import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';
import '../context.dart';
import '../rule.dart';

/// R4：暂存层（`design_system/`）不得依赖业务。
///
/// 依赖了 `data/` / `modules/` / `routes/` / `services/` 的组件**永远上移不进包**。
class R4DesignSystemBoundary {
  static const id = 'R4';
  static const title = '暂存层 import 边界';

  static final _forbidden = RegExp(
    r"""import\s+['"][^'"]*\b(data|modules|routes|services)/""",
  );

  static DoctorRuleResult check(ProjectContext ctx, DoctorConfig config) {
    final dir = Directory(p.join(ctx.root.path, config.designSystemDir));
    if (!dir.existsSync()) {
      return const DoctorRuleResult(
        ruleId: id,
        title: title,
        status: DoctorRuleStatus.skipped,
        skipReason: '项目里没有暂存层目录',
      );
    }

    final issues = <DoctorIssue>[];
    for (final file in ctx.filesUnder(config.designSystemDir)) {
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
              message: '暂存层组件 import 了业务层：${lines[i].trim()}',
              hint: '暂存层只能依赖 dart/flutter/w_tools/get —— 依赖业务就永远上移不了',
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
