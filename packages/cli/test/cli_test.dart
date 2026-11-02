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

  test('init --no-instructions 不生成 AGENTS', () async {
    final root = _project();
    expect((await _run('init.dart', ['--root', root.path, '--no-instructions'])).exitCode, 0);
    expect(File(p.join(root.path, 'AGENTS.md')).existsSync(), isFalse);
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

  test('doctor --write-config：已存在返回 1，--force 才覆盖', () async {
    final root = _project();
    final config = File(p.join(root.path, '.w_tools_doctor.yaml'));

    final first = await _run('doctor.dart', ['--root', root.path, '--write-config']);
    expect(first.exitCode, 0);
    expect(config.existsSync(), isTrue);

    final second = await _run('doctor.dart', ['--root', root.path, '--write-config']);
    expect(second.exitCode, 1);
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
    expect(json['created'], isA<List<Object?>>());
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
}
