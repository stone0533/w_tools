import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:w_tools_cli/src/doctor/banned_rule.dart';
import 'package:w_tools_cli/src/doctor/rule.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/templates.dart';

import '../tool/gen_templates.dart';

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
    expect(minimal, isNot(contains('WApp.start')));
    expect(minimal, isNot(contains('WFormTextField')));
    expect(minimal, isNot(contains('DioRegistry')));
    expect(minimal, isNot(contains('WAsyncController')));
    expect(minimal, isNot(contains('WQrView')));
    expect(minimal, isNot(contains('WMap')));

    final noAsync = InitTemplates.agentsBlock(withAsync: false);
    expect(noAsync, isNot(contains('WAsyncController')));
    expect(noAsync, contains('WApp.start'));

    final noForm = InitTemplates.agentsBlock(withForm: false);
    expect(noForm, isNot(contains('WFormTextField')));
    expect(noForm, contains('WApp.start'));

    final noApi = InitTemplates.agentsBlock(withApi: false);
    expect(noApi, isNot(contains('DioRegistry')));
    expect(noApi, contains('WApp.start'));

    final noApp = InitTemplates.agentsBlock(withApp: false);
    expect(noApp, isNot(contains('WApp.start')));
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
    expect(enNoForm, contains('WApp.start'));
  });

  test('base 包含上移候选与 API 形状约束', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('默认值要能直接用'));
    expect(block, contains('API 参数优先'));
    expect(block, contains('由维护者补 CHANGELOG'));
  });

  test('base 只指引暂存层，UI 分层由 ui 片段负责', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('待上移的通用组件'));
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

  test('AGENTS closing 生成 doctor 规则速查表', () {
    final zh = InitTemplates.agentsBlock();
    expect(zh, contains('## 检查项'));
    expect(zh, contains('| R1 | 聚合包依赖 |'));
    expect(zh, contains('| R9 | 项目禁用 API |'));

    final en = InitTemplates.agentsBlock(lang: 'en');
    expect(en, contains('## Checks'));
    expect(en, contains('| R1 | Aggregate package dependency |'));
    expect(zh, contains('R6 需在'));
    expect(en, contains('R6 must be enabled'));
  });

  test('AGENTS 片段带标记块（init 靠它幂等替换）', () {
    final block = InitTemplates.agentsBlock();
    expect(block, contains('<!-- w_tools:begin -->'));
    expect(block, contains('<!-- w_tools:end -->'));
  });
}
