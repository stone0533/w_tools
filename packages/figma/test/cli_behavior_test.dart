import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// CLI 层行为：不联网，只使用临时缓存。
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cli_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<ProcessResult> run(List<String> args) {
    return Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'bin/figma.dart', ...args, '--root=${root.path}'],
      workingDirectory: Directory.current.path,
    );
  }

  test('help fetch / fetch --help 输出命令帮助', () async {
    final byHelp = await run(<String>['help', 'fetch']);
    expect(byHelp.exitCode, 0, reason: '${byHelp.stderr}');
    expect('${byHelp.stdout}', contains('fetch —'));

    final byFlag = await run(<String>['fetch', '--help']);
    expect(byFlag.exitCode, 0, reason: '${byFlag.stderr}');
    expect('${byFlag.stdout}', contains('--check-stale'));

    final unknown = await run(<String>['help', 'unknown']);
    expect(unknown.exitCode, 2);
  });

  test('缓存命中时不需要 token', () async {
    final cache = File('${root.path}/.figma-cache/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    }));

    final result = await run(<String>['fetch', 'nodes', 'K', '1:2']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stderr}', contains('cache hit'));
    expect(File('${root.path}/.figma-token').existsSync(), isFalse);
  });

  test('多节点缓存下 spec 能命中第二个节点', () async {
    final cache = File('${root.path}/.figma-cache/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'First',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
          },
        },
        '2:3': {
          'document': {
            'id': '2:3',
            'type': 'FRAME',
            'name': 'Second',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 200, 'height': 200},
          },
        },
      },
    }));

    final result = await run(<String>['spec', '2:3', '--file=${cache.path}']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('# Second  (2:3)'));
  });

  test('spec --json 同时返回原始 node 与 markdown', () async {
    final cache = File('${root.path}/.figma-cache/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Structured',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2', '--file=${cache.path}', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['schema'], 'w_tools_figma.spec/1');
    expect((payload['node'] as Map)['id'], '1:2');
    expect('${payload['markdown']}', contains('# Structured'));
  });

  test('缓存命中但 --check-stale 仍需 token', () async {
    final cache = File('${root.path}/.figma-cache/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    }));

    final result = await run(<String>['fetch', 'nodes', 'K', '1:2', '--check-stale']);
    expect(result.exitCode, 4, reason: '${result.stderr}');
    expect('${result.stderr}', contains('缺少'));
  });

  test('非 figd_ token 返回 exit 4', () async {
    final cache = File('${root.path}/.figma-cache/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    }));
    File('${root.path}/.figma-token').writeAsStringSync('not-a-figma-token');

    final result = await run(<String>['fetch', 'nodes', 'K', '1:2', '--check-stale']);
    expect(result.exitCode, 4, reason: '${result.stderr}');
    expect('${result.stderr}', contains('figd_'));
  });

  test('非法参数返回 exit 2', () async {
    final result = await run(<String>['tokens', '1:2', '--min=abc']);
    expect(result.exitCode, 2, reason: '${result.stderr}');

    final unknown = await run(<String>['budget', '--wat']);
    expect(unknown.exitCode, 2, reason: '${unknown.stderr}');
  });

  test('init --force 覆盖已有 token', () async {
    final first = await run(<String>['init']);
    expect(first.exitCode, 0, reason: '${first.stderr}');
    final token = File('${root.path}/.figma-token');
    token.writeAsStringSync('custom');

    final forced = await run(<String>['init', '--force']);
    expect(forced.exitCode, 0, reason: '${forced.stderr}');
    expect(token.readAsStringSync(), contains('figd_REPLACE_ME'));
  });

  test('init 在 POSIX 上把 token 设为 600', () async {
    if (Platform.isWindows) return;
    final result = await run(<String>['init']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final token = File('${root.path}/.figma-token');
    expect(token.existsSync(), isTrue);
    expect(token.statSync().mode & 0x1FF, 0x180);
  });
}
