@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _project() {
  final root = Directory.systemTemp.createTempSync('wt_cli_');
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
    "name: demo_app\nenvironment:\n  sdk: ^3.10.0\ndependencies: {}\n",
  );
  return root;
}

/// 用真实的 dart run 跑入口，验证参数解析与退出码（main 里有 exit，不能直接调用）。
Future<ProcessResult> _run(String bin, List<String> args) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'bin/$bin', ...args],
    workingDirectory: Directory.current.path,
  );
}

void main() {
  test('普通 init 会更新 manifest，即使没带 --force', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path])).exitCode, 0);
    final changed = await _run('init.dart', ['--root', root.path, '--device']);
    expect(changed.exitCode, 0, reason: '${changed.stderr}');
    expect(
      File(p.join(root.path, '.w_tools', 'init.json')).readAsStringSync(),
      contains('"device": true'),
    );
    expect(
      File(p.join(root.path, 'integration_test', 'app_keepalive_smoke_test.dart')).existsSync(),
      isFalse,
    );
  });

  test('init --check 回放上次 --device flags', () async {
    final root = _project();
    final first = await _run('init.dart', ['--root', root.path, '--device']);
    expect(first.exitCode, 0, reason: '${first.stderr}');
    final check = await _run('init.dart', ['--root', root.path, '--check']);
    expect(check.exitCode, 0, reason: '${check.stderr}');
    expect(
      File(p.join(root.path, '.w_tools', 'init.json')).readAsStringSync(),
      contains('"device": true'),
    );
  });

  test('init --check 对未初始化项目返回 1 并报告缺失', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--check']);
    expect(r.exitCode, 1);
    expect('${r.stdout}', contains('缺失'));
    expect(File(p.join(root.path, 'lib/app/w/toolkit.dart')).existsSync(), isFalse);
  });

  test('init 之后 init --check 返回 0', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path])).exitCode, 0);
    final check = await _run('init.dart', ['--root', root.path, '--check']);
    expect(check.exitCode, 0);
  });

  test('init 把 banned 写进 AGENTS 段落', () async {
    final root = _project();
    File(p.join(root.path, '.w_tools_doctor.yaml')).writeAsStringSync('''
banned:
  - id: no-foo
    pattern: Foo.bar
    use: Baz.bar
    reason: removed
''');
    expect((await _run('init.dart', ['--root', root.path])).exitCode, 0);
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, contains('本项目禁用 API'));
    expect(agents, contains('no-foo'));
    expect(agents, contains('Baz.bar'));
  });

  test('init 支持 --no-form / --no-app / --no-api', () async {
    final root = _project();
    expect(
      (await _run('init.dart', [
        '--root',
        root.path,
        '--no-form',
        '--no-app',
        '--no-api',
      ])).exitCode,
      0,
    );
    final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
    expect(toolkit, isNot(contains("package:w_tools_form")));
    expect(toolkit, isNot(contains("package:w_tools_app")));
    expect(toolkit, isNot(contains("package:w_tools_api")));
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, isNot(contains('WFormTextField')));
    expect(agents, isNot(contains('WApp.start')));
    expect(agents, isNot(contains('DioRegistry')));
  });

  test('init map 参数统一为 --map / --no-map / --with-map 别名', () async {
    final mapRoot = _project();
    expect((await _run('init.dart', ['--root', mapRoot.path, '--map'])).exitCode, 0);
    expect(
      File(p.join(mapRoot.path, 'lib/app/w/toolkit.dart')).readAsStringSync(),
      contains('package:w_tools_map'),
    );

    final noMapRoot = _project();
    expect((await _run('init.dart', ['--root', noMapRoot.path, '--no-map'])).exitCode, 0);
    expect(
      File(p.join(noMapRoot.path, 'lib/app/w/toolkit.dart')).readAsStringSync(),
      isNot(contains('package:w_tools_map')),
    );

    final aliasRoot = _project();
    expect((await _run('init.dart', ['--root', aliasRoot.path, '--with-map'])).exitCode, 0);
    expect(
      File(p.join(aliasRoot.path, 'lib/app/w/toolkit.dart')).readAsStringSync(),
      contains('package:w_tools_map'),
    );

    final conflict = await _run('init.dart', ['--root', aliasRoot.path, '--map', '--no-map']);
    expect(conflict.exitCode, 2);
    expect('${conflict.stderr}', contains('不能同时'));
  });

  test('init --figma 生成 AGENTS，JSON 标记 figma=true', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--figma', '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final payload = jsonDecode('${r.stdout}') as Map<String, dynamic>;
    expect(payload['figma'], isTrue);
    expect(
      File(p.join(root.path, 'AGENTS.md')).readAsStringSync(),
      contains('w_tools_figma'),
    );
    expect(
      File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync(),
      isNot(contains('w_tools_figma')),
    );
  });

  test('init 自动检测 pubspec 的 w_tools_figma', () async {
    final root = _project();
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    pubspec.writeAsStringSync(
      '${pubspec.readAsStringSync()}dev_dependencies:\n  w_tools_figma: ^0.3.0\n',
    );
    final r = await _run('init.dart', ['--root', root.path, '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final payload = jsonDecode('${r.stdout}') as Map<String, dynamic>;
    expect(payload['figma'], isTrue);
    expect(
      File(p.join(root.path, 'AGENTS.md')).readAsStringSync(),
      contains('w_tools_figma'),
    );
  });

  test('init 使用消费方 pubspec 的 figma 约束', () async {
    final root = _project();
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    pubspec.writeAsStringSync(
      '${pubspec.readAsStringSync()}dev_dependencies:\n  w_tools_figma: ^0.4.0\n',
    );
    final r = await _run('init.dart', ['--root', root.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, contains('dart pub add dev:w_tools_figma:^0.4.0'));
    expect(agents, isNot(contains('dart pub add dev:w_tools_figma:^0.3.0')));
  });

  test('init 对 path 依赖不生成 pub 版本', () async {
    final root = _project();
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    pubspec.writeAsStringSync(
      '${pubspec.readAsStringSync()}dev_dependencies:\n'
      '  w_tools_figma:\n    path: ../figma\n',
    );
    final r = await _run('init.dart', ['--root', root.path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, contains('已通过 path/git 安装'));
    expect(agents, isNot(contains('dart pub add dev:w_tools_figma:')));
  });

  test('ai.figma: false 阻止自动生成', () async {
    final root = _project();
    final pubspec = File(p.join(root.path, 'pubspec.yaml'));
    pubspec.writeAsStringSync(
      '${pubspec.readAsStringSync()}dev_dependencies:\n  w_tools_figma: ^0.3.0\n',
    );
    File(p.join(root.path, '.w_tools_doctor.yaml')).writeAsStringSync(
      'ai:\n  figma: false\n',
    );
    final r = await _run('init.dart', ['--root', root.path, '--json']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final payload = jsonDecode('${r.stdout}') as Map<String, dynamic>;
    expect(payload['figma'], isFalse);
    expect(
      File(p.join(root.path, 'AGENTS.md')).readAsStringSync(),
      isNot(contains('w_tools_figma')),
    );
  });

  test('init --figma / --no-figma 冲突', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--figma', '--no-figma']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('不能同时'));
  });

  test('init 正反 feature 参数不能同时使用', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--ui', '--no-ui']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('不能同时'));

    final app = await _run('init.dart', ['--root', root.path, '--app', '--no-app']);
    expect(app.exitCode, 2);
  });

  test('init help 从 feature 注册表生成', () async {
    final r = await _run('init.dart', ['--help']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('--map / --no-map'));
    expect('${r.stdout}', contains('--app / --no-app'));
    expect('${r.stdout}', contains('--toast / --no-toast'));
    expect('${r.stdout}', contains('--figma / --no-figma'));
  });

  test('init --no-toast 不导出 toast，也不生成轻提示规则', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path, '--no-toast'])).exitCode, 0);
    final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
    expect(toolkit, isNot(contains('package:w_tools_toast')));
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, isNot(contains('轻提示')));
  });

  test('init --no-ui 不生成 UI 文件', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path, '--no-ui'])).exitCode, 0);
    expect(File(p.join(root.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'lib/app/design_system/README.md')).existsSync(), isFalse);
    final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
    expect(toolkit, isNot(contains("export 'package:w_tools_ui")));
    final agents = File(p.join(root.path, 'AGENTS.md')).readAsStringSync();
    expect(agents, isNot(contains('AppScaffold')));
  });

  test('init --profile=minimal 只导出 core', () async {
    final root = _project();
    expect(
      (await _run('init.dart', ['--root', root.path, '--profile=minimal'])).exitCode,
      0,
    );
    final toolkit = File(p.join(root.path, 'lib/app/w/toolkit.dart')).readAsStringSync();
    expect(toolkit, contains("export 'package:w_tools_core"));
    expect(toolkit, isNot(contains("export 'package:w_tools_ui")));
    expect(File(p.join(root.path, 'lib/app/ui/app_scaffold.dart')).existsSync(), isFalse);
  });

  test('init 的 ai-prompts 相反 flag 冲突退出 2', () async {
    final root = _project();
    final both = await _run('init.dart', [
      '--root',
      root.path,
      '--ai-prompts',
      '--no-ai-prompts',
    ]);
    expect(both.exitCode, 2);
    expect('${both.stderr}', contains('不能同时使用'));
  });

  test('init --no-instructions 与 --ai-prompts 冲突退出 2', () async {
    final root = _project();
    final r = await _run('init.dart', [
      '--root',
      root.path,
      '--no-instructions',
      '--ai-prompts',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('不能同时使用'));
  });

  test('init --no-ai-prompts 不生成 AI_PROMPTS', () async {
    final root = _project();
    expect(
      (await _run('init.dart', ['--root', root.path, '--no-ai-prompts'])).exitCode,
      0,
    );
    expect(File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).existsSync(), isFalse);
  });

  test('init --no-instructions 不生成 AGENTS', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path, '--no-instructions'])).exitCode, 0);
    expect(File(p.join(root.path, 'AGENTS.md')).existsSync(), isFalse);
    expect(File(p.join(root.path, '.w_tools', 'AI_PROMPTS.md')).existsSync(), isFalse);
  });

  test('init --check-drift 对改过的产物返回 1', () async {
    final root = _project();
    await _run('init.dart', ['--root', root.path]);
    File(p.join(root.path, 'lib/app/w/toolkit.dart')).writeAsStringSync('// 改过\n');
    expect((await _run('init.dart', ['--root', root.path, '--check'])).exitCode, 0);
    expect((await _run('init.dart', ['--root', root.path, '--check-drift'])).exitCode, 1);
  });

  test('doctor --only 未知规则返回 2', () async {
    final root = _project();
    final r = await _run('doctor.dart', ['--root', root.path, '--only=R99']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('未知规则'));
  });

  test('doctor --write-config：已存在返回 2，--force 才覆盖', () async {
    final root = _project();
    final config = File(p.join(root.path, '.w_tools_doctor.yaml'));

    final first = await _run('doctor.dart', ['--root', root.path, '--write-config']);
    expect(first.exitCode, 0);
    expect(config.existsSync(), isTrue);

    final second = await _run('doctor.dart', ['--root', root.path, '--write-config']);
    expect(second.exitCode, 2);
    expect('${second.stderr}', contains('已存在'));

    config.writeAsStringSync('# 我改过\n');
    final third = await _run('doctor.dart', [
      '--root',
      root.path,
      '--write-config',
      '--force',
    ]);
    expect(third.exitCode, 0);
    expect(config.readAsStringSync(), contains('toolkit_entry'));
  });

  test('doctor --write-config --force 覆盖前备份为 .bak', () async {
    final root = Directory.systemTemp.createTempSync('wt_wcfg_');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    final cfg = File(p.join(root.path, '.w_tools_doctor.yaml'));

    expect((await _run('doctor.dart', ['--root', root.path, '--write-config'])).exitCode, 0);
    cfg.writeAsStringSync('banned:\n  - id: mine\n    pattern: x\n');

    final forced = await _run('doctor.dart', ['--root', root.path, '--write-config', '--force']);
    expect(forced.exitCode, 0);
    expect(forced.stderr, contains('.bak'));
    final backup = File('${cfg.path}.bak');
    expect(backup.existsSync(), isTrue);
    expect(backup.readAsStringSync(), contains('mine'));
    expect(cfg.readAsStringSync(), isNot(contains('mine')));
  });

  test('doctor --json 的 exitCode 与进程退出码一致', () async {
    final bad = _project();
    File(p.join(bad.path, 'pubspec.yaml')).writeAsStringSync(
      'name: demo\ndependencies:\n  w_tools: ^2.0.0\n',
    );
    final fail = await _run('doctor.dart', ['--root', bad.path, '--json']);
    expect(fail.exitCode, 1);
    final failJson = jsonDecode('${fail.stdout}') as Map<String, Object?>;
    expect(failJson['exitCode'], 1);
    expect((failJson['counts'] as Map)['error'], greaterThan(0));
    final issues = (((failJson['rules'] as List).first as Map)['issues'] as List);
    expect((issues.first as Map)['fix'], isNotNull);

    final good = _project();
    final ok = await _run('doctor.dart', ['--root', good.path, '--json']);
    expect(ok.exitCode, 0);
    final okJson = jsonDecode('${ok.stdout}') as Map<String, Object?>;
    expect(okJson['exitCode'], 0);
    expect((okJson['counts'] as Map)['error'], 0);
  });

  test('init --targets / --lang 生效，未知 target 返回 2', () async {
    final root = _project();
    final ok = await _run('init.dart', [
      '--root',
      root.path,
      '--targets=agents,claude',
      '--lang=en',
    ]);
    expect(ok.exitCode, 0);
    expect(File(p.join(root.path, 'CLAUDE.md')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'AGENTS.md')).readAsStringSync(), contains('Get facts first'));

    final bad = await _run('init.dart', ['--root', root.path, '--targets=bogus']);
    expect(bad.exitCode, 2);
    expect('${bad.stderr}', contains('未知 targets'));
  });

  test('init --json 输出机器可读结果', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--json']);
    expect(r.exitCode, 0);
    final json = jsonDecode('${r.stdout}') as Map<String, Object?>;
    expect(json['schemaVersion'], 1);
    expect(json['needsPubspec'], isTrue);
    expect(json['nextActions'], isNotEmpty);
    expect(json['created'], isA<List<Object?>>());
    expect((json['created'] as List).first, isA<Map>());
    expect(json['missing'], isA<List<Object?>>());
  });

  test('init / doctor 支持 --version', () async {
    for (final bin in <String>['init.dart', 'doctor.dart']) {
      final r = await _run(bin, ['--version']);
      expect(r.exitCode, 0);
      expect('${r.stdout}'.trim(), isNotEmpty);
    }
  });

  test('context --format=json 输出项目事实', () async {
    final root = _project();
    final r = await _run('context.dart', ['--root', root.path, '--format=json']);
    expect(r.exitCode, 0);
    final json = jsonDecode('${r.stdout}') as Map<String, Object?>;
    expect(json['schemaVersion'], 1);
    expect((json['project'] as Map)['name'], 'demo_app');
    expect(json['commands'], isA<Map>());
  });

  test('context 的 --max-tokens 非法时返回 2', () async {
    final root = _project();
    final r = await _run('context.dart', ['--root', root.path, '--max-tokens=abc']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('--max-tokens'));
  });

  test('list 能按关键词查到组件（text / json）', () async {
    final r = await _run('list.dart', ['WImage']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('WImage'));

    final json = await _run('list.dart', ['WImage', '--format=json']);
    final payload = jsonDecode('${json.stdout}') as Map<String, Object?>;
    expect(payload['count'], greaterThan(0));
  });

  test('explain 输出 import 与反例（text / json）', () async {
    final r = await _run('explain.dart', ['WImage']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains("import 'package:w_tools_ui/w_tools_ui.dart';"));

    final json = await _run('explain.dart', ['WImage', '--format=json']);
    final payload = jsonDecode('${json.stdout}') as Map<String, Object?>;
    expect(payload['found'], isTrue);
  });

  test('list --format=prompt 输出紧凑目录', () async {
    final r = await _run('list.dart', ['async', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('# w_tools catalog'));
    expect('${r.stdout}', contains('WAsyncController'));
    expect('${r.stdout}', contains('c.load()'));
  });

  test('explain WAsync 输出 usage / related，tryRun 可精确命中', () async {
    final json = await _run('explain.dart', ['WAsync', '--format=json']);
    final payload = jsonDecode('${json.stdout}') as Map<String, Object?>;
    final component = (payload['components'] as List).single as Map<String, Object?>;
    expect(component['usage'], contains('WAsync.tryRun'));
    expect(component['related'], contains('WAsyncResult'));
    expect(component['pitfalls'], contains('run 失败抛异常；tryRun 不抛异常'));

    final prompt = await _run('explain.dart', ['WAsync', '--format=prompt']);
    expect(prompt.exitCode, 0);
    expect('${prompt.stdout}', contains('WAsync.tryRun'));
    expect('${prompt.stdout}', contains('注意：'));

    final alias = await _run('explain.dart', ['tryRun']);
    expect(alias.exitCode, 0);
    expect('${alias.stdout}', contains('WAsync / WAsyncOptions'));

    final themeViews = await _run('explain.dart', ['WAsyncThemeViews']);
    expect(themeViews.exitCode, 0);
    expect('${themeViews.stdout}', contains('WAsyncThemeViews.of(context)'));
  });

  test('context 对坏配置报配置文件名', () async {
    final root = _project();
    File(p.join(root.path, '.w_tools_doctor.yaml')).writeAsStringSync('banned: [');
    final r = await _run('context.dart', ['--root', root.path]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('.w_tools_doctor.yaml'));
    expect('${r.stderr}', isNot(contains('pubspec.yaml')));
  });

  test('context 对坏 pubspec.lock 报 lock 文件名', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('packages: [');
    final r = await _run('context.dart', ['--root', root.path]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('pubspec.lock'));
  });

  test('explain --root 读取项目 banned', () async {
    final root = _project();
    File(p.join(root.path, '.w_tools_doctor.yaml')).writeAsStringSync('''
banned:
  - id: no-wimage
    pattern: WImage
    use: AppImage
    reason: project ban
''');
    final r = await _run('explain.dart', ['WImage', '--root', root.path]);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('本项目禁用'));
    expect('${r.stdout}', contains('AppImage'));
  });

  test('doctor --print-config 不要求项目目录', () async {
    final empty = Directory.systemTemp.createTempSync('wt_cli_empty_');
    final r = await _run('doctor.dart', ['--root', empty.path, '--print-config']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('toolkit_entry'));
  });

  test('init 保留上次 profile / targets / lang', () async {
    final root = _project();
    final first = await _run('init.dart', [
      '--root',
      root.path,
      '--profile=minimal',
      '--targets=claude',
      '--lang=en',
    ]);
    expect(first.exitCode, 0);

    final second = await _run('init.dart', ['--root', root.path]);
    expect(second.exitCode, 0);
    expect('${second.stdout}', contains('profile: minimal'));
    expect('${second.stdout}', contains('targets: claude'));
    expect(File(p.join(root.path, 'CLAUDE.md')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'AGENTS.md')).existsSync(), isFalse);
  });

  test('list 无匹配时退出码 1', () async {
    final r = await _run('list.dart', ['绝对不存在的组件']);
    expect(r.exitCode, 1);
  });

  test('feedback 缺少子命令时退出码 2', () async {
    final root = _project();
    final r = await _run('feedback.dart', ['--root', root.path]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('path'));
    expect('${r.stderr}', contains('lint'));
  });

  test('init 命令体错误也输出 JSON', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).deleteSync();
    final r = await _run('init.dart', ['--root', root.path, '--json']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
  });

  test('--json 与 --format 冲突时退出码 2', () async {
    final root = _project();
    final r = await _run('doctor.dart', [
      '--root',
      root.path,
      '--json',
      '--format=markdown',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('冲突'));
    expect('${r.stdout}', contains('"ok":false'));
  });

  test('feedback submit 默认无通道时跳过', () async {
    final root = _project();
    final body = File(p.join(root.path, 'body.md'))
      ..writeAsStringSync('''
- 包/版本：w_tools_ui 5.0.0
- 环境：Flutter 3.44 / macOS
- 命令 / 输入：WImage(...)
- 期望：显示
- 实际：空白
- 影响：页面不可用
- 建议：补提示
- 复现数据：见附件
''');
    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=ui',
      '--title=WImage 空白',
      '--body-file',
      body.path,
    ]);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('反馈未提交'));
    expect(File(p.join(root.path, 'docs', 'agents', 'feedback.md')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'docs', 'feedback')).existsSync(), isFalse);
  });

  test('feedback submit --json 缺字段也输出 JSON', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
    Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    final body = File(p.join(root.path, 'body.md'))..writeAsStringSync('- 包/版本：ui\n');
    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=ui',
      '--title=t',
      '--body-file',
      body.path,
      '--json',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
    expect('${r.stdout}', contains('反馈缺少必填字段'));
  });

  test('feedback submit 默认优先写本地台账', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
    Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    File(p.join(root.path, 'docs', 'feedback', 'README.md')).writeAsStringSync('''
| 包 | 待处理 | 最近更新 |
| --- | --- | --- |
| [ui](ui.md) | 0 | 2026-11-04 |
''');
    File(p.join(root.path, 'docs', 'feedback', 'ui.md')).writeAsStringSync('''
# w_tools_ui 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
''');
    final body = File(p.join(root.path, 'body.md'))
      ..writeAsStringSync('''
- 包/版本：w_tools_ui 5.0.0
- 环境：macOS
- 命令 / 输入：WImage
- 期望：显示
- 实际：空白
- 影响：无
- 建议：补提示
- 复现数据：无
''');
    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=ui',
      '--title=WImage 空白',
      '--body-file',
      body.path,
    ]);
    expect(r.exitCode, 0);
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'ui.md')).readAsStringSync(),
      contains('### [待处理] ui: WImage 空白'),
    );
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'README.md')).readAsStringSync(),
      contains('| [ui](ui.md) | 1 |'),
    );
  });
  test('消费方自带 docs/feedback 不会被误写', () async {
    final root = _project();
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    File(p.join(root.path, 'docs', 'feedback', 'README.md')).writeAsStringSync(
      '| 包 | 待处理 | 最近更新 |\n| --- | --- | --- |\n',
    );
    final body = File(p.join(root.path, 'body.md'))
      ..writeAsStringSync('''
- 包/版本：w_tools_ui 5.0.0
- 环境：macOS
- 命令 / 输入：WImage
- 期望：显示
- 实际：空白
- 影响：无
- 建议：补提示
- 复现数据：无
''');
    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=ui',
      '--title=WImage 空白',
      '--body-file',
      body.path,
    ]);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('反馈未提交'));
    expect(File(p.join(root.path, 'docs', 'feedback', 'ui.md')).existsSync(), isFalse);
  });

  test('未知包名直接拒绝', () async {
    final root = _project();
    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=foo',
      '--title=x',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('未知反馈包'));
  });

  test('feedback status 输出通道', () async {
    final root = _project();
    final r = await _run('feedback.dart', ['status', '--root', root.path, '--json']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('"channel":"disabled"'));
  });
  test('feedback status 在仓库内输出 ledger', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
    Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    final r = await _run('feedback.dart', ['status', '--root', root.path, '--json']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('"channel":"ledger"'));
  });

  test('init 自动检测 w_tools_device 并生成设备脚手架', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync(
      'name: demo_app\n'
      'environment:\n  sdk: ^3.10.0\n'
      'dev_dependencies:\n  w_tools_device: ^0.1.2\n',
    );
    final r = await _run('init.dart', ['--root', root.path, '--profile=minimal']);
    expect(r.exitCode, 0);
    expect(
      File(p.join(root.path, 'docs', 'agents', 'device-testing.md')).existsSync(),
      isTrue,
    );
    expect(File(p.join(root.path, 'tool', 'device_smoke.dart')).existsSync(), isFalse);
    expect(
      File(p.join(root.path, '.w_tools', 'init.json')).readAsStringSync(),
      contains('"device": true'),
    );
  });

  test('--device-test 保留 deprecated shim', () async {
    final root = _project();
    final r = await _run('init.dart', ['--root', root.path, '--device-test']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('--device-test 已移除'));
    expect(
      File(p.join(root.path, 'docs', 'agents', 'device-testing.md')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(root.path, 'integration_test', 'app_keepalive_smoke_test.dart')).existsSync(),
      isFalse,
    );
  });
}
