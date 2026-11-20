import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cache/nodes_index.dart';
import 'package:w_tools_figma/src/cli/frames_handler.dart';
import 'package:w_tools_figma/src/cli/spec_handler.dart';
import 'package:w_tools_figma/src/cli/tokens_handler.dart';

/// 命令纯逻辑的无 CLI 直测：不启动子进程、不联网。
void main() {
  late Directory root;
  late Directory home;
  late CacheStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_cmd_');
    home = Directory.systemTemp.createTempSync('figma_cmd_home_');
    store = CacheStore(root, home: home.path);
    store.dir.createSync(recursive: true);
    File('${store.dir.path}/nodes-K-1-2.json').writeAsStringSync(jsonEncode({
      'nodes': {
        '1:2': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Zeta',
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
                'type': 'FRAME',
                'name': 'Alpha',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 5, 'height': 5},
                'children': <Object?>[],
              },
              {
                'id': '1:4',
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
  });

  tearDown(() {
    exitCode = 0;
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  test('frames：默认只给顶层，--all 才带嵌套，过滤 + 排序在对象里', () {
    final top = framesFromIndex(store, root: root, all: false).rows;
    expect(top.map((row) => row['id']), <String>['1:2']);

    final all = framesFromIndex(store, root: root, all: true).rows;
    expect(filterFrames(all, nameFilter: 'alp').map((row) => row['id']), <String>['1:3']);
    expect(
      filterFrames(all).map((row) => row['name']),
      <String>['Alpha', 'Zeta'],
      reason: '按 name 排序，同名前缀下嵌套画板在前',
    );
  });

  test('spec：includeMarkdown 控制是否渲染，nodeDepth 裁剪 children', () {
    final withoutMarkdown = buildSpecReport(
      store,
      nodeIds: <String>['1:2'],
      includeMarkdown: false,
    );
    expect(withoutMarkdown.entries.single.markdown, isNull);
    expect(withoutMarkdown.markdowns, isEmpty);

    final withMarkdown = buildSpecReport(store, nodeIds: <String>['1:2']);
    expect(withMarkdown.entries.single.markdown, contains('Zeta'));
    expect(withMarkdown.markdowns, hasLength(1));

    final trimmed = buildSpecReport(
      store,
      nodeIds: <String>['1:2'],
      nodeDepth: 0,
      includeMarkdown: false,
    );
    expect((trimmed.entries.single.node).containsKey('children'), isFalse);
  });

  test('tokens：返回四类统计 + 数据源 + markdown', () {
    final report = buildTokensReport(store, nodeIds: <String>['1:2']);

    expect(report.colors.map((c) => c.value), contains('#FF0000'));
    expect(report.texts.single.family, 'Inter');
    expect(report.radii, isEmpty);
    expect(report.sources, hasLength(1));
    expect(report.nodeIds, <String>['1:2']);
    expect(report.markdown, contains('# 设计 token'));
  });
}
