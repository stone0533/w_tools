import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/doctor/context.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';
import 'package:w_tools_cli/src/doctor/rules/r1_meta_dependency.dart';
import 'package:w_tools_cli/src/doctor/rules/r2_direct_subpackage_import.dart';
import 'package:w_tools_cli/src/doctor/rules/r3_hardcoded_colors.dart';
import 'package:w_tools_cli/src/doctor/rules/r4_design_system_boundary.dart';
import 'package:w_tools_cli/src/doctor/rules/r5_staged_marker.dart';
import 'package:w_tools_cli/src/doctor/rules/r6_banned_units.dart';
import 'package:w_tools_cli/src/doctor/rules/r7_toolkit_consistency.dart';
import 'package:w_tools_cli/src/doctor/rules/r8_generated_stale.dart';

/// 每个用例在临时目录里造一个最小「消费方项目」。
Directory makeProject(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('wt_doctor_');
  files.forEach((rel, content) {
    final f = File(p.join(root.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });
  return root;
}

ProjectContext ctxOf(Directory root, DoctorConfig config) =>
    ProjectContext.load(root, config, includeTests: true);

void main() {
  group('R1 依赖聚合包', () {
    test('dependencies 里有 w_tools → error', () {
      final root = makeProject({
        'pubspec.yaml':
            'name: demo\ndependencies:\n  w_tools: ^2.0.0\n  flutter:\n    sdk: flutter\n',
      });
      final r = R1MetaDependency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.fail);
      expect(r.issues.single.level, DoctorLevel.error);
      expect(r.issues.single.fix?.kind, 'edit');
      expect(r.issues.single.fix?.path, 'dependencies.w_tools');
    });

    test('只在 dev_dependencies 里有 → 通过（doctor 自己就靠它）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\ndev_dependencies:\n  w_tools: ^2.0.0\n',
      });
      final r = R1MetaDependency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('dependency_overrides 里有 → 只 warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\ndependency_overrides:\n  w_tools:\n    path: ../x\n',
      });
      final r = R1MetaDependency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.level, DoctorLevel.warn);
    });
  });

  group('R2 直连子包', () {
    test('业务文件 import 子包 → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.file, 'lib/app/foo.dart');
    });

    test('直接 import 聚合包 → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "import 'package:w_tools/w.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.message, contains('聚合包'));
    });

    test('注释里的 import 不算', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "// import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('项目 ui 目录 import 子包 → 通过（项目永久 UI 规范）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/ui/app_scaffold.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('暂存层 import 子包 → 通过（将来要整体上移，允许直连）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('聚合入口自己 import 子包 → 通过', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/w/toolkit.dart': "export 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });
  });

  group('R3 硬编码语义色', () {
    DoctorConfig configured() => DoctorConfig(palette: <String>['#3F3F3F'], colorMinCount: 3);

    test('没配调色板 → 跳过', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n'});
      final r = R3HardcodedColors.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.skipped);
    });

    test('达到阈值 → warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart':
            "const c = Color(0xFF3F3F3F);\nconst d = Color(0xFF3F3F3F);\n"
            "const e = Color(0xFF3F3F3F);\n",
      });
      final r = R3HardcodedColors.check(ctxOf(root, configured()), configured());
      expect(r.issues.single.level, DoctorLevel.warn);
    });

    test('8 位十六进制调色板（带 AA）能归一化匹配', () {
      final config = DoctorConfig(palette: const ['#AA3F3F3F'], colorMinCount: 3);
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart':
            'const c = Color(0xFF3F3F3F);\n'
            'const d = Color(0xFF3F3F3F);\n'
            'const e = Color(0xFF3F3F3F);\n',
      });
      final r = R3HardcodedColors.check(ctxOf(root, config), config);
      expect(r.issues.single.level, DoctorLevel.warn);
    });

    test('低于阈值 → 不报', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': "const c = Color(0xFF3F3F3F);\n",
      });
      final r = R3HardcodedColors.check(ctxOf(root, configured()), configured());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('项目 ui 里的固定品牌色不报', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/ui/app_boxes.dart':
            "const a = Color(0xFF3F3F3F);\nconst b = Color(0xFF3F3F3F);\nconst c = Color(0xFF3F3F3F);\n",
      });
      final r = R3HardcodedColors.check(ctxOf(root, configured()), configured());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('暂存层里的硬编码不报（还没上移）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart':
            "const a = Color(0xFF3F3F3F);\nconst b = Color(0xFF3F3F3F);\nconst c = Color(0xFF3F3F3F);\n",
      });
      final r = R3HardcodedColors.check(ctxOf(root, configured()), configured());
      expect(r.status, DoctorRuleStatus.pass);
    });
  });

  group('R4 / R5 暂存层', () {
    test('暂存层 import data/ → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart': "import '../data/foo.dart';\n",
      });
      final config = DoctorConfig();
      final r = R4DesignSystemBoundary.check(ctxOf(root, config), config);
      expect(r.issues.single.level, DoctorLevel.error);
    });

    test('项目 ui import data/ → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/ui/widget.dart': "import '../data/foo.dart';\n",
      });
      final config = DoctorConfig();
      final r = R4DesignSystemBoundary.check(ctxOf(root, config), config);
      expect(r.issues.single.file, 'lib/app/ui/widget.dart');
    });

    test('只有项目 ui、没有暂存层时仍会检查', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/ui/widget.dart': '# project ui\n',
      });
      final config = DoctorConfig();
      final r = R4DesignSystemBoundary.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('metadata/、my_services/ 不误报', () {
      for (final path in <String>[
        'package:foo/metadata/x.dart',
        'package:foo/my_services/x.dart',
      ]) {
        final root = makeProject({
          'pubspec.yaml': 'name: demo\n',
          'lib/app/design_system/x.dart': "import '$path';\n",
        });
        final config = DoctorConfig();
        final r = R4DesignSystemBoundary.check(ctxOf(root, config), config);
        expect(r.status, DoctorRuleStatus.pass, reason: path);
      }
    });

    test('STAGED 标记在第 6-10 行也算（放宽后）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart':
            '// 1\n// 2\n// 3\n// 4\n// 5\n// 6\n// STAGED: 待上移\nclass X {}\n',
      });
      final config = DoctorConfig();
      final r = R5StagedMarker.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('暂存层 README 不算缺 STAGED 标记', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/README.md': '# staging\n',
      });
      final r = R5StagedMarker.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('暂存层缺 STAGED 标记 → warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart': "// 没有标记\nclass X {}\n",
      });
      final config = DoctorConfig();
      final r = R5StagedMarker.check(ctxOf(root, config), config);
      expect(r.issues.single.level, DoctorLevel.warn);
    });

    test('没有暂存层目录 → 跳过（而不是通过）', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n'});
      final config = DoctorConfig();
      expect(
        R4DesignSystemBoundary.check(ctxOf(root, config), config).status,
        DoctorRuleStatus.skipped,
      );
      expect(R5StagedMarker.check(ctxOf(root, config), config).status, DoctorRuleStatus.skipped);
    });
  });

  group('R7 toolkit 一致性', () {
    test('export 了未依赖的包 → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\ndependencies:\n  w_tools_ui: ^1.1.0\n',
        'lib/app/w/toolkit.dart':
            "export 'package:w_tools_ui/w_tools_ui.dart';\n"
            "export 'package:w_tools_core/w_tools_core.dart';\n",
      });
      final r = R7ToolkitConsistency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      final error = r.issues.singleWhere((i) => i.level == DoctorLevel.error);
      expect(error.message, contains('w_tools_core'));
      expect(error.fix?.kind, 'edit');
      expect(error.fix?.path, 'dependencies.w_tools_core');
      expect(error.fix?.value, 'any');
    });

    test('依赖了但没导出的包 → info', () {
      final root = makeProject({
        'pubspec.yaml':
            'name: demo\ndependencies:\n'
            '  w_tools_ui: ^1.1.0\n  w_tools_core: ^1.0.1\n',
        'lib/app/w/toolkit.dart': "export 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R7ToolkitConsistency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.level, DoctorLevel.info);
      expect(r.issues.single.message, contains('w_tools_core'));
    });
  });

  group('R8 生成物版本', () {
    test('版本不一致 → warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'pubspec.lock': 'packages:\n  w_tools_cli:\n    version: "1.0.1"\n',
        'lib/app/w/toolkit.dart': '// generated by w_tools_cli 1.0.0\n',
      });
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.level, DoctorLevel.warn);
      expect(r.issues.single.message, contains('1.0.1'));
      expect(r.issues.single.fix?.command, contains('init --force'));
    });

    test('AGENTS 缺版本标记 → warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'pubspec.lock': 'packages:\n  w_tools_cli:\n    version: "1.0.0"\n',
        'AGENTS.md': '# 说明\n<!-- w_tools:begin -->\n<!-- w_tools:end -->\n',
      });
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.message, contains('版本标记'));
    });

    test('手写的 target 文件（无 w_tools 标记）→ 跳过', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'pubspec.lock': 'packages:\n  w_tools_cli:\n    version: "1.0.0"\n',
        'CLAUDE.md': '# 我自己的规则\n',
      });
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.skipped);
    });

    test('没有 w_tools_cli 的 lock → 跳过', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n'});
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.skipped);
    });
  });

  group('R6 禁用单位', () {
    test('默认不启用 → 跳过', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n', 'lib/a.dart': 'final x = 12.h;\n'});
      final r = R6BannedUnits.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.skipped);
    });

    test('启用后 → warn（项目专用，--strict 才失败）', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n', 'lib/a.dart': 'final x = 12.h;\n'});
      final config = DoctorConfig(enabledRules: <String>{'R6'});
      final r = R6BannedUnits.check(ctxOf(root, config), config);
      expect(r.issues.single.line, 1);
      expect(r.issues.single.level, DoctorLevel.warn);
    });

    test('注释里的 .h 不算', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n', 'lib/a.dart': '// 旧单位 12.h\n'});
      final config = DoctorConfig(enabledRules: <String>{'R6'});
      final r = R6BannedUnits.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });
  });
}
