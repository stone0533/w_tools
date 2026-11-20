import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';

/// `frames` 扫描缓存与直接 `--file` 解析必须给出相同结果。
void main() {
  late Directory root;
  late Directory home;
  late Directory cacheDir;
  late File demoFile;
  late File nestedFile;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_frames_');
    home = Directory.systemTemp.createTempSync('figma_frames_home_');
    cacheDir = CacheStore(root, home: home.path).dir;
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

  test('第二次 frames 走索引，不再解析缓存内容', () async {
    final pinned = DateTime.utc(2026, 1, 1);
    nestedFile.setLastModifiedSync(pinned);
    final first = await run(<String>['frames', '--json', '--all']);
    expect(first.exitCode, 0, reason: '${first.stderr}');

    final indexFile = File('${cacheDir.path}/_nodes-index.json');
    expect(indexFile.existsSync(), isTrue, reason: 'frames 应该写索引');
    final index = jsonDecode(indexFile.readAsStringSync()) as Map;
    expect(index['version'], 5);
    expect(
      (index['files'] as Map).values.any((entry) => (entry as Map)['frames'] is List),
      isTrue,
    );

    final size = nestedFile.statSync().size;
    nestedFile.writeAsStringSync(List<String>.filled(size, ' ').join());
    nestedFile.setLastModifiedSync(pinned);

    final second = await run(<String>['frames', '--json', '--all']);
    expect(second.exitCode, 0, reason: '${second.stderr}');
    expect(
      framesOf('${second.stdout}').map((row) => row['id']),
      containsAll(<String>['1:10', '1:11', '1:12']),
      reason: '索引命中时不应重新解析已被替换的缓存内容',
    );
  });
}
