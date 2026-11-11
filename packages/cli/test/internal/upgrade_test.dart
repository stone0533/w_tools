import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_cli/src/upgrade/hosted.dart';
import 'package:w_tools_cli/src/upgrade/pubspec_edit.dart';
import 'package:w_tools_cli/src/upgrade/upgrade_command.dart' as command;
import 'package:w_tools_cli/src/upgrade/upgrade_plan.dart';
import 'package:w_tools_cli/src/upgrade/upgrade_report.dart';

/// upgrade 的三段纯逻辑（计划 / 编辑 / 报告）+ 一条本地 HTTP 的取数测试。
/// 命令层用假 [LatestFetcher] 注入，测试不联网、不跑 pub。

LatestRelease _rel(String version, {String? sdk = '^3.10.0'}) =>
    LatestRelease(version: version, sdkConstraint: sdk);

class _FakeFetcher implements LatestFetcher {
  _FakeFetcher(this.hosted, this.releases);

  @override
  final String hosted;
  final Map<String, LatestRelease?> releases;
  final List<String> requested = <String>[];

  @override
  Future<Map<String, LatestRelease?>> fetch(Iterable<String> names) async {
    requested.addAll(names);
    return <String, LatestRelease?>{for (final name in names) name: releases[name]};
  }
}

const _pubspec = '''
name: demo_app
environment:
  sdk: ^3.5.4

dependencies:
  flutter:
    sdk: flutter
  # 刻意钉死：retrofit 4.9.2 起 Parser 枚举新增值，build_runner 会编译失败。
  retrofit: 4.9.0
  w_tools_core: ^3.1.1
  w_tools_ui: ^8.0.1 # 行尾注释：不要丢
  w_tools_async: ^6.1.0
  w_tools_map:
    path: ../w_tools_map

dev_dependencies:
  w_tools_cli: ^1.18.0
  w_tools_figma: ^0.13.1

dependency_overrides:
  w_tools_map: ^3.0.0
''';

const _lock = '''
packages:
  w_tools_core:
    dependency: "direct main"
    version: "3.1.1"
  w_tools_ui:
    dependency: "direct main"
    version: "8.0.1"
  w_tools_async:
    dependency: "direct main"
    version: "6.1.0"
  w_tools_cli:
    dependency: "direct dev"
    version: "1.18.0"
  w_tools_figma:
    dependency: "direct dev"
    version: "0.13.1"
sdks:
  dart: ">=3.5.4 <4.0.0"
''';

Directory _project({String pubspec = _pubspec, String? lock = _lock, String name = 'demo_app'}) {
  final root = Directory.systemTemp.createTempSync('wt_upgrade_');
  addTearDown(() => root.deleteSync(recursive: true));
  File(
    '${root.path}/pubspec.yaml',
  ).writeAsStringSync(pubspec.replaceFirst('name: demo_app', 'name: $name'));
  if (lock != null) File('${root.path}/pubspec.lock').writeAsStringSync(lock);
  return root;
}

Map<String, LatestRelease?> _latest() => <String, LatestRelease?>{
  'w_tools_core': _rel('3.1.2'),
  'w_tools_ui': _rel('8.1.0'),
  'w_tools_async': _rel('6.1.0'),
  'w_tools_cli': _rel('1.18.2'),
  'w_tools_figma': _rel('0.13.2'),
};

Future<(int, String)> _run(
  List<String> argv, {
  LatestFetcher? fetcher,
  command.PubRunner? pubRunner,
}) async {
  final out = <String>[];
  final code = await runZoned(
    () async => (await command.run(argv, fetcher: fetcher, pubRunner: pubRunner)).exitCode,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => out.add(line),
    ),
  );
  return (code, out.join('\n'));
}

void main() {
  group('SemVer / caret', () {
    test('平台版本串取第一个 token', () {
      expect(SemVer.tryParse('3.12.2 (stable) (Tue Jun 9 2026)')?.toString(), '3.12.2');
      expect(SemVer.tryParse('3.12.2-dev.1'), const SemVer(3, 12, 2));
      expect(SemVer.tryParse('v3.12.2'), isNull);
    });

    test('caret 上界按 semver：8.x / 0.x / 0.0.x', () {
      expect(const SemVer(8, 1, 0).caretUpperBound(), const SemVer(9, 0, 0));
      expect(const SemVer(0, 13, 1).caretUpperBound(), const SemVer(0, 14, 0));
      expect(const SemVer(0, 0, 3).caretUpperBound(), const SemVer(0, 0, 4));
    });

    test('sdk 约束只认能解析的写法，解析不了返回 null（不拦）', () {
      expect(satisfiesConstraint('^3.10.0', const SemVer(3, 12, 2)), isTrue);
      expect(satisfiesConstraint('^3.10.0', const SemVer(3, 9, 9)), isFalse);
      expect(satisfiesConstraint('>=3.9.0 <4.0.0', const SemVer(3, 12, 2)), isTrue);
      expect(satisfiesConstraint('>=3.9.0 <4.0.0', const SemVer(4, 0, 0)), isFalse);
      expect(satisfiesConstraint('>=3.9.0 <4.0.0', const SemVer(3, 8, 0)), isFalse);
      expect(satisfiesConstraint('any', const SemVer(3, 12, 2)), isNull);
      expect(satisfiesConstraint(null, const SemVer(3, 12, 2)), isNull);
    });

    test('只接受 caret 约束；精确钉死 / any 交给人工', () {
      expect(parseCaretConstraint('^8.0.1'), const SemVer(8, 0, 1));
      expect(parseCaretConstraint('4.9.0'), isNull);
      expect(parseCaretConstraint('any'), isNull);
      expect(parseCaretConstraint('>=8.0.0 <9.0.0'), isNull);
    });
  });

  group('buildPlan', () {
    UpgradePlan plan({
      Map<String, LatestRelease?>? latest,
      bool allowMajor = false,
      Set<String> only = const <String>{},
      Set<String> overrides = const <String>{},
      String dart = '3.12.2',
      Map<String, String>? locked,
    }) {
      return buildPlan(
        hosted: 'https://example.test',
        dependencies: <String, Object?>{
          'flutter': <String, String>{'sdk': 'flutter'},
          'retrofit': '4.9.0',
          'w_tools_core': '^3.1.1',
          'w_tools_ui': '^8.0.1',
          'w_tools_async': '^6.1.0',
          'w_tools_map': <String, String>{'path': '../w_tools_map'},
        },
        devDependencies: <String, Object?>{
          'w_tools_cli': '^1.18.0',
          'w_tools_figma': '^0.13.1',
        },
        locked:
            locked ??
            const <String, String>{
              'w_tools_core': '3.1.1',
              'w_tools_ui': '8.0.1',
              'w_tools_async': '6.1.0',
              'w_tools_cli': '1.18.0',
              'w_tools_figma': '0.13.1',
            },
        latest: latest ?? _latest(),
        overrides: overrides,
        allowMajor: allowMajor,
        only: only,
        dartVersion: dart,
      );
    }

    PackageUpgrade byName(UpgradePlan p, String name) =>
        p.packages.firstWhere((pkg) => pkg.name == name);

    test('同 caret 窗口的包可升，目标写成 ^最新', () {
      final p = plan();
      expect(byName(p, 'w_tools_core').status, UpgradeStatus.outdated);
      expect(byName(p, 'w_tools_core').target, '^3.1.2');
      expect(byName(p, 'w_tools_ui').target, '^8.1.0');
      expect(byName(p, 'w_tools_async').status, UpgradeStatus.upToDate);
      expect(p.hasFindings, isTrue);
      expect(p.writable.length, 4);
    });

    test('跨 major 默认只报告；--major 才可升', () {
      final blocked = plan(latest: {'w_tools_ui': _rel('9.0.0')});
      expect(byName(blocked, 'w_tools_ui').status, UpgradeStatus.majorBlocked);
      expect(byName(blocked, 'w_tools_ui').target, isNull);
      expect(blocked.hasRisks, isTrue);

      final allowed = plan(latest: {'w_tools_ui': _rel('9.0.0')}, allowMajor: true);
      expect(byName(allowed, 'w_tools_ui').status, UpgradeStatus.outdated);
      expect(byName(allowed, 'w_tools_ui').target, '^9.0.0');
    });

    test('0.x 包跨 minor 按跨 major 处理', () {
      final p = plan(latest: {'w_tools_figma': _rel('0.14.0')});
      expect(byName(p, 'w_tools_figma').status, UpgradeStatus.majorBlocked);
      expect(byName(p, 'w_tools_figma').reason, contains('0.14.0'));
    });

    test('lock 落后但下界已最新也算 findings', () {
      final p = plan(
        latest: {'w_tools_async': _rel('6.1.0')},
        locked: {'w_tools_async': '6.0.9'},
      );
      final async = byName(p, 'w_tools_async');
      expect(async.status, UpgradeStatus.upToDate);
      expect(async.lockBehind, isTrue);
      expect(p.hasFindings, isTrue);
    });

    test('SDK 不兼容时不写，并给出原因', () {
      final p = plan(
        dart: '3.9.0',
        latest: {'w_tools_ui': _rel('8.1.0', sdk: '^3.10.0')},
      );
      final ui = byName(p, 'w_tools_ui');
      expect(ui.status, UpgradeStatus.sdkBlocked);
      expect(ui.reason, contains('^3.10.0'));
      expect(ui.target, isNull);
    });

    test('override / path / 精确钉死 / 非 caret 都是 skipped（带原因）', () {
      final p = plan(overrides: {'w_tools_core'});
      expect(byName(p, 'w_tools_core').status, UpgradeStatus.skipped);
      expect(byName(p, 'w_tools_core').reason, contains('dependency_overrides'));
      expect(byName(p, 'w_tools_map').status, UpgradeStatus.skipped);
      expect(byName(p, 'w_tools_map').reason, contains('path / git'));
      expect(p.packages.map((pkg) => pkg.name), isNot(contains('retrofit')));
    });

    test('--only 只考虑指名的包，其余显式 skipped', () {
      final p = plan(only: {'w_tools_ui'});
      expect(byName(p, 'w_tools_ui').status, UpgradeStatus.outdated);
      expect(byName(p, 'w_tools_core').status, UpgradeStatus.skipped);
      expect(byName(p, 'w_tools_core').reason, contains('--only'));
      expect(p.writable.length, 1);
    });

    test('hosted 上找不到的包是 skipped，不是 outdated', () {
      final p = plan(latest: {'w_tools_ui': null});
      expect(byName(p, 'w_tools_ui').status, UpgradeStatus.skipped);
      expect(byName(p, 'w_tools_ui').reason, contains('找不到'));
    });
  });

  group('raiseConstraints', () {
    test('只改指名包的版本 token，注释与其它字节不动', () {
      final edit = raiseConstraints(_pubspec, {
        'w_tools_ui': '^8.1.0',
        'w_tools_cli': '^1.18.2',
      });
      expect(edit.missed, isEmpty);
      expect(edit.applied, {'w_tools_ui': '^8.1.0', 'w_tools_cli': '^1.18.2'});
      expect(edit.text, contains('w_tools_ui: ^8.1.0 # 行尾注释：不要丢'));
      expect(edit.text, contains('w_tools_cli: ^1.18.2'));
      expect(edit.text, contains('# 刻意钉死：retrofit 4.9.2 起 Parser 枚举新增值'));
      expect(edit.text, contains('retrofit: 4.9.0'));
      // 只差这两行，其余行完全一致。
      final before = _pubspec.split('\n');
      final after = edit.text.split('\n');
      final changed = <int>[
        for (var i = 0; i < before.length; i++)
          if (before[i] != after[i]) i,
      ];
      expect(changed.length, 2);
    });

    test('引号、行尾注释、CRLF 都保留', () {
      const text = "name: x\r\ndependencies:\r\n  w_tools_ui: \"^8.0.1\" # c\r\n";
      final edit = raiseConstraints(text, {'w_tools_ui': '^8.1.0'});
      expect(edit.text, 'name: x\r\ndependencies:\r\n  w_tools_ui: "^8.1.0" # c\r\n');
    });

    test('dependency_overrides / 注释行里的同名内容不动', () {
      const text = '''
name: x
dependencies:
  w_tools_ui: ^8.0.1
dependency_overrides:
  w_tools_ui: ^8.0.0
''';
      final edit = raiseConstraints(text, {'w_tools_ui': '^8.1.0'});
      expect(edit.applied, {'w_tools_ui': '^8.1.0'});
      expect(edit.text, contains('  w_tools_ui: ^8.1.0\n'));
      expect(edit.text, contains('  w_tools_ui: ^8.0.0\n'));
    });

    test('找不到的包进 missed，不静默丢掉', () {
      final edit = raiseConstraints(_pubspec, {'w_tools_missing': '^1.0.0'});
      expect(edit.applied, isEmpty);
      expect(edit.missed, ['w_tools_missing']);
      expect(edit.text, _pubspec);
    });
  });

  group('HttpLatestFetcher', () {
    Future<HttpServer> serve(Object? Function(String name) body) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final name = request.uri.pathSegments.last;
        final payload = body(name);
        if (payload == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else if (payload is int) {
          request.response.statusCode = payload;
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.write(payload);
        }
        await request.response.close();
      });
      return server;
    }

    test('解析 latest.version 与 environment', () async {
      final server = await serve(
        (name) => name == 'w_tools_ui'
            ? '{"latest":{"version":"8.1.0","published":"2026-11-10T00:00:00Z",'
                  '"pubspec":{"environment":{"sdk":"^3.10.0","flutter":">=3.38.0"}}}}'
            : null,
      );
      final fetcher = HttpLatestFetcher(hosted: 'http://127.0.0.1:${server.port}');
      addTearDown(fetcher.close);
      final result = await fetcher.fetch(<String>['w_tools_ui', 'w_tools_nope']);
      expect(result['w_tools_ui']?.version, '8.1.0');
      expect(result['w_tools_ui']?.sdkConstraint, '^3.10.0');
      expect(result['w_tools_ui']?.flutterConstraint, '>=3.38.0');
      expect(result['w_tools_nope'], isNull);
    });

    test('非 200 / 非 JSON 都抛 HostedException（命令层 exit 3）', () async {
      final failing = await serve((_) => HttpStatus.internalServerError);
      final badJson = await serve((_) => 'not json');

      await expectLater(
        HttpLatestFetcher(hosted: 'http://127.0.0.1:${failing.port}').fetch(['w_tools_ui']),
        throwsA(isA<HostedException>()),
      );
      await expectLater(
        HttpLatestFetcher(hosted: 'http://127.0.0.1:${badJson.port}').fetch(['w_tools_ui']),
        throwsA(isA<HostedException>()),
      );
    });

    test('hosted 解析优先级：override > PUB_HOSTED_URL > pub.dev，去掉尾斜杠', () {
      expect(
        resolveHostedUrl(
          override: 'https://mirror.test/',
          environment: {'PUB_HOSTED_URL': 'https://env.test'},
        ),
        'https://mirror.test',
      );
      expect(
        resolveHostedUrl(environment: {'PUB_HOSTED_URL': 'https://env.test/'}),
        'https://env.test',
      );
      expect(resolveHostedUrl(environment: const {}), defaultHostedUrl);
    });
  });

  group('upgrade 命令', () {
    test('--check 有落后：exit 1，不写文件', () async {
      final root = _project();
      final (code, out) = await _run(
        ['--root', root.path, '--check', '--format=json'],
        fetcher: _FakeFetcher('https://example.test', _latest()),
      );
      expect(code, 1);
      expect(out, contains('"schema": "w_tools_cli.upgrade/1"'));
      expect(out, contains('"status": "outdated"'));
      expect(out, contains('"ok": false'));
      expect(File('${root.path}/pubspec.yaml').readAsStringSync(), _pubspec);
    });

    test('--check 全部最新：exit 0', () async {
      final root = _project();
      final (code, _) = await _run(
        ['--root', root.path, '--check'],
        fetcher: _FakeFetcher('https://example.test', <String, LatestRelease?>{
          'w_tools_core': _rel('3.1.1'),
          'w_tools_ui': _rel('8.0.1'),
          'w_tools_async': _rel('6.1.0'),
          'w_tools_cli': _rel('1.18.0'),
          'w_tools_figma': _rel('0.13.1'),
        }),
      );
      expect(code, 0);
    });

    test('--dry-run 打印改动但不写文件', () async {
      final root = _project();
      final (code, out) = await _run(
        ['--root', root.path, '--dry-run'],
        fetcher: _FakeFetcher('https://example.test', _latest()),
      );
      expect(code, 0);
      expect(out, contains('--dry-run'));
      expect(out, contains('w_tools_ui: ^8.0.1 -> ^8.1.0'));
      expect(File('${root.path}/pubspec.yaml').readAsStringSync(), _pubspec);
    });

    test('写入：只改 w_tools 系包的 token，其它依赖与注释不动', () async {
      final root = _project();
      final (code, out) = await _run(
        ['--root', root.path, '--no-get'],
        fetcher: _FakeFetcher('https://example.test', _latest()),
      );
      expect(code, 0, reason: out);
      final written = File('${root.path}/pubspec.yaml').readAsStringSync();
      expect(written, contains('w_tools_core: ^3.1.2'));
      expect(written, contains('w_tools_ui: ^8.1.0 # 行尾注释：不要丢'));
      expect(written, contains('w_tools_cli: ^1.18.2'));
      expect(written, contains('retrofit: 4.9.0'));
      expect(written, contains('# 刻意钉死：retrofit 4.9.2 起 Parser 枚举新增值'));
      expect(written, contains('w_tools_map:\n    path: ../w_tools_map'));
      expect(out, contains('已写入 pubspec.yaml'));
      expect(out, contains('init --force'), reason: '抬了 w_tools_cli 必须提示用新 CLI 刷生成物');
    });

    test('pub get 成功：写入后跑 pub，命令用 flutter（项目有 flutter 依赖）', () async {
      final root = _project();
      final calls = <String>[];
      final (code, out) = await _run(
        ['--root', root.path],
        fetcher: _FakeFetcher('https://example.test', _latest()),
        pubRunner: (executable, args, dir) {
          calls.add('$executable ${args.join(' ')} @ ${dir == root.path ? 'root' : dir}');
          return ProcessResult(0, 0, 'Got dependencies!', '');
        },
      );
      expect(code, 0, reason: out);
      expect(calls, ['flutter pub get @ root']);
      expect(out, contains('flutter pub get … 完成'));
      expect(out, isNot(contains('flutter pub get\n')), reason: '--get 跑过就不再提示 next');
    });

    test('pub get 失败：还原 pubspec、exit 2、带 pub 输出末尾', () async {
      final root = _project();
      final (code, out) = await _run(
        ['--root', root.path],
        fetcher: _FakeFetcher('https://example.test', _latest()),
        pubRunner: (_, _, _) => ProcessResult(
          0,
          1,
          '',
          'Because demo_app depends on w_tools_ui ^8.1.0 which doesn\'t match...',
        ),
      );
      expect(code, 2);
      expect(File('${root.path}/pubspec.yaml').readAsStringSync(), _pubspec);
      expect(out, contains('已还原'));
      expect(out, contains('doesn\'t match'));
      expect(out, contains('flutter pub get … 失败'));
    });

    test('幂等：再跑一次 0 改动', () async {
      final root = _project();
      final fetcher = _FakeFetcher('https://example.test', _latest());
      await _run(['--root', root.path, '--no-get'], fetcher: fetcher);
      final once = File('${root.path}/pubspec.yaml').readAsStringSync();
      final (code, out) = await _run(
        ['--root', root.path, '--no-get'],
        fetcher: fetcher,
      );
      expect(code, 0);
      expect(File('${root.path}/pubspec.yaml').readAsStringSync(), once);
      expect(out, isNot(contains('已写入')));
    });

    test('lock 落后但下界已最新：--check exit 1，写入模式会跑 pub（这里用 --no-get 只验计划）', () async {
      final root = _project();
      final fetcher = _FakeFetcher('https://example.test', <String, LatestRelease?>{
        'w_tools_core': _rel('3.1.1'),
        'w_tools_ui': _rel('8.0.1'),
        'w_tools_async': _rel('6.1.0'),
        'w_tools_cli': _rel('1.18.0'),
        'w_tools_figma': _rel('0.13.1'),
      });
      // lock 落后一个补丁
      File('${root.path}/pubspec.lock').writeAsStringSync(
        _lock.replaceFirst('version: "6.1.0"', 'version: "6.0.9"'),
      );
      final (code, out) = await _run(
        ['--root', root.path, '--check', '--format=prompt'],
        fetcher: fetcher,
      );
      expect(code, 1);
      expect(out, contains('已最新 w_tools_async'));
    });

    test('workspace 项目：exit 2', () async {
      final root = _project(
        pubspec: 'name: demo_app\nresolution: workspace\ndependencies:\n  w_tools_core: ^3.1.1\n',
        lock: null,
      );
      final (code, _) = await _run(['--root', root.path, '--check']);
      expect(code, 2);
    });

    test('没有 pubspec：exit 2', () async {
      final root = Directory.systemTemp.createTempSync('wt_upgrade_empty_');
      addTearDown(() => root.deleteSync(recursive: true));
      final (code, _) = await _run(['--root', root.path, '--check']);
      expect(code, 2);
    });

    test('--only 写了非 w_tools 包：exit 2', () async {
      final root = _project();
      final (code, _) = await _run(
        ['--root', root.path, '--check', '--only=retrofit'],
        fetcher: _FakeFetcher('https://example.test', _latest()),
      );
      expect(code, 2);
    });

    test('没有 w_tools 依赖：exit 0 并说明', () async {
      final root = _project(pubspec: 'name: demo_app\ndependencies:\n  retrofit: 4.9.0\n');
      final (code, out) = await _run(
        ['--root', root.path, '--check'],
        fetcher: _FakeFetcher('https://example.test', const <String, LatestRelease?>{}),
      );
      expect(code, 0);
      expect(out, contains('没有 w_tools* 依赖'));
    });

    test('--help 走统一入口：exit 0 且带退出码表', () async {
      final (code, out) = await _run(['--help']);
      expect(code, 0);
      expect(out, contains('退出码'));
      expect(out, contains('upgrade --check'));
    });
  });

  group('报告', () {
    UpgradePlan samplePlan() => buildPlan(
      hosted: 'https://example.test',
      dependencies: <String, Object?>{'w_tools_core': '^3.1.1', 'w_tools_ui': '^8.0.1'},
      devDependencies: <String, Object?>{'w_tools_cli': '^1.18.0'},
      locked: const <String, String>{'w_tools_core': '3.1.1', 'w_tools_ui': '8.0.1'},
      latest: <String, LatestRelease?>{
        'w_tools_core': _rel('3.1.2'),
        'w_tools_ui': _rel('9.0.0'),
        'w_tools_cli': _rel('1.18.2'),
      },
      overrides: const <String>{},
      allowMajor: false,
      only: const <String>{},
      dartVersion: '3.12.2',
    );

    test('text 列出可升级 / 跨 major / next', () {
      final outcome = UpgradeOutcome(
        projectName: 'demo_app',
        mode: 'check',
        next: const <String>['写入并安装：dart run w_tools_cli:w_tools upgrade'],
      );
      final text = outcome.toText(samplePlan());
      expect(text, contains('w_tools_core'));
      expect(text, contains('可升级'));
      expect(text, contains('跨 major'));
      expect(text, contains('2 个可升级：w_tools_cli、w_tools_core'));
      expect(text, contains('next:'));
    });

    test('json 带 schema / summary / pub 段', () {
      final outcome = UpgradeOutcome(projectName: 'demo_app', mode: 'write');
      final json = outcome.toJson(samplePlan());
      expect(json['schema'], 'w_tools_cli.upgrade/1');
      expect((json['summary'] as Map<String, Object?>)['outdated'], 2);
      expect((json['packages'] as List).length, 3);
      expect((json['pub'] as Map<String, Object?>)['ran'], isFalse);
    });

    test('prompt 每行一个包，适合贴给 AI', () {
      final outcome = UpgradeOutcome(projectName: 'demo_app', mode: 'check');
      final prompt = outcome.toPrompt(samplePlan());
      expect(prompt, contains('可升级 w_tools_core: ^3.1.1 -> ^3.1.2'));
      expect(prompt, contains('跨major w_tools_ui: ^8.0.1 -> 9.0.0'));
    });
  });
}
