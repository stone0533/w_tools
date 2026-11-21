import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cli/version.dart';

/// CLI 层行为：不联网，只使用临时缓存。
void main() {
  late Directory root;

  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cli_');
    home = Directory.systemTemp.createTempSync('figma_cli_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<ProcessResult> run(List<String> args, {bool withRoot = true}) {
    // 子进程也要隔离 HOME，否则会读到真实的 ~/.cache/w_tools 与 token
    return Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'bin/figma.dart',
        ...args,
        if (withRoot) '--root=${root.path}',
      ],
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

  test('顶层 --help 列出 version', () async {
    final result = await run(<String>['--help']);
    expect(result.exitCode, 0);
    expect('${result.stdout}', contains('version'));
  });

  test('--ignore-budget 在 1.0.0 已删除', () async {
    final result = await run(<String>['fetch', 'nodes', 'K', '1:2', '--ignore-budget']);
    expect(result.exitCode, 2, reason: '${result.stderr}');
    expect('${result.stderr}', contains('未知选项：--ignore-budget'));
  });

  test('version 输出版本号', () async {
    final result = await run(<String>['version']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('w_tools_figma $figmaVersion'));
  });

  test('未知选项返回 exit 2', () async {
    final result = await run(<String>['spec', '1:2', '--min=3']);
    expect(result.exitCode, 2);
    expect('${result.stderr}', contains('未知选项：--min'));
  });

  test('fetch images 不缓存，拒绝 --refresh / --check-stale / --depth', () async {
    for (final flag in <String>['--refresh', '--check-stale', '--depth=2']) {
      final result = await run(<String>['fetch', 'images', 'K', '1:2', flag]);
      expect(result.exitCode, 2, reason: '$flag: ${result.stderr}');
      expect('${result.stderr}', contains('images 不支持'));
    }

    for (final scale in <String>['2', '3']) {
      final nodes = await run(<String>['fetch', 'nodes', 'K', '1:2', '--scale=$scale']);
      expect(nodes.exitCode, 2, reason: '$scale: ${nodes.stderr}');
      expect('${nodes.stderr}', contains('nodes 不支持 --scale'));
    }
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
    ], withRoot: false);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(out.readAsBytesSync(), <int>[1, 2, 3, 4]);
  });

  test('me 缺少 token 返回 exit 4', () async {
    final result = await run(<String>['me'], withRoot: false);
    expect(result.exitCode, 4, reason: '${result.stderr}');
  });

  test('url --json 输出 fileKey / nodeId', () async {
    final result = await run(<String>[
      'url',
      'https://www.figma.com/design/ABC/app?node-id=1-2',
      '--json',
    ], withRoot: false);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;
    expect(payload['schema'], 'w_tools_figma.url/1');
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
    final items = (payload['items'] as List).cast<Map<String, dynamic>>();
    expect((items.single['node'] as Map).containsKey('children'), isFalse);
  });

  test('spec --with-layout 在 markdown 表格加布局列', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Layout',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
            'children': [
              {
                'id': '1:3',
                'type': 'FRAME',
                'name': 'Column',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
                'layoutMode': 'VERTICAL',
                'itemSpacing': 8,
                'paddingLeft': 16,
                'paddingRight': 16,
                'paddingTop': 10,
                'paddingBottom': 10,
              },
            ],
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2', '--with-layout']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('| 布局 |'));
    expect('${result.stdout}', contains('layoutMode=VERTICAL'));
  });

  test('spec --with-id 在 markdown 表格加子节点 id', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'WithId',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': [
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'Child',
                'characters': 'Hi',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              },
            ],
          },
        },
      },
    }));

    final result = await run(<String>['spec', '1:2', '--with-id']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('| id | x,y |'));
    expect('${result.stdout}', contains('| 1:3 |'));
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
    final items = (payload['items'] as List).cast<Map<String, dynamic>>();
    expect(items.single.containsKey('node'), isTrue);
    expect(items.single.containsKey('markdown'), isFalse);
  });

  test('spec --node-only 需要 --json', () async {
    final result = await run(<String>['spec', '1:2', '--node-only']);
    expect(result.exitCode, 2, reason: '${result.stderr}');
    expect('${result.stderr}', contains('--node-only 只与 --json 一起使用'));
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
    final items = (payload['items'] as List).cast<Map<String, dynamic>>();
    expect(items.single['nodeId'], '1:2');
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
    expect(payload['schema'], 'w_tools_figma.specs/1');
    final items = (payload['items'] as List).cast<Map<String, dynamic>>();
    expect(items, hasLength(1));
    expect((items.single['node'] as Map)['id'], '1:2');
    expect('${items.single['markdown']}', contains('# Structured'));
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
    expect(result.exitCode, 4, reason: '${result.stderr}');
    expect('${result.stderr}', contains('缺少'));
  });

  test('非 figd_ token 返回 exit 4', () async {
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
    expect(result.exitCode, 4, reason: '${result.stderr}');
    expect('${result.stderr}', contains('figd_'));
  });

  test('cache stats 拒绝 --all；cache clean 需要 --yes', () async {
    final stats = await run(<String>['cache', 'stats', '--all']);
    expect(stats.exitCode, 2);

    final refused = await run(<String>['cache', 'clean']);
    expect(refused.exitCode, 2, reason: '${refused.stderr}');
    expect('${refused.stderr}', contains('--yes'));

    final ok = await run(<String>['cache', 'clean', '--yes']);
    expect(ok.exitCode, 0, reason: '${ok.stderr}');
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

    final unknown = await run(<String>['usage', '--wat'], withRoot: false);
    expect(unknown.exitCode, 2, reason: '${unknown.stderr}');

    final skip = await run(<String>['tokens', '1:2', '--skip-markdown']);
    expect(skip.exitCode, 2, reason: '${skip.stderr}');
    expect('${skip.stderr}', contains('只与 --json 一起使用'));
  });

  test('tokens --json 带结构化数组，不再只有 counts + markdown', () async {
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
            'fills': [
              {
                'type': 'SOLID',
                'color': {'r': 1, 'g': 0, 'b': 0, 'a': 1},
              },
            ],
            'children': [
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'Title',
                'characters': 'hi',
                'style': {
                  'fontFamily': 'Inter',
                  'fontSize': 14,
                  'fontWeight': 500,
                  'lineHeightPx': 20,
                  'letterSpacing': 0,
                  'textAlignHorizontal': 'LEFT',
                },
                'fills': [
                  {
                    'type': 'SOLID',
                    'color': {'r': 0.2, 'g': 0.2, 'b': 0.2, 'a': 1},
                  },
                ],
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
              },
            ],
          },
        },
      },
    }));

    final result = await run(<String>['tokens', '1:2', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode('${result.stdout}') as Map<String, dynamic>;

    expect(payload['schema'], 'w_tools_figma.tokens/1');
    expect(payload['counts'], isA<Map<String, dynamic>>());
    expect(payload['markdown'], contains('# 设计 token'));

    final colors = (payload['colors'] as List).cast<Map<String, dynamic>>();
    expect(
      colors.map((c) => c['value']),
      containsAll(<String>['#FF0000', '#333333']),
      reason: '两个 SOLID 填充都要出现在结构化数组里',
    );
    expect(colors.every((c) => c['count'] == 1), isTrue);
    expect(colors.first['samples'], isA<List<dynamic>>());

    expect('${payload['sources']}', contains('nodes-K-1-2.json'));

    final texts = (payload['texts'] as List).cast<Map<String, dynamic>>();
    expect(texts.single['family'], 'Inter');
    expect(texts.single.containsKey('fontStyle'), isTrue);
    expect(texts.single['size'], '14');
    expect(texts.single['color'], '#333333');

    expect(payload['radii'], isA<List<dynamic>>());
    expect(payload['spacings'], isA<List<dynamic>>());

    final map = File('${root.path}/tokens.yaml')
      ..writeAsStringSync('colors:\n  "#FF0000": brandRed\n');
    final mapped = await run(<String>[
      'tokens',
      '1:2',
      '--json',
      '--skip-markdown',
      '--map=${map.path}',
    ]);
    expect(mapped.exitCode, 0, reason: '${mapped.stderr}');
    final mappedPayload = jsonDecode('${mapped.stdout}') as Map<String, dynamic>;
    final mappedColors = (mappedPayload['colors'] as List).cast<Map<String, dynamic>>();
    expect(
      mappedColors.firstWhere((color) => color['value'] == '#FF0000')['name'],
      'brandRed',
    );
    expect(
      mappedColors.firstWhere((color) => color['value'] == '#333333')['name'],
      isNull,
    );

    final lean = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    expect(lean.exitCode, 0, reason: '${lean.stderr}');
    final leanPayload = jsonDecode('${lean.stdout}') as Map<String, dynamic>;
    expect(leanPayload.containsKey('markdown'), isFalse);
    expect(leanPayload['colors'], isA<List<dynamic>>());
  });

  test('损坏缓存按"解析失败"报告，不再只说找不到节点', () async {
    File('${store.dir.path}/nodes-good.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': {'id': '1:2', 'type': 'FRAME', 'name': 'Demo'},
          },
        },
      }));
    final bad = File('${store.dir.path}/nodes-bad.json')..writeAsStringSync('{not json');

    final result = await run(<String>['spec', '9:9']);
    expect(result.exitCode, 1, reason: '${result.stderr}');
    expect('${result.stderr}', contains('解析失败'));
    expect('${result.stderr}', contains('cache clean'));
    expect('${result.stderr}', contains(bad.path));
  });

  test('只有损坏缓存时也指向 cache clean', () async {
    File('${store.dir.path}/nodes-bad.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');

    final result = await run(<String>['tokens', '1:2']);
    expect(result.exitCode, 1, reason: '${result.stderr}');
    expect('${result.stderr}', contains('解析失败'));
  });

  test('frames 跳过损坏缓存时保留好缓存的行并提示', () async {
    File('${store.dir.path}/nodes-good.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': {
              'id': '1:2',
              'type': 'FRAME',
              'name': 'Demo',
              'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              'children': <Object?>[],
            },
          },
        },
      }));
    File('${store.dir.path}/nodes-bad.json').writeAsStringSync('{not json');

    final result = await run(<String>['frames', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('1:2'));
    expect('${result.stderr}', contains('跳过 1 个解析失败的缓存'));
  });

  test('spec --no-markdown 已在 0.13.0 删除（exit 2）', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Demo',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': <Object?>[],
          },
        },
      },
    }));

    final removed = await run(<String>['spec', '1:2', '--json', '--no-markdown']);
    final current = await run(<String>['spec', '1:2', '--json', '--node-only']);

    expect(removed.exitCode, 2, reason: '${removed.stderr}');
    expect('${removed.stderr}', contains('未知选项：--no-markdown'));
    expect(current.exitCode, 0, reason: '${current.stderr}');
  });

  test('flag 值支持空格形态，输出与 = 形态一致', () async {
    final cache = File('${store.dir.path}/nodes-K-1-2.json');
    cache.parent.createSync(recursive: true);
    cache.writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Demo',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
            'children': [
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'Title',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
              },
            ],
          },
        },
      },
    }));

    final spaced = await run(<String>['spec', '1:2', '--json', '--node-depth', '0']);
    final equals = await run(<String>['spec', '1:2', '--json', '--node-depth=0']);
    expect(spaced.exitCode, 0, reason: '${spaced.stderr}');
    expect('${spaced.stdout}', '${equals.stdout}');

    final frames = await run(<String>['frames', '--json', '--name', 'Demo']);
    expect(frames.exitCode, 0, reason: '${frames.stderr}');
    expect('${frames.stdout}', contains('1:2'));
  });

  test('url / get 不再接受 --root（0.14.0 已移除）', () async {
    final url = await run(<String>['url', 'https://www.figma.com/design/ABC/app']);
    expect(url.exitCode, 2, reason: '${url.stderr}');
    expect('${url.stderr}', contains('未知选项：--root'));

    final get = await run(<String>['get', 'https://example.com/a.png', '${root.path}/x.png']);
    expect(get.exitCode, 2, reason: '${get.stderr}');
    expect('${get.stderr}', contains('未知选项：--root'));

    final direct = await run(
      <String>['url', 'https://www.figma.com/design/ABC/app'],
      withRoot: false,
    );
    expect(direct.exitCode, 0, reason: '${direct.stderr}');
  });

  test('多余的位置参数报错，不再静默忽略', () async {
    final spec = await run(<String>['spec', '1:2', '9:9']);
    expect(spec.exitCode, 2, reason: '${spec.stderr}');
    expect('${spec.stderr}', contains('多余的参数'));

    final url = await run(<String>['url', 'a', 'b'], withRoot: false);
    expect(url.exitCode, 2);
    expect('${url.stderr}', contains('多余的参数'));

    final fetch = await run(<String>['fetch', 'nodes', 'K', '1:2', 'extra']);
    expect(fetch.exitCode, 2);
    expect('${fetch.stderr}', contains('多余的参数'));

    final me = await run(<String>['me', 'extra'], withRoot: false);
    expect(me.exitCode, 2);
    expect('${me.stderr}', contains('多余的参数'));
  });

  test('init --force 不覆盖真实 token', () async {
    final first = await run(<String>['init']);
    expect(first.exitCode, 0, reason: '${first.stderr}');
    final token = CacheStore(root, home: home.path).tokenFile;
    token.writeAsStringSync('custom');

    final forced = await run(<String>['init', '--force']);
    expect(forced.exitCode, 1, reason: '${forced.stderr}');
    expect('${forced.stderr}', contains('已有真实 token'));
    expect(token.readAsStringSync(), 'custom');
  });

  test('init --force 会重建模板 token', () async {
    final first = await run(<String>['init']);
    expect(first.exitCode, 0, reason: '${first.stderr}');
    final token = CacheStore(root, home: home.path).tokenFile;
    token.writeAsStringSync('figd_REPLACE_ME\n');

    final forced = await run(<String>['init', '--force']);
    expect(forced.exitCode, 0, reason: '${forced.stderr}');
    expect(token.readAsStringSync(), contains('figd_REPLACE_ME'));
  });

  test('init 在 POSIX 上把 token 设为 600', () async {
    if (Platform.isWindows) return;
    final result = await run(<String>['init']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final token = CacheStore(root, home: home.path).tokenFile;
    expect(token.existsSync(), isTrue);
    expect(token.statSync().mode & 0x1FF, 0x180);
  });

  test('init 对已存在的 token 也收紧到 600', () async {
    if (Platform.isWindows) return;
    final token = CacheStore(root, home: home.path).tokenFile;
    token.parent.createSync(recursive: true);
    token.writeAsStringSync('figd_real');
    Process.runSync('chmod', <String>['644', token.path]);

    final result = await run(<String>['init']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(token.statSync().mode & 0x1FF, 0x180);
  });

  File writeCache(
    String name,
    Map<String, dynamic> document, {
    String nodeId = '1:2',
  }) {
    final file = File('${store.dir.path}/$name');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({
      'nodes': {
        nodeId: {'document': document}
      },
    }));
    return file;
  }

  Map<String, dynamic> frame({
    String id = '1:2',
    String name = 'Demo',
    List<Object?> children = const <Object?>[],
  }) =>
      <String, dynamic>{
        'id': id,
        'type': 'FRAME',
        'name': name,
        'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
        'children': children,
      };

  test('--root 不同写法落到同一缓存；空 / 不存在 / 选项在前都 exit 2', () async {
    final plain = await run(<String>['cache', 'stats', '--root=${root.path}'], withRoot: false);
    final dotted = await run(<String>['cache', 'stats', '--root=${root.path}/./'], withRoot: false);
    expect(plain.exitCode, 0, reason: '${plain.stderr}');
    expect(dotted.exitCode, 0, reason: '${dotted.stderr}');
    final dirLine = '缓存目录：';
    expect(
      '${dotted.stdout}'.split('\n').firstWhere((line) => line.startsWith(dirLine)),
      '${plain.stdout}'.split('\n').firstWhere((line) => line.startsWith(dirLine)),
    );

    final empty = await run(<String>['cache', 'stats', '--root='], withRoot: false);
    expect(empty.exitCode, 2, reason: '${empty.stderr}');
    final missing =
        await run(<String>['cache', 'stats', '--root=/no/such/figma/dir'], withRoot: false);
    expect(missing.exitCode, 2, reason: '${missing.stderr}');
    final before = await run(<String>['--root=${root.path}', 'cache', 'stats'], withRoot: false);
    expect(before.exitCode, 2, reason: '${before.stderr}');
    expect('${before.stderr}', contains('选项要放在命令之后'));
  });

  test('--version / -v 与 version 等价', () async {
    for (final args in <List<String>>[
      <String>['--version'],
      <String>['-v'],
      <String>['version'],
    ]) {
      final result = await run(args, withRoot: false);
      expect(result.exitCode, 0, reason: '$args: ${result.stderr}');
      expect('${result.stdout}', contains('w_tools_figma'));
    }
  });

  test('frames 空过滤值 exit 2；显式 --file 损坏 exit 1', () async {
    writeCache('nodes-K-1-2.json', frame());

    final emptyName = await run(<String>['frames', '--name=']);
    expect(emptyName.exitCode, 2, reason: '${emptyName.stderr}');
    expect('${emptyName.stderr}', contains('--name 不能为空'));

    final bad = File('${store.dir.path}/nodes-K-bad.json')..writeAsStringSync('{not json');
    final corrupt = await run(<String>['frames', '--file=${bad.path}']);
    expect(corrupt.exitCode, 1, reason: '${corrupt.stderr}');
    expect('${corrupt.stderr}', contains('缓存解析失败'));
    expect('${corrupt.stdout}', isNot(contains('没有 FRAME')));
  });

  test('tokens 空 id exit 2；重复 id 去重', () async {
    writeCache('nodes-K-red.json', {
      'id': '1:2',
      'type': 'RECTANGLE',
      'name': 'Red',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      'fills': [
        {
          'type': 'SOLID',
          'color': {'r': 1, 'g': 0, 'b': 0},
        },
      ],
    });

    final empty = await run(<String>['tokens', ',']);
    expect(empty.exitCode, 2, reason: '${empty.stderr}');

    final single = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    final duplicate = await run(<String>['tokens', '1:2,1:2', '--json', '--skip-markdown']);
    final singlePayload = jsonDecode('${single.stdout}') as Map<String, dynamic>;
    final duplicatePayload = jsonDecode('${duplicate.stdout}') as Map<String, dynamic>;
    expect(singlePayload['nodeIds'], <String>['1:2']);
    expect(duplicatePayload['nodeIds'], <String>['1:2']);
    expect(
      (duplicatePayload['colors'] as List).first['count'],
      (singlePayload['colors'] as List).first['count'],
    );
  });

  test('frames 人类输出对 dN 行加截断标记', () async {
    final file = File('${store.dir.path}/nodes-K-1-2-d2.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'version': '1',
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    expect(file.existsSync(), isTrue);

    final result = await run(<String>['frames']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}', contains('0*'));
    expect('${result.stdout}', contains('来自 --depth 裁剪缓存'));
  });

  test('frames --page=- 不再提示可能漏掉单节点缓存', () async {
    writeCache('nodes-K-1-2.json', frame(name: 'Solo'));
    final result = await run(<String>['frames', '--page=-']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stderr}', isNot(contains('可能漏掉')));
  });

  test('cache clean --file 输出路径与 cache stats 一致', () async {
    writeCache('nodes-K-1-2.json', frame());
    File('${store.dir.path}/dump.json').writeAsStringSync('{}');

    final stats = await run(<String>['cache', 'stats']);
    final dir = '${stats.stdout}'
        .split('\n')
        .firstWhere((line) => line.startsWith('缓存目录：'))
        .replaceFirst('缓存目录：', '')
        .trim();
    final clean = await run(<String>['cache', 'clean', '--file=dump.json', '--yes']);
    expect(clean.exitCode, 0, reason: '${clean.stderr}');
    expect('${clean.stdout}', contains(dir));
  });

  test('spec / tokens 默认优先完整树，--allow-depth 才读裁剪缓存', () async {
    final full = File('${store.dir.path}/nodes-K-1-2.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': frame(children: <Object?>[
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'Title',
                'characters': 'Hi',
                'style': {'fontFamily': 'Inter', 'fontSize': 16},
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              },
            ]),
          },
        },
      }));
    final depth = File('${store.dir.path}/nodes-K-1-2-d2.json')
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    full.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depth.setLastModifiedSync(DateTime.now());

    final tokens = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    final tokensPayload = jsonDecode('${tokens.stdout}') as Map<String, dynamic>;
    expect(tokens.exitCode, 0, reason: '${tokens.stderr}');
    expect(tokensPayload['depthLimited'], isFalse);
    expect((tokensPayload['sourceDepths'] as List).first['depth'], isNull);
    expect('${tokens.stderr}', contains('完整缓存可能陈旧'));
    expect('${tokens.stderr}', contains('dN 文件时间更晚'));

    final spec = await run(<String>['spec', '1:2', '--json', '--node-only']);
    final specPayload = jsonDecode('${spec.stdout}') as Map<String, dynamic>;
    expect(spec.exitCode, 0, reason: '${spec.stderr}');
    expect(specPayload['depthLimited'], isFalse);
    expect((specPayload['items'] as List).first['sourceDepth'], isNull);

    final depthOnly = await run(
      <String>['tokens', '1:2', '--json', '--skip-markdown', '--allow-depth'],
    );
    final depthPayload = jsonDecode('${depthOnly.stdout}') as Map<String, dynamic>;
    expect(depthPayload['depthLimited'], isTrue);
    expect((depthPayload['sourceDepths'] as List).first['depth'], 2);
  });

  test('同 version 的 dN 文件更新不报陈旧；JSON 给稳定字段', () async {
    final full = File('${store.dir.path}/nodes-K-same-1.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'version': '2415310932909825311',
        'lastModified': '2026-10-28T07:39:10Z',
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    final depth = File('${store.dir.path}/nodes-K-same-1-d2.json')
      ..writeAsStringSync(jsonEncode({
        'version': '2415310932909825311',
        'lastModified': '2026-10-28T07:39:10Z',
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    full.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depth.setLastModifiedSync(DateTime.now());

    final tokens = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    final payload = jsonDecode('${tokens.stdout}') as Map<String, dynamic>;
    expect(tokens.exitCode, 0, reason: '${tokens.stderr}');
    expect(payload['staleAgainstDepth'], isFalse);
    expect(payload['newerDepthAvailable'], isEmpty);
    expect('${tokens.stderr}', isNot(contains('完整缓存可能陈旧')));
    expect('${tokens.stderr}', isNot(contains('version')));

    final spec = await run(<String>['spec', '1:2', '--json', '--node-only']);
    final specPayload = jsonDecode('${spec.stdout}') as Map<String, dynamic>;
    expect(spec.exitCode, 0, reason: '${spec.stderr}');
    expect(specPayload['staleAgainstDepth'], isFalse);
    expect(specPayload['newerDepthAvailable'], isEmpty);
  });

  test('dN version 更新时警告，并在 JSON 标出 newerDepthAvailable', () async {
    final full = File('${store.dir.path}/nodes-K-newer-1.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'version': '2415310932909825311',
        'lastModified': '2026-10-28T07:39:10Z',
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    expect(full.existsSync(), isTrue);
    final depth = File('${store.dir.path}/nodes-K-newer-1-d2.json')
      ..writeAsStringSync(jsonEncode({
        'version': '2415310932909825312',
        'lastModified': '2026-10-29T07:39:10Z',
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));

    final tokens = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    final payload = jsonDecode('${tokens.stdout}') as Map<String, dynamic>;
    expect(tokens.exitCode, 0, reason: '${tokens.stderr}');
    expect(payload['staleAgainstDepth'], isTrue);
    final newer = (payload['newerDepthAvailable'] as List).cast<Map<String, dynamic>>();
    expect(newer, hasLength(1));
    expect(newer.single['nodeId'], '1:2');
    expect(newer.single['source'], depth.path);
    expect(newer.single['depth'], 2);
    expect(newer.single['version'], '2415310932909825312');
    expect('${tokens.stderr}', contains('完整缓存可能陈旧'));
    expect('${tokens.stderr}', contains('dN version 2415310932909825312 更新'));

    final spec = await run(<String>['spec', '1:2', '--json', '--node-only']);
    final specPayload = jsonDecode('${spec.stdout}') as Map<String, dynamic>;
    expect(spec.exitCode, 0, reason: '${spec.stderr}');
    expect(specPayload['staleAgainstDepth'], isTrue);
    final specNewer = (specPayload['newerDepthAvailable'] as List).cast<Map<String, dynamic>>();
    expect(specNewer.single['nodeId'], '1:2');
    expect(specNewer.single['source'], depth.path);
    expect(specNewer.single['depth'], 2);
  });

  test('stale / depth 提示只引用同一 fileKey 的缓存', () async {
    final fullA = File('${store.dir.path}/nodes-FILEA-10-1.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'version': '100',
        'lastModified': '2026-10-28T07:39:10Z',
        'nodes': {
          '10:1': {'document': frame(id: '10:1', name: 'FILEA')},
        },
      }));
    final depthB = File('${store.dir.path}/nodes-FILEB-10-1-d2.json')
      ..writeAsStringSync(jsonEncode({
        'version': '300',
        'lastModified': '2026-10-29T07:39:10Z',
        'nodes': {
          '10:1': {'document': frame(id: '10:1', name: 'FILEB')},
        },
      }));
    fullA.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depthB.setLastModifiedSync(DateTime.now());

    final normal = await run(<String>['tokens', '10:1', '--json', '--skip-markdown']);
    final normalPayload = jsonDecode('${normal.stdout}') as Map<String, dynamic>;
    expect(normal.exitCode, 0, reason: '${normal.stderr}');
    expect((normalPayload['sources'] as List).single, contains('FILEA'));
    expect(normalPayload['staleAgainstDepth'], isFalse);
    expect(normalPayload['newerDepthAvailable'], isEmpty);
    expect('${normal.stderr}', isNot(contains('完整缓存可能陈旧')));

    final depth = await run(
      <String>['tokens', '10:1', '--allow-depth', '--json', '--skip-markdown'],
    );
    final depthPayload = jsonDecode('${depth.stdout}') as Map<String, dynamic>;
    expect(depth.exitCode, 0, reason: '${depth.stderr}');
    expect((depthPayload['sources'] as List).single, contains('FILEB'));
    expect(depthPayload['depthLimited'], isTrue);
    expect('${depth.stderr}', isNot(contains('nodes-FILEA')));
    expect('${depth.stderr}', contains('未找到同一 fileKey 的完整缓存'));
  });

  test('depth 警告只走 stderr，不写进 spec stdout / tokens --out', () async {
    final depth = File('${store.dir.path}/nodes-K-1-2-d2.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    final out = File('${root.path}/design-tokens.md');

    final spec = await run(<String>['spec', '1:2', '--file=${depth.path}']);
    expect(spec.exitCode, 0, reason: '${spec.stderr}');
    expect('${spec.stdout}', isNot(contains('⚠️')));
    expect('${spec.stdout}', startsWith('# Demo  (1:2)'));
    expect('${spec.stderr}', contains('--depth 裁剪缓存'));

    final tokens = await run(
      <String>['tokens', '1:2', '--file=${depth.path}', '--out=${out.path}'],
    );
    expect(tokens.exitCode, 0, reason: '${tokens.stderr}');
    expect(out.readAsStringSync(), startsWith('# 设计 token 汇总'));
    expect(out.readAsStringSync(), isNot(contains('⚠️')));
    expect('${tokens.stderr}', contains('--depth 裁剪缓存'));
  });

  test('缓存结构异常 exit 1，不打印 Dart 栈', () async {
    final badBox = File('${store.dir.path}/nodes-K-badbox.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': {
              'id': '1:2',
              'type': 'FRAME',
              'name': 'bad',
              'absoluteBoundingBox': {'y': 0, 'width': 10, 'height': 10},
              'children': <Object?>[],
            },
          },
        },
      }));
    final box = await run(<String>['spec', '1:2', '--file=${badBox.path}']);
    expect(box.exitCode, 1, reason: '${box.stderr}');
    expect('${box.stderr}', contains('absoluteBoundingBox'));
    expect('${box.stderr}', isNot(contains('#0')));

    final badStyle = File('${store.dir.path}/nodes-K-badstyle.json')
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {
            'document': {
              'id': '1:2',
              'type': 'TEXT',
              'name': 'bad',
              'characters': 'hi',
              'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              'style': 'oops',
              'children': <Object?>[],
            },
          },
        },
      }));
    final style = await run(<String>['spec', '1:2', '--file=${badStyle.path}']);
    expect(style.exitCode, 1, reason: '${style.stderr}');
    expect('${style.stderr}', contains('style'));
  });

  test('skip-hidden / skip-name-prefix 同时作用于 JSON node', () async {
    writeCache(
        'nodes-K-skip.json',
        frame(children: <Object?>[
          {
            'id': '1:3',
            'type': 'TEXT',
            'name': 'Hidden',
            'visible': false,
            'characters': 'Hidden',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
          {
            'id': '1:4',
            'type': 'TEXT',
            'name': '標題 mock',
            'characters': 'Title',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
          {
            'id': '1:5',
            'type': 'TEXT',
            'name': 'Body',
            'characters': 'Body',
            'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
          },
        ]));

    final hidden = await run(
      <String>['spec', '1:2', '--json', '--node-only', '--skip-hidden'],
    );
    final hiddenNode = ((jsonDecode('${hidden.stdout}') as Map<String, dynamic>)['items']
        as List)[0]['node'] as Map<String, dynamic>;
    expect(hiddenNode['children'], hasLength(2));

    final prefixed = await run(
      <String>['spec', '1:2', '--json', '--node-only', '--skip-name-prefix=標題'],
    );
    final prefixedNode = ((jsonDecode('${prefixed.stdout}') as Map<String, dynamic>)['items']
        as List)[0]['node'] as Map<String, dynamic>;
    final ids = (prefixedNode['children'] as List).map((c) => (c as Map)['id']);
    expect(ids, isNot(contains('1:4')));
  });

  test('tokens 输出 textCase / textDecoration 与数值字段；frames 带 cacheDepth', () async {
    writeCache('nodes-K-style.json', {
      'id': '1:2',
      'type': 'TEXT',
      'name': 'note',
      'characters': 'abcdef',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      'style': {
        'fontFamily': 'Inter',
        'fontSize': 16,
        'textAlignHorizontal': 'LEFT',
      },
      'characterStyleOverrides': <int>[0, 0, 0, 0, 3, 3],
      'styleOverrideTable': {
        '3': {'textDecoration': 'UNDERLINE'},
      },
      'cornerRadius': 8,
    });
    final tokens = await run(<String>['tokens', '1:2', '--json', '--skip-markdown']);
    final payload = jsonDecode('${tokens.stdout}') as Map<String, dynamic>;
    final texts = payload['texts'] as List;
    expect(texts.any((t) => t['textDecoration'] == 'UNDERLINE'), isTrue);
    expect(texts.first['sizeNum'], 16);
    expect((payload['radii'] as List).first['valueNum'], 8);

    File('${store.dir.path}/nodes-K-1-9-d2.json').writeAsStringSync(jsonEncode({
      'nodes': {
        '1:9': {
          'document': frame(id: '1:9', name: 'DepthOnly'),
        },
      },
    }));
    final frames = await run(<String>['frames', '--json']);
    final rows = (jsonDecode('${frames.stdout}') as Map<String, dynamic>)['frames'] as List;
    final depthRow = rows.firstWhere((row) => row['id'] == '1:9');
    expect(depthRow['cacheDepth'], 2);
  });

  test('空的 individualStrokeWeights key 不会把 CLI 打成 exit 255', () async {
    writeCache('nodes-K-stroke.json', {
      'id': '1:2',
      'type': 'FRAME',
      'name': 'Stroke',
      'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
      'strokes': [
        {
          'type': 'SOLID',
          'color': {'r': 0, 'g': 0, 'b': 0},
        },
      ],
      'strokeWeight': 2,
      'individualStrokeWeights': {'': 2},
      'children': <Object?>[],
    });

    final result = await run(<String>['spec', '1:2', '--json']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stderr}', isNot(contains('Unhandled exception')));
    expect('${result.stdout}', isNot(contains('[=2]')));
  });

  test('cache clean --file 接受 /tmp 与 /private/tmp 等等价路径', () async {
    if (!Platform.isMacOS || !store.dir.path.startsWith('/private/')) return;
    final file = File('${store.dir.path}/dump-alias.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{}');
    final alias = file.path.replaceFirst('/private', '');

    final result = await run(<String>['cache', 'clean', '--file=$alias', '--yes']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(file.existsSync(), isFalse);
  });

  test('cache clean --file 仍拒绝缓存目录外 / 软链到外部的文件', () async {
    final outside = File('${home.path}/outside.json')..writeAsStringSync('{}');
    final link = Link('${store.dir.path}/link-outside.json');
    if (!Platform.isWindows) {
      link.parent.createSync(recursive: true);
      link.createSync(outside.path);
      final result = await run(<String>['cache', 'clean', '--file=${link.path}', '--yes']);
      expect(result.exitCode, 2, reason: '${result.stderr}');
      expect(outside.existsSync(), isTrue);
    }
  });

  test('显式 --file=<dN> 时也提示同项目的完整缓存', () async {
    final full = File('${store.dir.path}/nodes-K-1-2.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    final depth = File('${store.dir.path}/nodes-K-1-2-d2.json')
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          '1:2': {'document': frame()},
        },
      }));
    full.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    depth.setLastModifiedSync(DateTime.now());

    final tokens = await run(
      <String>['tokens', '1:2', '--file=${depth.path}', '--json', '--skip-markdown'],
    );
    expect(tokens.exitCode, 0, reason: '${tokens.stderr}');
    expect('${tokens.stderr}', contains(full.path));
    expect('${tokens.stderr}', isNot(contains('没有其它完整缓存')));

    final spec = await run(<String>['spec', '1:2', '--file=${depth.path}']);
    expect(spec.exitCode, 0, reason: '${spec.stderr}');
    expect('${spec.stdout}', isNot(contains('⚠️')));
    expect('${spec.stdout}', startsWith('# Demo  (1:2)'));
    expect('${spec.stderr}', contains(full.path));

    final humanTokens = await run(<String>['tokens', '1:2', '--file=${depth.path}']);
    expect(humanTokens.exitCode, 0, reason: '${humanTokens.stderr}');
    expect('${humanTokens.stdout}', isNot(contains('⚠️')));
  });

  test('损坏缓存返回 exit 1，不报参数错误', () async {
    final cache = File('${store.dir.path}/nodes-K-broken.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');

    final spec = await run(<String>['spec', '1:2', '--file=${cache.path}']);
    expect(spec.exitCode, 1, reason: '${spec.stderr}');
    expect('${spec.stderr}', contains('缓存文件损坏'));
    expect('${spec.stderr}', isNot(contains('参数错误')));

    final tokens = await run(<String>['tokens', '1:2', '--file=${cache.path}']);
    expect(tokens.exitCode, 1, reason: '${tokens.stderr}');
    expect('${tokens.stderr}', contains('缓存文件损坏'));
  });
}
