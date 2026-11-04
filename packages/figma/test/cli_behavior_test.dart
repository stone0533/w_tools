import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// CLI 层行为：不联网，只使用临时缓存。
void main() {
  late Directory root;

  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cli_');
    home = Directory.systemTemp.createTempSync('figma_cli_home_');
    CacheStore.homeOverride = home.path;
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<ProcessResult> run(List<String> args) {
    // 子进程也要隔离 HOME，否则会读到真实的 ~/.cache/w_tools 与 token
    return Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'bin/figma.dart', ...args, '--root=${root.path}'],
      workingDirectory: Directory.current.path,
      environment: <String, String>{
        ...Platform.environment,
        'HOME': home.path,
        'USERPROFILE': home.path,
        'FIGMA_TOKEN': '',
      },
    );
  }

  test('help fetch / fetch --help 输出命令帮助', () async {
    final byHelp = await run(<String>['help', 'fetch']);
    expect(byHelp.exitCode, 0, reason: '${byHelp.stderr}');
    expect('${byHelp.stdout}', contains('fetch —'));

    final byFlag = await run(<String>['fetch', '--help']);
    expect(byFlag.exitCode, 0, reason: '${byFlag.stderr}');
    expect('${byFlag.stdout}', contains('--check-stale'));

    final cacheHelp = await run(<String>['help', 'cache']);
    expect(cacheHelp.exitCode, 0, reason: '${cacheHelp.stderr}');
    expect('${cacheHelp.stdout}', contains('cache clean'));

    final unknown = await run(<String>['help', 'unknown']);
    expect(unknown.exitCode, 2);
  });

  test('不支持的选项返回 exit 2', () async {
    final result = await run(<String>['spec', '1:2', '--min=3']);
    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('不支持的选项'));
  });

  test('get 下载图片 URL 到本地文件', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response
        ..statusCode = 200
        ..add(<int>[1, 2, 3, 4]);
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final out = File('${root.path}/images/demo.png');
    final result = await run(<String>[
      'get',
      'http://${server.address.address}:${server.port}/image',
      out.path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(out.readAsBytesSync(), <int>[1, 2, 3, 4]);
  });

  test('me 缺少 token 返回 exit 2', () async {
    final result = await run(<String>['me']);
    expect(result.exitCode, 2, reason: '${result.stderr}');
  });

  test('url --json 输出 fileKey / nodeId', () async {
    final result = await run(<String>[
      'url',
      'https://www.figma.com/design/ABC/app?node-id=1-2',
      '--json',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['fileKey'], 'ABC');
    expect(payload['nodeId'], '1:2');
  });

  test('spec --json --node-depth 限制原始节点层级', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Root',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': [
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'Child',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              },
            ],
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2', '--json', '--node-depth=0']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect((payload['node'] as Map).containsKey('children'), isFalse);
  });

  test('spec --json --node-only 不返回 markdown', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'NodeOnly',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2', '--json', '--node-only']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload.containsKey('node'), isTrue);
    expect(payload.containsKey('markdown'), isFalse);
  });

  test('spec a,b --json 返回 specs/1，默认顶层 frames', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'First',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': [],
          },
        },
        '2:3': {
          'document': {
            'id': '2:3',
            'type': 'FRAME',
            'name': 'Second',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 20, 'height': 20},
            'children': [],
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2,2:3', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['schema'], 'w_tools_figma.specs/1');
    expect(payload['items'], hasLength(2));

    final frames = await run(<String>['frames', '--json']);
    expect(frames.exitCode, 0, reason: '${frames.stderr}');
    final framePayload = jsonDecode('${frames.stdout}') as Map<String, dynamic>;
    expect(framePayload['frames'], hasLength(2));
  });

  test('spec a,b 支持跨缓存', () async {
    final dir = Directory(store.dir.path)..createSync(recursive: true);
    for (final entry in {'a.json': '1:2', 'b.json': '2:3'}.entries) {
      File('${dir.path}/nodes-${entry.key}').writeAsStringSync(jsonEncode({
        'nodes': {
          entry.value: {
            'document': {
              'id': entry.value,
              'type': 'FRAME',
              'name': entry.key,
              'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              'children': <Object?>[],
            },
          },
        },
      }));
    }
    final result = await run(<String>['spec', '1:2,2:3', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['schema'], 'w_tools_figma.specs/1');
    expect(payload['items'], hasLength(2));
    final sources = (payload['items'] as List).map((e) => (e as Map)['source']).toSet();
    expect(sources, hasLength(2));
  });

  test('frames page 来自 CANVAS，纯 FRAME 缓存不把画板名当页面', () async {
    final dir = Directory(store.dir.path)..createSync(recursive: true);
    File('${dir.path}/nodes-page.json').writeAsStringSync(jsonEncode({
      'nodes': {
        'p:1': {
          'document': {
            'id': 'p:1',
            'type': 'CANVAS',
            'name': 'Home',
            'children': [
              {
                'id': '1:2',
                'type': 'FRAME',
                'name': 'Card',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              },
            ],
          },
        },
      },
    }));
    File('${dir.path}/nodes-frame.json').writeAsStringSync(jsonEncode({
      'nodes': {
        '2:3': {
          'document': {
            'id': '2:3',
            'type': 'FRAME',
            'name': 'Standalone',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
        },
      },
    }));
    final result = await run(<String>['frames', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    final frames = (payload['frames'] as List).cast<Map<String, dynamic>>();
    expect(frames.firstWhere((f) => f['id'] == '1:2')['page'], 'Home');
    expect(frames.firstWhere((f) => f['id'] == '2:3')['page'], '');
  });

  test('spec 默认选择包含 nodeId 的缓存，而不是最大文件', () async {
    final dir = Directory(store.dir.path)..createSync(recursive: true);
    final target = File('${dir.path}/nodes-old.json');
    target.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Target',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': <Object?>[],
          },
        },
      },
    }));
    final large = File('${dir.path}/nodes-large.json');
    large.writeAsStringSync(jsonEncode({
      'nodes': {
        '9:9': {
          'document': {
            'id': '9:9',
            'type': 'FRAME',
            'name': 'Other',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': List.generate(2000, (i) => {'x': i}),
          },
        },
      },
    }));
    target.setLastModifiedSync(DateTime(2020));
    large.setLastModifiedSync(DateTime(2026));

    final result = await run(<String>['spec', '1:2', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['nodeId'], '1:2');
  });

  test('frames 列出缓存里的 FRAME', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'MemberCard',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 375, 'height': 812},
            'children': [],
          },
        },
      },
    }));

    final result = await run(<String>['frames', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['schema'], 'w_tools_figma.frames/1');
    final frames = payload['frames'] as List;
    expect(frames, hasLength(1));
    expect((frames.first as Map)['id'], '1:2');
    expect((frames.first as Map)['name'], 'MemberCard');
  });

  test('缓存命中时不需要 token', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
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
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
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
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
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
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {'id': '1:2', 'type': 'FRAME', 'name': 'demo'},
        },
      },
    }));

    final result = await run(<String>['fetch', 'nodes', 'K', '1:2', '--check-stale']);
    expect(result.exitCode, 2, reason: '${result.stderr}');
    expect('${result.stderr}', contains('缺少'));
  });

  test('非 figd_ token 返回 exit 2', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
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
    expect(result.exitCode, 2, reason: '${result.stderr}');
    expect('${result.stderr}', contains('figd_'));
  });

  test('cache stats 拒绝 --all；cache clean --yes 需要 --all', () async {
    final stats = await run(<String>['cache', 'stats', '--all']);
    expect(stats.exitCode, 2);
    final clean = await run(<String>['cache', 'clean', '--yes']);
    expect(clean.exitCode, 2);
  });

  test('cache clean --all 需要 --yes 确认', () async {
    final refused = await run(<String>['cache', 'clean', '--all']);
    expect(refused.exitCode, 2, reason: '${refused.stderr}');
    expect('${refused.stderr}', contains('--yes'));

    final ok = await run(<String>['cache', 'clean', '--all', '--yes']);
    expect(ok.exitCode, 0, reason: '${ok.stderr}');
  });

  test('tokens --out 自动创建父目录', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Tok',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
        },
      },
    }));

    final out = '${root.path}/nested/docs/tokens.md';
    final result = await run(<String>['tokens', '1:2', '--out=$out']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(File(out).existsSync(), isTrue);
  });

  test('tokens --json 与 --out 互斥', () async {
    final result = await run(<String>['tokens', '1:2', '--json', '--out=/tmp/x.md']);
    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('不能同时使用'));
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
    final token = CacheStore(root).tokenFile;
    token.writeAsStringSync('custom');

    final forced = await run(<String>['init', '--force']);
    expect(forced.exitCode, 0, reason: '${forced.stderr}');
    expect(token.readAsStringSync(), contains('figd_REPLACE_ME'));
  });

  test('init 在 POSIX 上把 token 设为 600', () async {
    if (Platform.isWindows) return;
    final result = await run(<String>['init']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final token = CacheStore(root).tokenFile;
    expect(token.existsSync(), isTrue);
    expect(token.statSync().mode & 0x1FF, 0x180);
  });
}
