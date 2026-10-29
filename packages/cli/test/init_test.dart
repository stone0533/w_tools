import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/init_project.dart';
import 'package:yaml/yaml.dart';

/// 从当前目录向上找仓库根（含 workspace: 的 pubspec.yaml）。
Directory? tryRepoRoot() {
  var dir = Directory.current;
  while (dir.path != dir.parent.path) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && pubspec.readAsStringSync().contains('workspace:')) {
      return dir;
    }
    dir = dir.parent;
  }
  return null;
}

Directory makeProject({String? agents, Map<String, String>? extra}) {
  final root = Directory.systemTemp.createTempSync('wt_init_');
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
    "name: demo_app\nenvironment:\n  sdk: '^3.8.0'\ndependencies:\n  flutter:\n    sdk: flutter\n",
  );
  if (agents != null) File(p.join(root.path, 'AGENTS.md')).writeAsStringSync(agents);
  extra?.forEach((rel, content) {
    final f = File(p.join(root.path, rel));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  });
  return root;
}

void main() {
  group('生成产物', () {
    test('生成 toolkit / 暂存层 README / AGENTS 片段', () async {
      final root = makeProject(agents: '# 项目说明\n');
      final report = runInit(root);

      expect(report.created, contains('lib/app/w/toolkit.dart'));
      expect(report.created, contains('lib/app/design_system/README.md'));
      expect(report.created, contains('lib/app/ui/app_bars.dart'));
      expect(report.created, contains('lib/app/ui/app_boxes.dart'));
      expect(report.created, contains('lib/app/ui/app_buttons.dart'));
      expect(report.created, contains('lib/app/ui/app_card.dart'));
      expect(report.created, contains('lib/app/ui/app_scaffold.dart'));
      expect(report.created.any((e) => e.startsWith('AGENTS.md')), isTrue);

      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, contains("export 'package:w_tools_ui/w_tools_ui.dart';"));
      expect(toolkit, contains("export '../ui/app_boxes.dart';"));
      expect(toolkit, contains("export '../ui/app_buttons.dart';"));
      expect(toolkit, contains("export '../ui/app_card.dart';"));
      expect(toolkit, contains("export '../ui/app_scaffold.dart';"));
      // 注意：注释里会提到 w_tools_map（解释为什么不导出），所以要断言 export 行
      expect(toolkit, isNot(contains("export 'package:w_tools_map")));
      expect(toolkit, contains('w_tools_qr'));
      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, contains("package:demo_app/app/w/toolkit.dart"));
      expect(agents, contains('AppScaffold'));
      expect(agents, contains('WPressable'));
      final appScaffold = File(
        p.join(root.path, 'lib/app/ui/app_scaffold.dart'),
      ).readAsStringSync();
      expect(appScaffold, contains('class AppScaffold'));
      expect(appScaffold, contains('AppBars.style(context)'));
      final appButtons = File(
        p.join(root.path, 'lib/app/ui/app_buttons.dart'),
      ).readAsStringSync();
      expect(appButtons, contains('class AppButtons'));
      expect(appButtons, contains('WButtonStyle primary'));
      final appBoxes = File(
        p.join(root.path, 'lib/app/ui/app_boxes.dart'),
      ).readAsStringSync();
      expect(appBoxes, contains('class AppBoxes'));
      expect(appBoxes, contains('static BoxDecoration card'));
      final appCard = File(
        p.join(root.path, 'lib/app/ui/app_card.dart'),
      ).readAsStringSync();
      expect(appCard, contains('class AppCard'));
      expect(appCard, contains('AppBoxes.card'));
    });

    test('--no-ui 不生成 ui 文件，也不导出 w_tools_ui', () async {
      final root = makeProject();
      final report = runInit(root, features: InitFeatures.full.copyWith(ui: false));

      expect(report.created, isNot(contains('lib/app/ui/app_scaffold.dart')));
      expect(File(p.join(root.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isFalse);
      expect(
        File(p.join(root.path, 'lib/app/design_system/README.md')).existsSync(),
        isFalse,
      );

      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains("export 'package:w_tools_ui")));
      expect(toolkit, isNot(contains("export '../ui/")));

      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, isNot(contains('AppScaffold')));

      expect(report.pubspecSnippet, isNot(contains('w_tools_ui:')));
    });

    test('profile=minimal 只保留 core', () async {
      final root = makeProject();
      runInit(root, features: InitFeatures.forProfile(InitProfile.minimal));

      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, contains("export 'package:w_tools_core"));
      expect(toolkit, isNot(contains("export 'package:w_tools_ui")));
      expect(toolkit, isNot(contains("export 'package:w_tools_api")));
      expect(File(p.join(root.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isFalse);
    });

    test('profile=ui / api 生成匹配能力', () async {
      final uiRoot = makeProject();
      final uiReport = runInit(
        uiRoot,
        features: InitFeatures.forProfile(InitProfile.ui),
      );
      final uiToolkit = File(
        p.join(uiRoot.path, 'lib/app/w/toolkit.dart'),
      ).readAsStringSync();
      expect(uiToolkit, contains("export 'package:w_tools_ui"));
      expect(uiToolkit, contains("export 'package:w_tools_toast"));
      expect(uiToolkit, isNot(contains("export 'package:w_tools_api")));
      expect(File(p.join(uiRoot.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isTrue);
      expect(File(p.join(uiRoot.path, 'lib/app/design_system/README.md')).existsSync(), isTrue);
      expect(uiReport.pubspecSnippet, contains('w_tools_ui:'));
      expect(uiReport.pubspecSnippet, isNot(contains('w_tools_api:')));

      final apiRoot = makeProject();
      final apiReport = runInit(
        apiRoot,
        features: InitFeatures.forProfile(InitProfile.api),
      );
      final apiToolkit = File(
        p.join(apiRoot.path, 'lib/app/w/toolkit.dart'),
      ).readAsStringSync();
      expect(apiToolkit, contains("export 'package:w_tools_api"));
      expect(apiToolkit, isNot(contains("export 'package:w_tools_ui")));
      expect(File(p.join(apiRoot.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isFalse);
      expect(apiReport.pubspecSnippet, contains('w_tools_api:'));
      expect(apiReport.pubspecSnippet, isNot(contains('w_tools_ui:')));
    });

    test('profile 可被单项覆盖', () async {
      final addUiRoot = makeProject();
      runInit(
        addUiRoot,
        features: InitFeatures.forProfile(InitProfile.minimal).copyWith(ui: true),
      );
      expect(
        File(p.join(addUiRoot.path, 'lib/app/ui/app_scaffold.dart')).existsSync(),
        isTrue,
      );
      final addUiToolkit = File(
        p.join(addUiRoot.path, 'lib/app/w/toolkit.dart'),
      ).readAsStringSync();
      expect(addUiToolkit, contains("export 'package:w_tools_ui"));

      final noUiRoot = makeProject();
      runInit(
        noUiRoot,
        features: InitFeatures.forProfile(InitProfile.ui).copyWith(ui: false),
      );
      expect(
        File(p.join(noUiRoot.path, 'lib/app/ui/app_scaffold.dart')).existsSync(),
        isFalse,
      );
      final noUiToolkit = File(
        p.join(noUiRoot.path, 'lib/app/w/toolkit.dart'),
      ).readAsStringSync();
      expect(noUiToolkit, isNot(contains("export 'package:w_tools_ui")));
      expect(noUiToolkit, contains("export 'package:w_tools_toast"));
    });

    test('profile 切换会报告旧 UI 文件（不删除）', () async {
      final root = makeProject();
      runInit(root);
      final report = runInit(
        root,
        features: InitFeatures.forProfile(InitProfile.minimal),
      );

      expect(report.stale, contains('lib/app/ui/app_scaffold.dart（当前 profile 不生成，未删除）'));
      expect(File(p.join(root.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isTrue);
    });

    test('--no-instructions 报告旧 AGENTS（不删除）', () async {
      final root = makeProject();
      runInit(root);
      final report = runInit(root, targets: const <String>{});

      expect(
        report.stale.any((e) => e.contains('AGENTS.md（当前 targets 未包含 agents')),
        isTrue,
      );
      expect(File(p.join(root.path, 'AGENTS.md')).existsSync(), isTrue);
    });

    test('--no-qr / --with-map 影响导出', () async {
      final root = makeProject();
      runInit(root, features: InitFeatures.full.copyWith(qr: false, map: true));
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains("export 'package:w_tools_qr")));
      expect(toolkit, contains("export 'package:w_tools_map"));
    });

    test('已有 section 时只追加缩进行，不重复 section 头', () async {
      final root = makeProject(
        extra: {
          'pubspec.yaml':
              "name: demo_app\nenvironment:\n  sdk: '^3.8.0'\n"
              "dependencies:\n  flutter:\n    sdk: flutter\n"
              "dev_dependencies:\n  flutter_test:\n    sdk: flutter\n",
        },
      );
      final snippet = runInit(root).pubspecSnippet;
      expect(snippet, contains('# 追加到已有的 dependencies: 下'));
      expect(snippet, contains('# 追加到已有的 dev_dependencies: 下'));
      expect(snippet, isNot(contains('\ndependencies:\n')));
      expect(snippet, isNot(contains('\ndev_dependencies:\n')));
    });

    test('--force 覆盖自定义 config 时给出警告', () async {
      final root = makeProject();
      runInit(root);
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      config.writeAsStringSync('# 我改过\n');
      final report = runInit(root, force: true);
      expect(report.warnings.any((e) => e.contains('覆盖了')), isTrue);
      expect(report.created.any((e) => e.contains('.w_tools_doctor.yaml')), isTrue);
    });

    test('pubspec 写坏时只警告，不抛异常', () async {
      final root = makeProject(extra: {'pubspec.yaml': 'name: demo\n  bad: [\n'});
      final report = runInit(root);
      expect(report.warnings.any((e) => e.contains('解析失败')), isTrue);
      expect(report.pubspecSnippet, contains('w_tools_core'));
    });

    test('依赖齐全时片段直接说明无需修改', () async {
      final root = makeProject(
        extra: {
          'pubspec.yaml':
              'name: demo_app\n'
              'dependencies:\n'
              '  w_tools_core: any\n  w_tools_app: any\n  w_tools_form: any\n'
              '  w_tools_ui: any\n  w_tools_api: any\n  w_tools_toast: any\n'
              '  w_tools_qr: any\n'
              'dev_dependencies:\n'
              '  w_tools_cli: any\n',
        },
      );
      expect(runInit(root).pubspecSnippet, contains('依赖已齐全'));
    });

    test('pubspec 片段只列缺失的包', () async {
      final root = makeProject(
        extra: {
          'pubspec.yaml':
              "name: demo_app\nenvironment:\n  sdk: '^3.8.0'\n"
              "dependencies:\n  w_tools_ui: ^1.1.0\n",
        },
      );
      final snippet = runInit(root).pubspecSnippet;
      expect(snippet, isNot(contains('w_tools_ui')));
      expect(snippet, contains('w_tools_core'));
      expect(snippet, contains('dev_dependencies:'));
    });
  });

  group('AGENTS.md 处理', () {
    test('已有内容时追加，不破坏原文', () async {
      final root = makeProject(agents: '# 我自己的规则\n- 不要用 X\n');
      runInit(root);
      final content = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(content, startsWith('# 我自己的规则'));
      expect(content, contains('<!-- w_tools:begin -->'));
      expect(content.split('<!-- w_tools:begin -->').length, 2); // 只出现一次
    });

    test('重复执行只替换标记块（幂等）', () async {
      final root = makeProject(agents: '# 说明\n');
      runInit(root);
      final first = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      final report = runInit(root);
      final second = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(second, first);
      expect(report.created, isEmpty);
    });

    test('标记块内容过期时原地更新', () async {
      final root = makeProject(
        agents: '# 说明\n<!-- w_tools:begin -->\n旧内容\n<!-- w_tools:end -->\n结尾\n',
      );
      runInit(root);
      final content = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(content, contains('用 w_tools 的方式'));
      expect(content, isNot(contains('旧内容')));
      expect(content, endsWith('结尾\n'));
    });
  });

  group('不覆盖 / check 模式', () {
    test('已有 toolkit.dart 且内容不同 → 默认不覆盖', () async {
      final root = makeProject(
        extra: {
          'lib/app/w/toolkit.dart': '// 我自己写的\n',
        },
      );
      final report = runInit(root);
      expect(File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync(), '// 我自己写的\n');
      expect(report.drift.any((e) => e.contains('内容不同')), isTrue);
    });

    test('--force 才覆盖', () async {
      final root = makeProject(
        extra: {
          'lib/app/w/toolkit.dart': '// 我自己写的\n',
        },
      );
      runInit(root, force: true);
      expect(
        File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync(),
        contains("export 'package:w_tools_ui"),
      );
    });

    test('check 模式不写任何文件', () async {
      final root = makeProject();
      final report = runInit(root, check: true);
      expect(report.created, isEmpty);
      expect(report.missing, isNotEmpty);
      expect(File(p.join(root.path, 'lib/app/w/toolkit.dart')).existsSync(), isFalse);
      expect(File(p.join(root.path, 'AGENTS.md')).existsSync(), isFalse);
    });

    test('check 模式：已初始化项目没有待办（missing 为空）', () async {
      final root = makeProject(agents: '# 说明\n');
      runInit(root);
      final report = runInit(root, check: true);
      expect(report.created, isEmpty);
      expect(report.missing, isEmpty, reason: '已存在的产物不应算缺失');
      expect(report.upToDate, isNotEmpty);
    });

    test('check 模式：内容不同只记 drift，不算失败', () async {
      final root = makeProject();
      runInit(root);
      File(p.join(root.path, 'lib/app/w/toolkit.dart')).writeAsStringSync('// 旧内容\n');
      final report = runInit(root, check: true);
      expect(report.missing, isEmpty);
      expect(report.drift.any((e) => e.contains('内容不同')), isTrue);
    });

    test('check 模式：自定义 .w_tools_doctor.yaml 不算失败', () async {
      final root = makeProject();
      runInit(root);
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      config.writeAsStringSync('${config.readAsStringSync()}\n# 项目自己的调整\n');
      final report = runInit(root, check: true);
      expect(report.missing, isEmpty);
      expect(report.drift, isEmpty, reason: '项目配置属于用户，不做内容比对');
    });

    test('check 模式：AGENTS 标记块过期只记 drift', () async {
      final root = makeProject(agents: '# 说明\n');
      runInit(root);
      File(p.join(root.path, 'AGENTS.md')).writeAsStringSync(
        '# 说明\n<!-- w_tools:begin -->\n旧内容\n<!-- w_tools:end -->\n',
      );
      final report = runInit(root, check: true);
      expect(report.missing, isEmpty);
      expect(report.drift.any((e) => e.contains('标记块')), isTrue);
    });
  });

  group('targets / language', () {
    test('--targets 生成多个指令文件', () async {
      final root = makeProject();
      final report = runInit(root, targets: const {'agents', 'claude', 'cursor'});
      expect(report.created, containsAll(<String>['AGENTS.md', 'CLAUDE.md']));
      expect(File(p.join(root.path, 'CLAUDE.md')).existsSync(), isTrue);
      final cursor = File(p.join(root.path, '.cursor/rules/w_tools.mdc'));
      expect(cursor.existsSync(), isTrue);
      expect(cursor.readAsStringSync(), startsWith('---\ndescription: w_tools conventions'));
    });

    test('--lang=en 生成英文指令', () async {
      final root = makeProject();
      runInit(root, lang: 'en');
      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, contains('Get facts first'));
      final readme = File(p.join(root.path, 'lib/app/design_system/README.md')).readAsStringSync();
      expect(readme, contains('staging area'));
    });

    test('多个 target 都是最新时 check 通过', () async {
      final root = makeProject();
      runInit(root, targets: const {'agents', 'claude'});
      final report = runInit(root, check: true, targets: const {'agents', 'claude'});
      expect(report.missing, isEmpty);
    });
  });

  group('AGENTS 边界', () {
    test('有 begin 没 end：check 记缺失，正常模式不动文件', () async {
      final root = makeProject(agents: '# 说明\n<!-- w_tools:begin -->\n旧内容\n');
      final before = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      final checkReport = runInit(root, check: true);
      expect(checkReport.missing.any((e) => e.contains('w_tools:end')), isTrue);

      final report = runInit(root);
      expect(report.warnings.any((e) => e.contains('不完整')), isTrue);
      expect(File(p.join(root.path, 'AGENTS.md')).readAsStringSync(), before);
    });

    test('有 AGENTS 但没有标记块：check 记缺失，正常模式追加', () async {
      final root = makeProject(agents: '# 说明\n');
      expect(
        runInit(root, check: true).missing.any((e) => e.contains('缺少 w_tools 标记块')),
        isTrue,
      );
      runInit(root);
      expect(File(p.join(root.path, 'AGENTS.md')).readAsStringSync(), contains('w_tools:begin'));
    });
  });

  group('pubspec 片段版本', () {
    final repo = tryRepoRoot();
    test('与仓库当前子包版本一致（防漂移）', () async {
      final root = repo!;
      final snippet = runInit(
        makeProject(),
        features: InitFeatures.full.copyWith(map: true),
      ).pubspecSnippet;
      for (final pkg in <String>[
        'core',
        'app',
        'form',
        'ui',
        'api',
        'toast',
        'qr',
        'map',
      ]) {
        final pubspec =
            loadYaml(
                  File(p.join(root.path, 'packages', pkg, 'pubspec.yaml')).readAsStringSync(),
                )
                as YamlMap;
        final version = pubspec['version'] as String;
        expect(
          snippet,
          contains('w_tools_$pkg: ^$version'),
          reason: 'packages/$pkg 已到 $version，更新 init_project.dart 里的约束',
        );
      }
      expect(snippet, contains('w_tools_cli: ^1.1.0'));
    }, skip: repo == null ? '不在 w_tools 仓库内' : false);
  });
}
