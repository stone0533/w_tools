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
import 'package:w_tools_cli/src/doctor/run.dart';

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
      expect(r.issues.single.message, isNot(contains('w_tools_map')));
      expect(r.issues.single.hint, contains('w_tools_map_google'));
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

    test('tool/ 里 import dev-only 工具包不报 R2', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'tool/main_e2e.dart': "import 'package:w_tools_e2e/w_tools_e2e.dart';\n",
        'test/x_test.dart': "import 'package:w_tools_device/w_tools_device.dart';\n",
        'integration_test/app_test.dart': "import 'package:w_tools_e2e/w_tools_e2e.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('lib/ 里 import dev-only 工具包仍然报 R2', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/tool.dart': "import 'package:w_tools_device/w_tools_device.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.fail);
    });

    test('行级 ignore R2 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart':
            '// w_tools:ignore R2 reason: migration bridge\n'
            "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('ignore 缺 reason 不生效（R2）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart':
            '// w_tools:ignore R2\n'
            "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.fail);
    });

    test('文件级 ignore-file R2 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart':
            '// w_tools:ignore-file R2 reason: generated bridge\n'
            "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('包名带数字的子包也能命中（w_tools_e2e）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "import 'package:w_tools_e2e/e2e.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.message, contains('w_tools_e2e'));
    });

    test('直接 import 聚合包 → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "import 'package:w_tools/w_tools.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.message, contains('聚合包'));
    });

    test('业务文件 export 子包 → error', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/foo.dart': "export 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      final r = R2DirectSubpackageImport.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.issues.single.file, 'lib/app/foo.dart');
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

  test('R3 行尾注释里的颜色不计入阈值', () {
    final root = makeProject({
      'lib/a.dart':
          'const c = Color(0xFF3F3F3F); // Color(0xFF3F3F3F)\n'
          '// Color(0xFF3F3F3F)\n'
          '// Color(0xFF3F3F3F)\n',
    });
    final config = DoctorConfig.parse('colors:\n  palette: ["#3F3F3F"]\n  min_count: 3\n');
    final r = R3HardcodedColors.check(ctxOf(root, config), config);
    expect(r.status, DoctorRuleStatus.pass);
  });

  test('R3 被忽略的命中不参与阈值', () {
    final root = makeProject({
      'lib/a.dart':
          '// w_tools:ignore R3 reason: legacy color\n'
          'const a = Color(0xFF3F3F3F);\n'
          'const b = Color(0xFF3F3F3F);\n',
    });
    final config = DoctorConfig.parse('colors:\n  palette: ["#3F3F3F"]\n  min_count: 2\n');
    final r = R3HardcodedColors.check(ctxOf(root, config), config);
    expect(r.status, DoctorRuleStatus.pass);
  });

  test('R3 单处命中 + 行级 ignore 不报', () {
    final root = makeProject({
      'lib/a.dart':
          '// w_tools:ignore R3 reason: legacy color\n'
          'const a = Color(0xFF3F3F3F);\n',
    });
    final config = DoctorConfig.parse(
      'colors:\n  palette: ["#3F3F3F"]\n  min_count: 1\n',
    );
    final r = R3HardcodedColors.check(ctxOf(root, config), config);
    expect(r.status, DoctorRuleStatus.pass);
  });

  test('R4 行尾注释里的业务 import 不算', () {
    final root = makeProject({
      'lib/app/ui/a.dart': 'void main() {} // import \'data/x.dart\';\n',
    });
    final r = R4DesignSystemBoundary.check(ctxOf(root, DoctorConfig()), DoctorConfig());
    expect(r.status, DoctorRuleStatus.pass);
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

    test('行级 ignore R4 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart':
            '// w_tools:ignore R4 reason: migration\n'
            "import '../data/foo.dart';\n",
      });
      final r = R4DesignSystemBoundary.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
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

    test('文件级 ignore-file R5 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/app/design_system/x.dart':
            '// w_tools:ignore-file R5 reason: migration\n'
            'class X {}\n',
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
      expect(error.fix?.value, '^3.1.1');
    });

    test('文件级 ignore-file R7 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\ndependencies:\n  w_tools_ui: ^1.1.0\n',
        'lib/app/w/toolkit.dart':
            '// w_tools:ignore-file R7 reason: migration\n'
            "export 'package:w_tools_ui/w_tools_ui.dart';\n"
            "export 'package:w_tools_core/w_tools_core.dart';\n",
      });
      final r = R7ToolkitConsistency.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.pass);
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

    test('文件级 ignore-file R8 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'pubspec.lock': 'packages:\n  w_tools_cli:\n    version: "1.0.0"\n',
        'lib/app/w/toolkit.dart':
            '// w_tools:ignore-file R8 reason: pinned generated file\n'
            '// generated by w_tools_cli 0.9.0\n',
      });
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.skipped);
    });

    test('AI_PROMPTS 版本不一致 → warn', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'pubspec.lock': 'packages:\n  w_tools_cli:\n    version: "1.0.0"\n',
        '.w_tools/AI_PROMPTS.md': '> 由 `w_tools_cli` v0.9.0（生成器版本）生成；重新生成请运行 init --force。\n',
      });
      final r = R8GeneratedStale.check(ctxOf(root, DoctorConfig()), DoctorConfig());
      expect(r.status, DoctorRuleStatus.fail);
      expect(r.issues.single.file, '.w_tools/AI_PROMPTS.md');
      expect(r.issues.single.message, contains('0.9.0'));
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

    test('行级 ignore R6 生效', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart':
            '// w_tools:ignore R6 reason: legacy unit\n'
            'final x = 12.h;\n',
      });
      final config = DoctorConfig(enabledRules: <String>{'R6'});
      final r = R6BannedUnits.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('行尾注释里的 .h 不算', () {
      final root = makeProject({
        'lib/a.dart': 'final x = 10; // 这里只是提到 .h\n',
      });
      final config = DoctorConfig.parse('rules:\n  R6: true\n');
      final r = R6BannedUnits.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });

    test('注释里的 .h 不算', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n', 'lib/a.dart': '// 旧单位 12.h\n'});
      final config = DoctorConfig(enabledRules: <String>{'R6'});
      final r = R6BannedUnits.check(ctxOf(root, config), config);
      expect(r.status, DoctorRuleStatus.pass);
    });
  });

  group('配置与文本扫描边界', () {
    test('rules: R2 false 真正关闭 R2（以 skipped 出现但不报问题）', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig.parse('rules:\n  R2: false\n');
      final results = runDoctor(ctxOf(root, config), config);
      final r2 = results.singleWhere((r) => r.ruleId == 'R2');
      expect(r2.status, DoctorRuleStatus.skipped);
      expect(r2.skipReason, doctorDisabledSkipReason);
      expect(r2.issues, isEmpty);
    });

    test('块注释里的 import 不算 R2', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': "/*\nimport 'package:w_tools_ui/w_tools_ui.dart';\n*/\nvoid main() {}\n",
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig();
      final result = R2DirectSubpackageImport.check(ctxOf(root, config), config);
      expect(result.status, DoctorRuleStatus.pass);
    });

    test('raw string 里的 import 不算 R2', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': "const s = r'''import 'package:w_tools_ui/w_tools_ui.dart';''';\n",
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig();
      final result = R2DirectSubpackageImport.check(ctxOf(root, config), config);
      expect(result.status, DoctorRuleStatus.pass);
    });

    test('ignore 支持 **/generated/**', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a/generated/x.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
        'lib/b.dart': 'void main() {}\n',
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig(ignore: const ['**/generated/**']);
      final ctx = ctxOf(root, config);
      expect(ctx.files, isNot(contains('lib/a/generated/x.dart')));
      expect(ctx.files, contains('lib/b.dart'));
    });

    test('R3 识别 8 位 alpha 颜色', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart':
            'final a = Color(0x803F3F3F);\n'
            'final b = Color(0x803F3F3F);\n'
            'final c = Color(0x803F3F3F);\n',
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig(palette: const ['#3F3F3F'], colorMinCount: 3);
      final result = R3HardcodedColors.check(ctxOf(root, config), config);
      expect(result.issues, isNotEmpty);
    });
  });

  group('规则列表一致性（未启用规则不消失）', () {
    test('默认关闭的 R6 以 skipped 出现，并带 skipReason', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': 'final x = 12.h;\n',
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig();
      final r6 = runDoctor(ctxOf(root, config), config).singleWhere((r) => r.ruleId == 'R6');
      expect(r6.status, DoctorRuleStatus.skipped);
      expect(r6.skipReason, isNotEmpty);
      expect(r6.issues, isEmpty);
    });

    test('显式关闭的规则同样以 skipped 出现，不再整个缺失', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n'});
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig.parse('rules:\n  R2: false\n');
      final r2 = runDoctor(ctxOf(root, config), config).singleWhere((r) => r.ruleId == 'R2');
      expect(r2.status, DoctorRuleStatus.skipped);
      expect(r2.issues, isEmpty);
    });

    test('未启用规则不执行检查：禁用 R2 时直连 import 不报问题', () {
      final root = makeProject({
        'pubspec.yaml': 'name: demo\n',
        'lib/a.dart': "import 'package:w_tools_ui/w_tools_ui.dart';\n",
      });
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig.parse('rules:\n  R2: false\n');
      final results = runDoctor(ctxOf(root, config), config);
      expect(results.expand((r) => r.issues), isEmpty);
    });

    test('每条内置规则都有结果，--only 仍只返回点名的规则', () {
      final root = makeProject({'pubspec.yaml': 'name: demo\n'});
      addTearDown(() => root.deleteSync(recursive: true));
      final config = DoctorConfig();
      final all = runDoctor(ctxOf(root, config), config);
      expect(all.map((r) => r.ruleId), unorderedEquals(doctorRuleIds));
      final only = runDoctor(ctxOf(root, config), config, only: {'R1'});
      expect(only.map((r) => r.ruleId), ['R1']);
    });
  });
}
