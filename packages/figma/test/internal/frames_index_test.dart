import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';

/// `frames` 走 `_nodes-index.json` 与直接 `--file` 解析必须给出相同结果，
/// 并且第二次调用不能再读缓存文件内容。
void main() {
  late Directory root;
  late Directory home;
  late Directory cacheDir;
  late File demoFile;
  late File nestedFile;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_frames_');
    home = Directory.systemTemp.createTempSync('figma_frames_home_');
    CacheStore.homeOverride = home.path;
    cacheDir = CacheStore(root).dir;
    cacheDir.createSync(recursive: true);

    demoFile = File('${cacheDir.path}/nodes-demo.json')
      ..writeAsStringSync(File('example/fixtures/nodes-demo.json').readAsStringSync());
    nestedFile = File('${cacheDir.path}/nodes-nested.json')
      ..writeAsStringSync(jsonEncode({
        'nodes': {
          'c:1': {
            'document': {
              'id': 'c:1',
              'type': 'CANVAS',
              'name': 'Home',
              'children': [
                {
                  'id': '1:10',
                  'type': 'FRAME',
                  'name': 'Top',
                  'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 100},
                  'children': [
                    {
                      'id': '1:11',
                      'type': 'FRAME',
                      'name': 'Inner',
                      'absoluteBoundingBox': {'x': 1, 'y': 1, 'width': 50, 'height': 50},
                      'children': <Object?>[],
                    },
                  ],
                },
                {
                  'id': '1:12',
                  'type': 'FRAME',
                  'name': 'Second',
                  'absoluteBoundingBox': {'x': 0, 'y': 200, 'width': 100, 'height': 100},
                  'children': <Object?>[],
                },
              ],
            },
          },
        },
      }));
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  Future<ProcessResult> run(List<String> args) {
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

  /// 只比 id/name/page/width/height/children；cacheFile 带绝对路径，两边必然不同。
  List<Map<String, dynamic>> framesOf(String stdout) {
    final list = ((jsonDecode(stdout) as Map)['frames'] as List)
        .cast<Map<String, dynamic>>()
        .map((row) => <String, dynamic>{...row}..remove('cacheFile'))
        .toList();
    list.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    return list;
  }

  /// 直接解析：每个缓存文件单独跑一次 `--file`，再按 id 合并。
  Future<List<Map<String, dynamic>>> direct(List<String> extra) async {
    final merged = <String, Map<String, dynamic>>{};
    for (final file in <File>[demoFile, nestedFile]) {
      final result = await run(<String>['frames', '--json', '--file=${file.path}', ...extra]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      for (final row in framesOf('${result.stdout}')) {
        merged['${row['id']}'] = row;
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    return list;
  }

  test('索引路径与直接解析一致（默认只列顶层）', () async {
    final indexed = await run(<String>['frames', '--json']);
    expect(indexed.exitCode, 0, reason: '${indexed.stderr}');

    expect(framesOf('${indexed.stdout}'), await direct(<String>[]));
  });

  test('索引路径与直接解析一致（--all 含嵌套）', () async {
    final indexed = await run(<String>['frames', '--json', '--all']);
    expect(indexed.exitCode, 0, reason: '${indexed.stderr}');
    final rows = framesOf('${indexed.stdout}');

    expect(rows, await direct(<String>['--all']));
    expect(rows.map((r) => r['id']), contains('1:11'));
  });

  test('--name / --page 过滤在两条路径上一致', () async {
    final byName = await run(<String>['frames', '--json', '--name=Top']);
    expect(byName.exitCode, 0, reason: '${byName.stderr}');
    expect(framesOf('${byName.stdout}'), await direct(<String>['--name=Top']));

    final byPage = await run(<String>['frames', '--json', '--page=Home']);
    expect(byPage.exitCode, 0, reason: '${byPage.stderr}');
    expect(framesOf('${byPage.stdout}'), await direct(<String>['--page=Home']));
  });

  test('同名画板按 id 排序，输出顺序稳定', () async {
    File('${cacheDir.path}/nodes-same.json').writeAsStringSync(jsonEncode({
      'nodes': {
        'c:2': {
          'document': {
            'id': 'c:2',
            'type': 'CANVAS',
            'name': 'Page',
            'children': [
              {
                'id': '2:1',
                'type': 'FRAME',
                'name': 'Same',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
                'children': <Object?>[],
              },
              {
                'id': '1:9',
                'type': 'FRAME',
                'name': 'Same',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
                'children': <Object?>[],
              },
            ],
          },
        },
      },
    }));

    final result = await run(<String>['frames', '--json', '--name=Same']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final frames =
        ((jsonDecode('${result.stdout}') as Map)['frames'] as List).cast<Map<String, dynamic>>();
    expect(
      frames.map((frame) => frame['id']).toList(),
      <String>['1:9', '2:1'],
      reason: '同名时按 id 兜底，别依赖目录遍历顺序',
    );
  });

  test('第二次 frames 不再读缓存文件内容', () async {
    // 先钉成整秒，避免不同文件系统的 mtime 精度让"索引不重建"变得不可复现。
    nestedFile.setLastModifiedSync(DateTime.utc(2026, 1, 1));
    final first = await run(<String>['frames', '--json', '--all']);
    expect(first.exitCode, 0, reason: '${first.stderr}');

    final indexFile = File('${cacheDir.path}/_nodes-index.json');
    expect(indexFile.existsSync(), isTrue, reason: '第一次调用应该建索引');
    expect((jsonDecode(indexFile.readAsStringSync()) as Map)['version'], 3);

    // 等长的非法 JSON + 还原 mtime：size/mtime 都没变，索引不会重建。
    // mtime 固定在整秒：Linux 上 setLastModifiedSync 会丢毫秒，跨平台只能比整秒。
    final pinned = DateTime.utc(2026, 1, 1);
    final stat = nestedFile.statSync();
    final size = stat.size;
    nestedFile.writeAsStringSync(List<String>.filled(size, ' ').join());
    nestedFile.setLastModifiedSync(pinned);
    expect(nestedFile.statSync().size, size);
    expect(nestedFile.statSync().modified.millisecondsSinceEpoch, pinned.millisecondsSinceEpoch);

    final second = await run(<String>['frames', '--json', '--all']);
    expect(second.exitCode, 0, reason: '${second.stderr}');
    expect(
      framesOf('${second.stdout}').map((r) => r['id']),
      containsAll(<String>['1:10', '1:11', '1:12']),
      reason: 'frames 若退回直接解析，会跳过这份"损坏"缓存并丢掉这些行',
    );
  });
}
