import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/doctor/banned_rule.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/templates.dart';

import '../../tool/agent_budget.dart';
import '../../tool/gen_templates.dart';

/// 漂移守卫：`lib/src/init/templates.g.dart` 必须与仓库根 `templates/` 一致。
///
/// 改了 templates/ 却忘了跑 `dart run tool/gen_templates.dart`，这条测试会红。
Directory cliRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && pubspec.readAsStringSync().contains('name: w_tools_cli')) {
      return dir;
    }
    dir = dir.parent;
  }
  throw StateError('找不到 w_tools_cli 包根');
}

void main() {
  final repoRoot = cliRoot().path;

  test('templates.g.dart 与 templates/ 内容一致', () {
    final committed = File(
      p.join(repoRoot, 'lib', 'src', 'init', 'templates.g.dart'),
    ).readAsStringSync();
    expect(
      committed,
      generate(repoRoot),
      reason: '改了 templates/ 之后要跑 `dart run tool/gen_templates.dart`',
    );
  });

  test('生成的常量能按开关剔除可选 export', () {
    final all = InitTemplates.toolkit(features: InitFeatures.full.copyWith(map: true));
    expect(all, contains("export 'package:w_tools_qr/w_tools_qr.dart';"));
    expect(all, contains("export 'package:w_tools_map/w_tools_map.dart';"));

    final minimal = InitTemplates.toolkit(
      features: InitFeatures.forProfile(InitProfile.minimal),
    );
    expect(minimal, isNot(contains("export 'package:w_tools_qr")));
    expect(minimal, isNot(contains("export 'package:w_tools_map")));
    expect(minimal, isNot(contains("export 'package:w_tools_ui")));
  });

  test('AGENTS 按能力裁剪未启用的段落', () {
    final minimal = InitTemplates.agentsBlock(
      withUi: false,
      withApp: false,
      withForm: false,
      withApi: false,
      withAsync: false,
      withQr: false,
      withMap: false,
    );
    expect(minimal, contains('WStorage'));
    expect(minimal, isNot(contains('WApp.options')));
    expect(minimal, isNot(contains('WFormTextField')));
    expect(minimal, isNot(contains('DioRegistry')));
    expect(minimal, isNot(contains('WAsyncController')));
    expect(minimal, isNot(contains('WQrView')));
    expect(minimal, isNot(contains('WMap')));

    final noAsync = InitTemplates.agentsBlock(withAsync: false);
    expect(noAsync, isNot(contains('WAsyncController')));
    expect(noAsync, contains('WApp.options'));

    final noForm = InitTemplates.agentsBlock(withForm: false);
    expect(noForm, isNot(contains('WFormTextField')));
    expect(noForm, contains('WApp.options'));

    final noApi = InitTemplates.agentsBlock(withApi: false);
    expect(noApi, isNot(contains('DioRegistry')));
    expect(noApi, contains('WApp.options'));

    final noApp = InitTemplates.agentsBlock(withApp: false);
    expect(noApp, isNot(contains('WApp.options')));
    expect(noApp, contains('WStorage'));

    final noQr = InitTemplates.agentsBlock(withQr: false);
    expect(noQr, isNot(contains('WQrView')));

    final noMap = InitTemplates.agentsBlock(withMap: false);
    expect(noMap, isNot(contains('WMap')));

    final noToast = InitTemplates.agentsBlock(withToast: false);
    expect(noToast, isNot(contains('WToast')));

    final noUi = InitTemplates.agentsBlock(withUi: false);
    expect(noUi, isNot(contains('WImage')));
    expect(noUi, isNot(contains('AppScaffold')));

    final enNoForm = InitTemplates.agentsBlock(lang: 'en', withForm: false);
    expect(enNoForm, isNot(contains('WFormTextField')));
    expect(enNoForm, contains('WApp.options'));
  });

  test('base 包含上移候选与 API 形状约束', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('默认值要能直接用'));
    expect(block, contains('API 参数优先'));
    expect(block, contains('由包维护者补 CHANGELOG'));

    final en = InitTemplates.agentsBlock(lang: 'en');
    expect(en, contains('working defaults'));
    expect(en, contains('prefer ≤ 3 API parameters'));
    expect(en, contains('package maintainers add the CHANGELOG entry'));
  });

  test('base 只指引暂存层，UI 分层由 ui 片段负责', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('先落暂存层'));
    expect(block, contains('design_system'));
    expect(block, isNot(contains('项目永久 UI 规范')));
    expect(InitTemplates.agentsBlock(), contains('项目永久 UI 层'));
  });

  test('UI 片段说明 lib/app/ui 是永久 UI 层', () {
    final withUi = InitTemplates.agentsBlock();
    expect(withUi, contains('项目永久 UI 层'));
    expect(withUi, contains('不走 STAGED'));

    final noUi = InitTemplates.agentsBlock(withUi: false);
    expect(noUi, isNot(contains('项目永久 UI 层')));
  });

  test('英文 banned 段落使用英文标题和边界说明', () {
    final block = InitTemplates.agentsBlock(
      lang: 'en',
      banned: const <BannedRule>[
        BannedRule(
          id: 'no-foo',
          pattern: 'Foo',
          mode: BannedPatternMode.literal,
          use: 'Bar',
          reason: 'removed',
          level: DoctorLevel.warn,
          paths: <String>[],
          ignore: <String>[],
        ),
      ],
    );
    expect(block, contains('Project-banned APIs'));
    expect(block, isNot(contains('本项目禁用 API')));
    expect(block, contains('R9 only matches registered patterns'));
    expect(block, contains('use `Bar`'));
    expect(block, contains('reason: removed'));
    expect(block, isNot(contains('改用')));
  });

  test('AGENTS 硬规则带 doctor 规则号，且不再内联规则速查表', () {
    final zh = InitTemplates.agentsBlock();
    expect(zh, contains('## 硬规则'));
    for (final rule in <String>['R1', 'R2', 'R4', 'R5', 'R9']) {
      expect(zh.split('## 组件约定').first, contains(rule), reason: '硬规则缺少 $rule');
    }
    // 规则速查表由 doctor --format=json 提供；内联的表既占常驻上下文又无法执行。
    expect(zh, isNot(contains('## 检查项')));
    expect(zh, isNot(contains('| R1 |')));

    final en = InitTemplates.agentsBlock(lang: 'en');
    expect(en, contains('## Hard rules'));
    for (final rule in <String>['R1', 'R2', 'R4', 'R5', 'R9']) {
      expect(en.split('## Component conventions').first, contains(rule));
    }
    expect(en, isNot(contains('## Checks')));
  });

  test('import 例外从 R2 常量渲染（toolkit / ui / design_system / dev-only）', () {
    for (final block in <String>[
      InitTemplates.agentsBlock(),
      InitTemplates.agentsBlock(lang: 'en'),
    ]) {
      expect(block, contains('lib/app/w/toolkit.dart'));
      expect(block, contains('lib/app/ui/'));
      expect(block, contains('lib/app/design_system/'));
      for (final pkg in <String>['w_tools_cli', 'w_tools_figma', 'w_tools_device', 'w_tools_e2e']) {
        expect(block, contains(pkg), reason: 'import 例外缺少 $pkg');
      }
      expect(block, contains('integration_test/'));
    }
  });

  test('纯 Dart 项目的命令跟着 isFlutter 走', () {
    final dart = InitTemplates.agentsBlock(isFlutter: false);
    expect(dart, contains('dart analyze'));
    expect(dart, contains('dart test'));
    expect(dart, isNot(contains('flutter analyze')));
    expect(dart, isNot(contains('flutter test')));

    final flutter = InitTemplates.agentsBlock();
    expect(flutter, contains('flutter analyze'));
    expect(flutter, contains('flutter test'));
  });

  test('AGENTS 片段带标记块（init 靠它幂等替换）', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('<!-- w_tools:begin -->'));
    expect(block, contains('<!-- w_tools:end -->'));
  });

  group('AGENTS 结构预算（防沉淀）', () {
    test('预算来自 catalog/agent_budget.yaml，且覆盖必检组合', () {
      final budget = AgentBudget.load();
      for (final combo in AgentBudget.requiredCombos) {
        expect(budget.hasCombo(combo), isTrue, reason: '预算缺少必检组合 $combo');
      }
      expect(budget.feedbackMaxLines, greaterThan(0));
    });

    test('渲染结果在预算内（行数 / 字符 / 反馈行数）', () {
      final budget = AgentBudget.load();
      final rows = measure(budget);
      expect(rows, isNotEmpty);
      expect(violations(budget, rows: rows), isEmpty);
    });

    test('预算文件缺失时直接报错，不能静默失去保护', () {
      final empty = Directory.systemTemp.createTempSync('wt_budget_');
      addTearDown(() => empty.deleteSync(recursive: true));
      expect(() => AgentBudget.load(empty), throwsStateError);
    });

    test('顺序：怎么用 → 硬规则 → 组件约定 → 完成前', () {
      final block = InitTemplates.agentsBlock();
      final howto = block.indexOf('## 怎么用 w_tools');
      final hard = block.indexOf('## 硬规则');
      final conventions = block.indexOf('## 组件约定');
      final beforeDone = block.indexOf('## 完成前');
      expect(howto, greaterThanOrEqualTo(0));
      expect(hard, greaterThan(howto));
      expect(conventions, greaterThan(hard));
      expect(beforeDone, greaterThan(conventions));
      expect(
        block.substring(0, hard).split('\n').length,
        lessThan(30),
        reason: '硬规则必须在前 30 行',
      );
      expect(block, isNot(contains('## 项目规则')), reason: '项目规则属于标记块之外');
    });

    test('反馈只留几行，并指向 AI_PROMPTS 的 L-1', () {
      final block = InitTemplates.agentsBlock();
      final closing = block.substring(block.indexOf('## 完成前'));
      expect(closing, contains('AI_PROMPTS.md'));
      expect(closing, contains('L-1'));
      final budget = AgentBudget.load();
      for (final lang in <String>['zh', 'en']) {
        expect(
          feedbackLines(lang),
          lessThanOrEqualTo(budget.feedbackMaxLines),
          reason: '$lang 的反馈段太长（默认关闭的通道不该常驻）',
        );
      }
    });

    test('zh / en 组件符号集合一致', () {
      String symbols(String text) {
        final found = RegExp(
          r'\b(?:W|App)[A-Z][A-Za-z0-9_]*',
        ).allMatches(text).map((m) => m.group(0)!).toSet().toList()..sort();
        return found.join(' ');
      }

      expect(symbols(InitTemplates.agentsBlock(lang: 'en')), symbols(InitTemplates.agentsBlock()));
    });

    test('每个能力一行约定，且都带 explain 入口', () {
      final block = InitTemplates.agentsBlock();
      for (final row in <String>[
        '页面与 UI',
        '表单',
        '接口',
        '启动 / 插件',
        '异步区块',
        '提示',
        '基础工具',
        '扫码',
        '地图',
      ]) {
        expect(block, contains(row), reason: '缺少「$row」约定');
      }
      expect('explain '.allMatches(block).length, greaterThanOrEqualTo(8));
    });

    test('项目规则占位在标记块外，且不自带 begin/end 标记', () {
      for (final stub in <String>[
        InitTemplates.projectRulesStub(),
        InitTemplates.projectRulesStub(lang: 'en'),
      ]) {
        expect(stub, isNot(contains('w_tools:begin')));
        expect(stub, isNot(contains('w_tools:end')));
        expect(stub, contains('init'));
      }
      expect(InitTemplates.projectRulesStub(), contains('## 项目规则'));
      expect(InitTemplates.projectRulesStub(lang: 'en'), contains('## Project rules'));
    });
  });
}
