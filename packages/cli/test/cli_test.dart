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
Future<ProcessResult> _run(
  String bin,
  List<String> args, {
  Map<String, String>? env,
}) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'bin/$bin', ...args],
    workingDirectory: Directory.current.path,
    environment: env,
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
      isNot(contains('设计稿取数')),
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

  test('init --force 保留自定义 config；--force-config 才覆盖', () async {
    final root = _project();
    final config = File(p.join(root.path, '.w_tools_doctor.yaml'));
    expect(
      (await _run('init.dart', [
        '--root',
        root.path,
        '--profile=minimal',
        '--no-instructions',
      ])).exitCode,
      0,
    );
    const custom = '# 我改过\nfeedback:\n  issue: true\n';
    config.writeAsStringSync(custom);

    final force = await _run('init.dart', [
      '--root',
      root.path,
      '--profile=minimal',
      '--no-instructions',
      '--force',
      '--format=json',
    ]);
    expect(force.exitCode, 0, reason: '${force.stderr}');
    expect(config.readAsStringSync(), custom);
    expect('${force.stdout}', contains('--force-config'));

    final forceConfig = await _run('init.dart', [
      '--root',
      root.path,
      '--profile=minimal',
      '--no-instructions',
      '--force-config',
      '--format=json',
    ]);
    expect(forceConfig.exitCode, 0, reason: '${forceConfig.stderr}');
    expect(config.readAsStringSync(), contains('由 `dart run w_tools_cli:w_tools doctor'));
    expect(File('${config.path}.bak').readAsStringSync(), custom);
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

  test('doctor --write-config --force 连续覆盖不丢旧备份', () async {
    final root = Directory.systemTemp.createTempSync('wt_wcfg_rot_');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
    final cfg = File(p.join(root.path, '.w_tools_doctor.yaml'));
    expect((await _run('doctor.dart', ['--root', root.path, '--write-config'])).exitCode, 0);

    cfg.writeAsStringSync('# user A\nfeedback:\n  issue: true\n');
    expect(
      (await _run('doctor.dart', ['--root', root.path, '--write-config', '--force'])).exitCode,
      0,
    );
    expect(File('${cfg.path}.bak').readAsStringSync(), contains('user A'));

    cfg.writeAsStringSync('# user B\nfeedback:\n  issue: false\n');
    expect(
      (await _run('doctor.dart', ['--root', root.path, '--write-config', '--force'])).exitCode,
      0,
    );
    expect(
      File('${cfg.path}.bak').readAsStringSync(),
      contains('user A'),
      reason: '已有 .bak 不能被第二次 force 覆盖',
    );
    final stamped = Directory(root.path)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('.w_tools_doctor.yaml.bak.'))
        .toList();
    expect(stamped, isNotEmpty);
    expect(stamped.any((f) => f.readAsStringSync().contains('user B')), isTrue);
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

  test('CLI-007 explain 多匹配返回 1 且 JSON 标记 ambiguous', () async {
    final prompt = await _run('explain.dart', ['W', '--format=prompt']);
    expect(prompt.exitCode, 1);
    expect('${prompt.stdout}', contains('缩小关键词'));

    final json = await _run('explain.dart', ['W', '--format=json']);
    expect(json.exitCode, 1);
    final payload = jsonDecode('${json.stdout}') as Map<String, Object?>;
    expect(payload['ambiguous'], isTrue);
    expect(payload['found'], isFalse);
  });

  test('list --format=prompt 输出紧凑目录', () async {
    final r = await _run('list.dart', ['async', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('# w_tools catalog'));
    expect('${r.stdout}', contains('WAsyncController'));
    expect('${r.stdout}', contains('c.load()'));
  });

  test('list --package 只输出目标包', () async {
    final r = await _run('list.dart', ['--package', 'w_tools_ui', '--format=prompt']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final out = '${r.stdout}';
    expect(out, contains('[w_tools_ui]'));
    expect(out, isNot(contains('[w_tools_form]')));
    final count = RegExp(r'^- ', multiLine: true).allMatches(out).length;
    expect(count, greaterThanOrEqualTo(30), reason: 'ui 目录没有列全');
  });

  test('list 位置参数 ui 按包名过滤', () async {
    final r = await _run('list.dart', ['ui', '--format=prompt']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final out = '${r.stdout}';
    expect(out, isNot(contains('[w_tools_form]')));
    final count = RegExp(r'^- ', multiLine: true).allMatches(out).length;
    expect(count, greaterThanOrEqualTo(30), reason: 'list ui 仍按关键词搜索');
  });

  test('explain WLanguage 覆盖 changeLanguage', () async {
    final r = await _run('explain.dart', ['WLanguage', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('用法：'));
    expect('${r.stdout}', contains('changeLanguage'));
  });

  test('explain WLocaleConfig 命中自身', () async {
    final r = await _run('explain.dart', ['WLocaleConfig', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', startsWith('# WLocaleConfig '));
  });

  test('explain WAppOptions 覆盖 appWrapper / localeConfig', () async {
    final r = await _run('explain.dart', ['WAppOptions', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('appWrapper'));
    expect('${r.stdout}', contains('localeConfig'));
  });

  test('explain WBottomSheet 覆盖 show', () async {
    final r = await _run('explain.dart', ['WBottomSheet', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('show'));
  });

  test('explain WApp 的文档带章节锚点', () async {
    final r = await _run('explain.dart', ['WApp', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', matches(RegExp(r'文档：.*#1-wapp')));
  });

  test('explain WAsyncView 覆盖 per-view builder', () async {
    final r = await _run('explain.dart', ['WAsyncView', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('errorBuilder'));
    expect('${r.stdout}', contains('onRetryError'));
  });

  test('explain WAsyncPagedController 覆盖 loadMore', () async {
    final r = await _run('explain.dart', ['WAsyncPagedController', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('loadMore'));
  });

  test('explain WAsyncState 覆盖 status', () async {
    final r = await _run('explain.dart', ['WAsyncState', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('status'));
  });

  test('explain WAsyncStrings 命中自身', () async {
    final r = await _run('explain.dart', ['WAsyncStrings', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', startsWith('# WAsyncStrings '));
  });

  test('explain WAsync 的文档带章节锚点', () async {
    final r = await _run('explain.dart', ['WAsync', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', matches(RegExp(r'文档：.*#1-wasync')));
  });

  test('explain WFormController 有用法与 reset', () async {
    final r = await _run('explain.dart', ['WFormController', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('用法：'));
    expect('${r.stdout}', contains('reset'));
  });

  test('explain WFormScope 命中自身而不是 WForm', () async {
    final r = await _run('explain.dart', ['WFormScope', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', startsWith('# WFormScope '));
  });

  test('explain WForm 的文档带章节锚点', () async {
    final r = await _run('explain.dart', ['WForm', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', matches(RegExp(r'文档：.*#36-直接字段与-wform')));
  });

  test('explain 文档链接带章节锚点', () async {
    final r = await _run('explain.dart', ['WImage', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', matches(RegExp(r'文档：.*#4-wimage')));
  });

  test('explain prompt 带示例链接', () async {
    final r = await _run('explain.dart', ['WImage', '--format=prompt']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('示例：'));
    expect('${r.stdout}', contains('packages/ui/example'));
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
    expect('${alias.stdout}', startsWith('WAsync  (w_tools_async)'));

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

  test('explain 读取 lock 版本并给出 API 文档', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync(
      'packages:\n  w_tools_ui:\n    version: "1.1.0"\n',
    );
    final r = await _run('explain.dart', [
      'WImage',
      '--root',
      root.path,
      '--format=prompt',
    ]);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('包版本：w_tools_ui 1.1.0'));
    expect(
      '${r.stdout}',
      contains('API 文档：https://pub.dev/documentation/w_tools_ui/1.1.0/'),
    );
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

  test('CLI-005 list 工具包在 prompt / json 也给教学入口', () async {
    final prompt = await _run('list.dart', ['--package=cli', '--format=prompt']);
    expect(prompt.exitCode, 1);
    expect('${prompt.stdout}', contains('docs/agents/cli.md'));

    final json = await _run('list.dart', ['--package=cli', '--format=json']);
    expect(json.exitCode, 1);
    expect('${json.stdout}', contains('"hint"'));
    expect('${json.stdout}', contains('docs/agents/cli.md'));
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
    expect(r.exitCode, 4);
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
    expect(r.exitCode, 4);
    expect('${r.stdout}', contains('反馈未提交'));
    expect(File(p.join(root.path, 'docs', 'feedback', 'ui.md')).existsSync(), isFalse);
  });

  test('feedback 写本机检出时提示工作区会变脏', () async {
    final root = Directory.systemTemp.createTempSync('wt_fb_dirty_');
    addTearDown(() => root.deleteSync(recursive: true));
    final repo = Directory(p.join(root.path, 'repo'))..createSync(recursive: true);
    File(p.join(repo.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
    final cli = Directory(p.join(repo.path, 'packages', 'cli'))..createSync(recursive: true);
    File(p.join(cli.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
    final feedback = Directory(p.join(repo.path, 'docs', 'feedback'))..createSync(recursive: true);
    File(p.join(feedback.path, 'README.md')).writeAsStringSync(
      '| 包 | 待处理 | 最近更新 |\n| --- | --- | --- |\n| [api](api.md) | 0 | 2026-11-04 |\n',
    );
    final app = Directory(p.join(root.path, 'app'))..createSync(recursive: true);
    File(p.join(app.path, 'pubspec.yaml')).writeAsStringSync('name: demo_app\n');
    File(p.join(app.path, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {'name': 'w_tools_cli', 'rootUri': cli.path},
          ],
        }),
      );
    File(
      p.join(app.path, '.w_tools_doctor.yaml'),
    ).writeAsStringSync('feedback:\n  enabled: true\n');
    final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_feedbackBody);

    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      app.path,
      '--package=ui',
      '--title=WImage 空白',
      '--body-file',
      body.path,
    ]);

    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(File(p.join(feedback.path, 'ui.md')).existsSync(), isTrue);
    expect('${r.stderr}', contains('工作区会变脏'));
  });

  test('feedback 公开 Issue 日额度用完后 exit 2', () async {
    final root = _project();
    // 没有本机仓库：确保走 Issue 通道
    final cache = Directory(p.join(root.path, 'pubcache', 'w_tools_cli'))
      ..createSync(recursive: true);
    File(p.join(cache.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
    File(p.join(root.path, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {'name': 'w_tools_cli', 'rootUri': cache.path},
          ],
        }),
      );
    File(tmpConfig(root)).writeAsStringSync('feedback:\n  enabled: true\n');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    File(p.join(root.path, '.w_tools', 'feedback_budget.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({'date': today, 'count': 5}));
    final body = File(p.join(root.path, 'body.md'))..writeAsStringSync(_feedbackBody);

    final r = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=ui',
      '--title=t',
      '--body-file',
      body.path,
      '--repo=stone0533/__w_tools_feedback_guard__',
    ]);

    expect(r.exitCode, 2, reason: '${r.stderr}');
    expect('${r.stderr}', contains('额度'));
    expect('${r.stderr}', contains('已用 5 / 上限 5'));
    expect('${r.stderr}', contains('feedback.max_issues_per_day'));
    expect('${r.stderr}', contains('feedback_budget.json'));
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

  test('CLI-006 feedback search 拒绝未知包', () async {
    final root = _project();
    final r = await _run('feedback.dart', [
      'search',
      'nothing',
      '--root',
      root.path,
      '--package=foo',
    ]);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('未知反馈包'));
  });

  test('feedback status 输出通道', () async {
    final root = _project();
    final r = await _run('feedback.dart', ['status', '--root', root.path, '--json']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('"channel":"disabled"'));
    expect('${r.stdout}', contains('"enableHint"'));
    expect('${r.stdout}', contains('"budget"'));
    expect('${r.stdout}', contains('"used":0'));
    expect('${r.stdout}', contains('"max":5'));
    expect('${r.stdout}', contains('"remaining":5'));
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

  test('CLI-001 init 拒绝越界 toolkit_entry，且不写项目外文件', () async {
    final base = Directory.systemTemp.createTempSync('wt_escape_');
    addTearDown(() => base.deleteSync(recursive: true));
    final root = Directory(p.join(base.path, 'proj'))..createSync(recursive: true);
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: demo_app\n');
    File(
      p.join(root.path, '.w_tools_doctor.yaml'),
    ).writeAsStringSync('toolkit_entry: ../escaped/toolkit.dart\n');

    final r = await _run('init.dart', ['--root', root.path]);

    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('toolkit_entry'));
    expect(File(p.join(base.path, 'escaped', 'toolkit.dart')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'lib', 'app', 'w', 'toolkit.dart')).existsSync(), isFalse);
  });

  test('CLI-002 坏配置类型不再抛栈（context）', () async {
    final root = _project();
    File(tmpConfig(root)).writeAsStringSync('toolkit_entry: [a, b]\n');

    final r = await _run('context.dart', ['--root', root.path, '--format=json']);

    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
    expect('${r.stderr}', isNot(contains('TypeError')));
    expect('${r.stderr}', isNot(contains('#0')));
  });

  test('CLI-002 / CLI-009 无 gh 时 feedback --issue 退出 3 且不抛栈', () async {
    final root = _project();
    // 消费方 + 没有本地仓库 + 已开启反馈 → Issue 通道，才会去调 gh。
    final cache = Directory(p.join(root.path, 'pubcache', 'w_tools_cli'))
      ..createSync(recursive: true);
    File(p.join(cache.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools_cli\n');
    File(p.join(root.path, '.dart_tool', 'package_config.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '{"configVersion":2,"packages":[{"name":"w_tools_cli","rootUri":"${cache.path}"}]}',
      );
    File(tmpConfig(root)).writeAsStringSync('feedback:\n  enabled: true\n');
    final body = File(p.join(root.path, 'body.md'))
      ..writeAsStringSync('''
- 包/版本：ui 1.0.0
- 环境：test
- 命令 / 输入：x
- 期望：a
- 实际：b
- 影响：c
- 建议：d
- 复现数据：e
''');

    final r = await _run(
      'feedback.dart',
      [
        'submit',
        '--root',
        root.path,
        '--package=ui',
        '--title=t',
        '--body-file',
        body.path,
        '--issue',
      ],
      env: <String, String>{'PATH': '/usr/bin:/bin'},
    );

    expect(r.exitCode, 3, reason: '${r.stderr}');
    expect('${r.stderr}', isNot(contains('ProcessException')));
    expect('${r.stderr}', isNot(contains('#0')));
  });

  test('CLI-009 feedback search --gh 无 gh 也退出 3', () async {
    final root = _project();
    final r = await _run(
      'feedback.dart',
      ['search', 'needle', '--root', root.path, '--gh'],
      env: <String, String>{'PATH': '/usr/bin:/bin'},
    );
    expect(r.exitCode, 3, reason: '${r.stderr}');
    expect('${r.stderr}', isNot(contains('#')));
  });

  test('CLI-003 explain --json 缺组件名输出 JSON 错误', () async {
    final r = await _run('explain.dart', ['--json']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
  });

  test('CLI-004 context --format=json 坏 lock 输出 JSON 错误', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('packages: [');
    final r = await _run('context.dart', ['--root', root.path, '--format=json']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
    expect('${r.stdout}', contains('pubspec.lock'));
  });

  test('CLI-005 doctor --print-config / --write-config 支持 --json，--force 需配套', () async {
    final root = _project();

    final printConfig = await _run('doctor.dart', ['--print-config', '--json']);
    expect(printConfig.exitCode, 0, reason: '${printConfig.stderr}');
    final printed = jsonDecode('${printConfig.stdout}') as Map<String, Object?>;
    expect(printed['schema'], isNotEmpty);
    expect('${printed['config']}', contains('toolkit_entry'));

    final writeConfig = await _run('doctor.dart', [
      '--root',
      root.path,
      '--write-config',
      '--json',
    ]);
    expect(writeConfig.exitCode, 0, reason: '${writeConfig.stderr}');
    final written = jsonDecode('${writeConfig.stdout}') as Map<String, Object?>;
    expect(written['written'], endsWith('.w_tools_doctor.yaml'));

    final forceOnly = await _run('doctor.dart', ['--root', root.path, '--force']);
    expect(forceOnly.exitCode, 2);
    expect('${forceOnly.stderr}', contains('--write-config'));
  });

  test('CLI-010 JSON 输出带 schema', () async {
    final root = _project();

    final doctor =
        jsonDecode(
              '${(await _run('doctor.dart', ['--root', root.path, '--json'])).stdout}',
            )
            as Map<String, Object?>;
    expect(doctor['schema'], 'w_tools_cli.doctor/1');
    expect(doctor['schemaVersion'], 1);

    final list =
        jsonDecode(
              '${(await _run('list.dart', ['WForm', '--format=json'])).stdout}',
            )
            as Map<String, Object?>;
    expect(list['schema'], 'w_tools_cli.list/1');

    final explain =
        jsonDecode(
              '${(await _run('explain.dart', ['WForm', '--json'])).stdout}',
            )
            as Map<String, Object?>;
    expect(explain['schema'], 'w_tools_cli.explain/1');

    final status =
        jsonDecode(
              '${(await _run('feedback.dart', ['status', '--root', root.path, '--json'])).stdout}',
            )
            as Map<String, Object?>;
    expect(status['schema'], 'w_tools_cli.feedback/1');
  });

  test('CLI-016 --format json 的空格写法在错误时也输出 JSON', () async {
    final r = await _run('list.dart', ['--format', 'json', '--bogus']);
    expect(r.exitCode, 2);
    expect('${r.stdout}', contains('"ok":false'));
  });

  test('CLI-017 init --help 列出 --instructions / --force-config', () async {
    final r = await _run('init.dart', ['--help']);
    expect(r.exitCode, 0);
    expect('${r.stdout}', contains('--instructions'));
    expect('${r.stdout}', contains('--force-config'));
  });

  test('CLI-007 feedback path 拒绝未知包', () async {
    final root = _project();
    final r = await _run('feedback.dart', ['path', '--root', root.path, '--package=foo']);
    expect(r.exitCode, 2);
    expect('${r.stderr}', contains('未知反馈包'));
  });

  test('CLI-007 feedback path 与 submit 对 app_getx 一致', () async {
    final root = _project();
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: w_tools\n');
    Directory(p.join(root.path, 'packages', 'cli')).createSync(recursive: true);
    Directory(p.join(root.path, 'docs', 'feedback')).createSync(recursive: true);
    File(p.join(root.path, 'docs', 'feedback', 'README.md')).writeAsStringSync('''
# 反馈

| 包 | 待处理 | 最近更新 |
| --- | --- | --- |
| [api](api.md) | 0 | 2026-11-04 |
''');

    final path = await _run('feedback.dart', [
      'path',
      '--root',
      root.path,
      '--package=app_getx',
    ]);
    expect(path.exitCode, 0);
    expect('${path.stdout}', contains('app_getx.md'));

    final body = File(p.join(root.path, 'body.md'))
      ..writeAsStringSync('''
- 包/版本：app_getx 1.0.0
- 环境：test
- 命令 / 输入：x
- 期望：a
- 实际：b
- 影响：c
- 建议：d
- 复现数据：e
''');
    final submit = await _run('feedback.dart', [
      'submit',
      '--root',
      root.path,
      '--package=app_getx',
      '--title=t',
      '--body-file',
      body.path,
      '--ledger',
    ]);
    expect(submit.exitCode, 0, reason: '${submit.stderr}');
    expect(
      File(p.join(root.path, 'docs', 'feedback', 'app_getx.md')).existsSync(),
      isTrue,
    );
  });

  test('CLI-011 list --package=cli 给出工具包教学入口提示', () async {
    final r = await _run('list.dart', ['--package=cli']);
    expect(r.exitCode, 1);
    expect('${r.stdout}', contains('docs/agents/cli.md'));
  });
}

String tmpConfig(Directory root) => p.join(root.path, '.w_tools_doctor.yaml');

/// 字段齐全的反馈正文，submit 用例共用。
const _feedbackBody = '''
- 包/版本：w_tools_ui 5.0.0
- 环境：macOS
- 命令 / 输入：WImage
- 期望：显示
- 实际：空白
- 影响：无
- 建议：补提示
- 复现数据：无
''';
