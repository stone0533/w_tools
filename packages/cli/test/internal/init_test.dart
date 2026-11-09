import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:w_tools_cli/src/doctor/config.dart';
import 'package:w_tools_cli/src/init/features.dart';
import 'package:w_tools_cli/src/init/init_project.dart';
import 'package:w_tools_cli/src/init/versions.dart';
import 'package:w_tools_cli/src/common/version.dart';
import 'package:w_tools_cli/src/init/manifest.dart';
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

      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
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

    test('默认生成 .w_tools/AI_PROMPTS.md，--no-ai-prompts 关闭', () async {
      final root = makeProject();
      final report = runInit(root);
      final prompt = File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md'));
      expect(prompt.existsSync(), isTrue);
      expect(report.created.any((e) => e.contains('AI_PROMPTS.md')), isTrue);
      expect(prompt.readAsStringSync(), contains('场景选择'));
      expect(prompt.readAsStringSync(), contains('A-1. 只读计划'));
      expect(prompt.readAsStringSync(), contains('w_tools_cli'));

      final offRoot = makeProject();
      final off = runInit(offRoot, aiPrompts: false);
      expect(File(p.join(offRoot.path, '.w_tools', 'AI_PROMPTS.md')).existsSync(), isFalse);
      expect(off.created.any((e) => e.contains('AI_PROMPTS.md')), isFalse);
    });

    test('AI_PROMPTS 跟随 targets / Flutter / 聚合包上下文', () async {
      final claudeRoot = makeProject();
      runInit(claudeRoot, targets: const {'claude'});
      final claude = File(
        p.join(claudeRoot.path, '.w_tools', 'AI_PROMPTS.md'),
      ).readAsStringSync();
      expect(claude, contains('CLAUDE.md'));
      expect(claude, isNot(contains('AGENTS.md')));
      expect(claude, contains('package:demo_app/app/w/toolkit.dart'));

      final dartRoot = makeProject();
      File(p.join(dartRoot.path, 'pubspec.yaml')).writeAsStringSync(
        "name: demo_app\nenvironment:\n  sdk: '^3.8.0'\ndependencies:\n  w_tools_core: ^3.1.1\n",
      );
      runInit(dartRoot);
      final dart = File(
        p.join(dartRoot.path, '.w_tools', 'AI_PROMPTS.md'),
      ).readAsStringSync();
      expect(dart, contains('dart analyze'));
      expect(dart, isNot(contains('flutter analyze')));
      expect(dart, contains('本项目依赖具体子包'));

      final aggregateRoot = makeProject();
      File(p.join(aggregateRoot.path, 'pubspec.yaml')).writeAsStringSync(
        "name: demo_app\nenvironment:\n  sdk: '^3.8.0'\ndependencies:\n  w_tools: ^10.0.0\n",
      );
      runInit(aggregateRoot);
      final aggregate = File(
        p.join(aggregateRoot.path, '.w_tools', 'AI_PROMPTS.md'),
      ).readAsStringSync();
      expect(aggregate, contains('已使用聚合包'));
    });

    test('AI_PROMPTS 按已启用能力裁剪表单 / 接口场景', () async {
      final root = makeProject();
      runInit(
        root,
        features: InitFeatures.full.copyWith(form: false, api: false),
      );
      final prompt = File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).readAsStringSync();
      expect(prompt, isNot(contains('## C. 表单')));
      expect(prompt, isNot(contains('## D. 接口')));
      expect(prompt, isNot(contains('| 表单 / 校验 / 提交 |')));
      expect(prompt, isNot(contains('| 接口 / 登录 / 401 |')));
      expect(prompt, isNot(contains('@if:')));
      expect(prompt, contains('B-1'));

      final fullRoot = makeProject();
      runInit(fullRoot);
      final full = File(
        p.join(fullRoot.path, '.w_tools', 'AI_PROMPTS.md'),
      ).readAsStringSync();
      expect(full, contains('## C. 表单'));
      expect(full, contains('## D. 接口'));
    });

    test('AI_PROMPTS 英文版包含场景选择', () async {
      final root = makeProject();
      runInit(root, lang: 'en');
      final prompt = File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).readAsStringSync();
      expect(prompt, contains('Scenario selection'));
      expect(prompt, contains('A-1. Read-only plan'));
    });

    test('--no-instructions 同时关闭 AI_PROMPTS', () async {
      final root = makeProject();
      final report = runInit(root, targets: const <String>{});
      expect(File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).existsSync(), isFalse);
      expect(report.created.any((e) => e.contains('AI_PROMPTS.md')), isFalse);
    });

    test('--check-drift 检测 AI_PROMPTS 内容变化', () async {
      final root = makeProject();
      runInit(root);
      final prompt = File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md'));
      prompt.writeAsStringSync('${prompt.readAsStringSync()}\n<!-- edited -->\n');
      final report = runInit(root, check: true);
      expect(report.drift.any((e) => e.contains('AI_PROMPTS.md')), isTrue);
    });

    test('--check 检测 AI_PROMPTS 缺失', () async {
      final root = makeProject();
      runInit(root);
      File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).deleteSync();
      final report = runInit(root, check: true);
      expect(report.missing.any((e) => e.contains('AI_PROMPTS.md')), isTrue);
    });

    test('--no-ai-prompts 对已有 AI_PROMPTS 只报告 stale', () async {
      final root = makeProject();
      runInit(root);
      final report = runInit(root, aiPrompts: false);
      expect(report.stale.any((e) => e.contains('AI_PROMPTS.md')), isTrue);
      expect(File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).existsSync(), isTrue);
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

      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains("export 'package:w_tools_ui")));
      expect(toolkit, isNot(contains("export '../ui/")));

      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, isNot(contains('AppScaffold')));

      expect(report.pubspecSnippet, isNot(contains('w_tools_ui:')));
    });

    test('--figma 只追加 AGENTS 片段，不影响 toolkit / 依赖片段', () async {
      final root = makeProject();
      final report = runInit(root, figma: true);
      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, contains('## Figma → Flutter'));
      expect(agents, contains('w_tools_figma'));
      expect(agents, contains('w_tools_figma:figma init'));
      expect(agents, contains('dart pub add dev:w_tools_figma'));
      expect(agents, isNot(contains('dart pub add dev:w_tools_figma:')));
      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains('w_tools_figma')));
      expect(report.pubspecSnippet, isNot(contains('w_tools_figma')));
    });

    test('manifest 记录生成器版本，老的没有该字段也能读', () {
      final root = makeProject();
      final manifest = InitManifest(
        profile: 'full',
        features: const <String, bool>{'core': true},
        targets: const <String>['agents'],
        lang: 'zh',
        figma: true,
        device: false,
        generator: cliVersion,
      );
      final file = InitManifest.fileFor(root)..parent.createSync(recursive: true);
      file.writeAsStringSync(manifest.encode());
      expect(InitManifest.load(root)?.generator, cliVersion);
      expect(InitManifest.load(root)?.aiPrompts, isTrue);

      // 老文件（没有 generator）
      file.writeAsStringSync('{"schema":"w_tools_cli.init/1","profile":"full"}');
      expect(InitManifest.load(root)?.generator, isNull);
    });

    test('--check 不迁移 manifest，也不把内部 manifest 当缺失', () async {
      final root = makeProject();
      final legacy = File(p.join(root.path, '.w_tools_init.json'));
      legacy.writeAsStringSync('{"schema":"w_tools_cli.init/1"}');
      final report = runInit(
        root,
        check: true,
        device: true,
        manifest: const InitManifest(
          profile: 'full',
          features: <String, bool>{},
          targets: <String>['agents'],
          lang: 'zh',
          figma: true,
          device: true,
        ),
      );
      expect(legacy.existsSync(), isTrue, reason: 'check 模式不应移动文件');
      expect(File(p.join(root.path, '.w_tools', 'init.json')).existsSync(), isFalse);
      expect(
        report.missing.any((e) => e.contains('init.json')),
        isFalse,
        reason: '--check 只检查用户可见生成物，内部 manifest 不算缺失',
      );
    });

    test('--check 不把可选的 .w_tools_doctor.yaml 当缺失', () async {
      final root = makeProject();
      // 项目里没有 .w_tools_doctor.yaml，也没跑过 init
      final report = runInit(root, check: true);
      expect(report.missing.any((e) => e.contains('.w_tools_doctor.yaml')), isFalse);
      expect(report.missing.any((e) => e.contains('toolkit.dart')), isTrue);
    });

    test('init 生成的聚合入口跟随 .w_tools_doctor.yaml 的 toolkit_entry', () async {
      final root = makeProject();
      File(p.join(root.path, '.w_tools_doctor.yaml')).writeAsStringSync(
        'toolkit_entry: lib/app/w/custom_toolkit.dart\n',
      );
      runInit(root, features: InitFeatures.full);
      expect(
        File(p.join(root.path, 'lib/app/w/custom_toolkit.dart')).existsSync(),
        isTrue,
      );
      expect(File(p.join(root.path, 'lib/app/w/toolkit.dart')).existsSync(), isFalse);
      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, contains('package:demo_app/app/w/custom_toolkit.dart'));
      expect(agents, isNot(contains('package:demo_app/app/w/toolkit.dart')));
    });

    test('旧 .w_tools_init.json 自动迁到 .w_tools/init.json', () async {
      final root = makeProject();
      File(
        p.join(root.path, '.w_tools_init.json'),
      ).writeAsStringSync('{"schema":"w_tools_cli.init/1"}');
      final report = runInit(root, device: true);
      expect(File(p.join(root.path, '.w_tools_init.json')).existsSync(), isFalse);
      expect(File(p.join(root.path, '.w_tools', 'init.json')).existsSync(), isTrue);
      expect(report.warnings.any((e) => e.contains('.w_tools_init.json')), isTrue);
    });

    test('--check --force 不写项目配置，也不报配置 drift', () async {
      final root = makeProject();
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      config.writeAsStringSync('banned: []\n');
      final before = config.readAsStringSync();
      final report = runInit(root, check: true, force: true);
      expect(config.readAsStringSync(), before);
      expect(report.drift.any((e) => e.contains('.w_tools_doctor.yaml')), isFalse);
      expect(report.upToDate.any((e) => e.contains('.w_tools_doctor.yaml')), isTrue);
      expect(File('${config.path}.bak').existsSync(), isFalse);
    });

    test('--check --force-config 报配置 drift，但不写 .bak', () async {
      final root = makeProject();
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      config.writeAsStringSync('banned: []\n');
      final before = config.readAsStringSync();
      final report = runInit(root, check: true, forceConfig: true);
      expect(config.readAsStringSync(), before);
      expect(report.drift.any((e) => e.contains('.w_tools_doctor.yaml')), isTrue);
      expect(File('${config.path}.bak').existsSync(), isFalse);
    });

    test('--device 只生成设备工具，不生成 integration_test', () async {
      final root = makeProject();
      final report = runInit(root, device: true);
      for (final rel in const [
        'docs/agents/device-testing.md',
        'tool/gradle-mirror.init.gradle.example',
      ]) {
        expect(File(p.join(root.path, rel)).existsSync(), isTrue, reason: rel);
        expect(report.created.any((e) => e.startsWith(rel)), isTrue, reason: rel);
      }
      expect(
        File(p.join(root.path, 'integration_test', 'app_keepalive_smoke_test.dart')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains('w_tools_device')));
      expect(report.pubspecSnippet, contains('w_tools_device'));
      final doc = File(p.join(root.path, 'docs', 'agents', 'device-testing.md')).readAsStringSync();
      expect(doc, isNot(contains('Get.offAllNamed')));
      expect(doc, isNot(contains('会员卡')));
      expect(doc, isNot(contains('dart run tool/device_smoke.dart')));
    });

    test('旧 tool/device_smoke.dart 只提示 stale', () async {
      final root = makeProject();
      final file = File(p.join(root.path, 'tool', 'device_smoke.dart'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('// 复制到新项目的 tool/device_smoke.dart\n');
      final report = runInit(root, device: true);
      expect(report.stale.any((e) => e.contains('tool/device_smoke.dart')), isTrue);
      expect(file.existsSync(), isTrue);
    });

    test('旧 device 文档含 --device-test 时提示 force-starters', () async {
      final root = makeProject();
      final file = File(p.join(root.path, 'docs', 'agents', 'device-testing.md'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('run init --device-test\n');
      final report = runInit(root);
      expect(report.warnings.any((w) => w.contains('force-starters')), isTrue);
    });

    test('--device 文档替换项目名，且保留 starter 语义', () async {
      final root = makeProject();
      final report = runInit(root, device: true);
      final file = File(p.join(root.path, 'docs', 'agents', 'device-testing.md'));
      final original = file.readAsStringSync();
      expect(original, contains('demo_app'));
      expect(original, isNot(contains('{{projectName}}')));
      expect(original, isNot(contains('--device-test')));
      file.writeAsStringSync('// 用户改过\n');
      final again = runInit(root, device: true);
      expect(file.readAsStringSync(), '// 用户改过\n');
      expect(again.upToDate.any((e) => e.contains('device-testing.md')), isTrue);
      expect(again.warnings.any((w) => w.contains('旧 device 内容')), isFalse);
      final forced = runInit(root, device: true, forceStarters: true);
      expect(file.readAsStringSync(), isNot('// 用户改过\n'));
      expect(forced.created.any((e) => e.contains('已覆盖')), isTrue);
      expect(report.created.any((e) => e.contains('device-testing.md')), isTrue);
    });

    test('--figma 不重复 UI / form 组件规则', () async {
      final noUiRoot = makeProject();
      runInit(noUiRoot, features: InitFeatures.full.copyWith(ui: false), figma: true);
      final noUiAgents = File(p.join(noUiRoot.path, 'AGENTS.md')).readAsStringSync();
      expect(noUiAgents, contains('w_tools_figma'));
      expect(noUiAgents, isNot(contains('页面骨架用 `AppScaffold`')));
      expect(noUiAgents, isNot(contains('表单用 `WForm`')));

      final minimalRoot = makeProject();
      runInit(
        minimalRoot,
        features: InitFeatures.forProfile(InitProfile.minimal),
        figma: true,
      );
      final minimalAgents = File(p.join(minimalRoot.path, 'AGENTS.md')).readAsStringSync();
      expect(minimalAgents, contains('w_tools_figma'));
      expect(minimalAgents, isNot(contains('AppScaffold')));
      expect(minimalAgents, isNot(contains('WForm')));
    });

    test('profile=minimal 只保留 core', () async {
      final root = makeProject();
      runInit(root, features: InitFeatures.forProfile(InitProfile.minimal));

      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
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
      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, isNot(contains("export 'package:w_tools_qr")));
      expect(toolkit, contains("export 'package:w_tools_map"));
      final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
      expect(agents, isNot(contains('WQrView')));
      expect(agents, contains('WMap'));
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

    test('--force 保留自定义 config，并提示 --force-config', () async {
      final root = makeProject();
      runInit(root);
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      const custom = '# 我改过\nfeedback:\n  issue: true\n';
      config.writeAsStringSync(custom);
      final report = runInit(root, force: true);
      expect(config.readAsStringSync(), custom);
      expect(report.created.any((e) => e.contains('.w_tools_doctor.yaml')), isFalse);
      expect(
        report.warnings.any(
          (e) => e.contains('保留') && e.contains('--force-config'),
        ),
        isTrue,
      );
      expect(File('${config.path}.bak').existsSync(), isFalse);
    });

    test('--force-config 覆盖配置前写 .bak，连续覆盖不丢旧备份', () async {
      final root = makeProject();
      runInit(root);
      final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
      const first = '# user A\nfeedback:\n  issue: true\n';
      config.writeAsStringSync(first);
      final firstReport = runInit(root, forceConfig: true);
      expect(config.readAsStringSync(), renderDefaultConfig());
      expect(File('${config.path}.bak').readAsStringSync(), first);
      expect(firstReport.warnings.any((e) => e.contains('.bak')), isTrue);

      const second = '# user B\nfeedback:\n  issue: false\n';
      config.writeAsStringSync(second);
      runInit(root, forceConfig: true);
      expect(
        File('${config.path}.bak').readAsStringSync(),
        first,
        reason: '已有 .bak 不能被覆盖',
      );
      final stamped = Directory(root.path)
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('.w_tools_doctor.yaml.bak.'))
          .toList();
      expect(stamped, isNotEmpty);
      expect(stamped.any((f) => f.readAsStringSync() == second), isTrue);
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
              '  w_tools_core: any\n  w_tools_app: any\n  w_tools_app_getx: any\n  w_tools_form: any\n'
              '  w_tools_ui: any\n  w_tools_api: any\n  w_tools_toast: any\n'
              '  w_tools_qr: any\n  w_tools_async: any\n'
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

    test('CLI-019 pubspecNeeded 直接来自依赖状态，不解析提示文案', () async {
      final missing = runInit(makeProject());
      expect(missing.pubspecNeeded, isTrue);

      final full = runInit(
        makeProject(
          extra: {
            'pubspec.yaml':
                'name: demo_app\n'
                'dependencies:\n'
                '  w_tools_core: any\n  w_tools_app: any\n  w_tools_app_getx: any\n  w_tools_form: any\n'
                '  w_tools_ui: any\n  w_tools_api: any\n  w_tools_toast: any\n'
                '  w_tools_qr: any\n  w_tools_async: any\n'
                'dev_dependencies:\n'
                '  w_tools_cli: any\n',
          },
        ),
      );
      expect(full.pubspecNeeded, isFalse);
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

    test('--force 不覆盖 UI starter；--force-starters 才覆盖并备份', () async {
      final root = makeProject();
      runInit(root);
      final ui = File(p.join(root.path, 'lib/app/ui/app_scaffold.dart'));
      ui.writeAsStringSync('// 项目自定义 UI\n');

      final plain = runInit(root, force: true);
      expect(ui.readAsStringSync(), '// 项目自定义 UI\n');
      expect(plain.upToDate.any((e) => e.startsWith('lib/app/ui/app_scaffold.dart')), isTrue);

      final forced = runInit(root, forceStarters: true);
      expect(ui.readAsStringSync(), isNot('// 项目自定义 UI\n'));
      expect(File('${ui.path}.bak').readAsStringSync(), '// 项目自定义 UI\n');
      expect(forced.warnings.any((e) => e.contains('app_scaffold.dart')), isTrue);
    });

    test('旧版 toolkit --force 自动迁移自定义 export', () async {
      final root = makeProject(
        extra: {
          'lib/app/w/toolkit.dart':
              '// 旧版\n'
              "library;\n"
              "export 'package:w_tools_core/w_tools_core.dart';\n"
              "export 'package:foo/foo.dart';\n",
        },
      );
      runInit(root, force: true);
      expect(
        File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(),
        isFalse,
      );
      final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
      expect(toolkit, contains('// w_tools:begin'));
      expect(toolkit, contains('// w_tools:end'));
      expect(
        toolkit.indexOf("export 'package:foo/foo.dart';"),
        greaterThan(toolkit.indexOf('// w_tools:end')),
      );
      expect(File(p.join(root.path, 'lib/app/w/toolkit.dart.bak')).existsSync(), isTrue);
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
    test('仓库版本与生成的 caret 约束完全一致（防版本漂移）', () async {
      final root = repo!;
      final snippet = runInit(
        makeProject(),
        features: InitFeatures.full.copyWith(map: true),
      ).pubspecSnippet;
      for (final entry in subpackageConstraints.entries) {
        final pubspecPath = p.join(
          root.path,
          'packages',
          entry.key.replaceFirst('w_tools_', ''),
          'pubspec.yaml',
        );
        final pubspec = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
        final version = pubspec['version'] as String;
        expect(
          entry.value,
          '^$version',
          reason: '${entry.key} 的 init 约束必须等于当前版本 $version',
        );
        expect(
          snippet,
          contains('${entry.key}: ${entry.value}'),
          reason: 'init 片段缺少 ${entry.key}: ${entry.value}',
        );
      }

      final devicePubspec =
          loadYaml(
                File(
                  p.join(root.path, 'packages', 'device', 'pubspec.yaml'),
                ).readAsStringSync(),
              )
              as YamlMap;
      expect(
        wToolsDeviceConstraint,
        '^${devicePubspec['version']}',
        reason: 'w_tools_device 的 init 约束必须等于当前版本',
      );
      expect(cliConstraint, '^1.16.0');
      expect(snippet, contains('w_tools_cli: $cliConstraint'));

      // 反向检查：片段里出现的每个 w_tools_* 约束都必须在已知清单里，
      // 防止新增/手写约束绕过 subpackageConstraints。
      final allowed = <String>{
        ...subpackageConstraints.keys,
        'w_tools_cli',
        'w_tools_device',
      };
      for (final match in RegExp(
        r'^\s*(w_tools_[a-z_]+):\s*\^',
        multiLine: true,
      ).allMatches(snippet)) {
        expect(
          allowed,
          contains(match.group(1)),
          reason: 'init 片段出现了未登记的约束 ${match.group(1)}',
        );
      }
    }, skip: repo == null ? '不在 w_tools 仓库内' : false);
  });
}
