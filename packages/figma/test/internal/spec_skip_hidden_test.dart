import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/spec_handler.dart';
import 'package:w_tools_figma/src/spec/spec_renderer.dart';

void main() {
  test('--skip-hidden 保留隐藏目标自身，不报找不到', () {
    final root = Directory.systemTemp.createTempSync('figma_skip_');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = CacheStore(root, home: '${root.path}/home');
    final file = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:3');
    store.write(file, {
      'nodes': {
        '1:3': {
          'document': {
            'id': '1:2',
            'type': 'FRAME',
            'name': 'Root',
            'opacity': 0,
            'children': [
              {
                'id': '1:3',
                'type': 'TEXT',
                'name': 'HiddenTarget',
                'characters': 'Hi',
                'absoluteBoundingBox': {
                  'x': 0,
                  'y': 0,
                  'width': 100,
                  'height': 20,
                },
                'style': {'fontFamily': 'Inter', 'fontSize': 14},
                'children': <Object?>[],
              },
            ],
          },
        },
      },
    });

    final report = buildSpecReport(
      store,
      nodeIds: const ['1:3'],
      file: file.path,
      skipHidden: true,
    );
    expect(report.entries.single.node['id'], '1:3');
    expect(report.markdowns.single, contains('HiddenTarget'));
  });

  test('--skip-hidden 同时剪掉 node 里的隐藏子树', () {
    final root = Directory.systemTemp.createTempSync('figma_skip_node_');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = CacheStore(root, home: '${root.path}/home');
    final file = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
    store.write(file, {
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
                'name': 'Hidden',
                'visible': false,
                'characters': 'Hidden',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
              },
              {
                'id': '1:4',
                'type': 'TEXT',
                'name': 'Visible',
                'characters': 'Visible',
                'absoluteBoundingBox': {'x': 0, 'y': 10, 'width': 10, 'height': 10},
              },
            ],
          },
        },
      },
    });

    final report =
        buildSpecReport(store, nodeIds: const ['1:2'], file: file.path, skipHidden: true);
    final children = report.entries.single.node['children'] as List<dynamic>;
    expect(children.map((c) => (c as Map)['id']), <String>['1:4']);
    expect(report.markdowns.single, isNot(contains('Hidden')));
  });

  test('--skip-name-prefix 同时剪掉 node 里的前缀子树，', () {
    final root = Directory.systemTemp.createTempSync('figma_skip_prefix_');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = CacheStore(root, home: '${root.path}/home');
    final file = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
    store.write(file, {
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
                'type': 'FRAME',
                'name': '標題 mock',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 10, 'height': 10},
                'children': <Object?>[],
              },
              {
                'id': '1:4',
                'type': 'TEXT',
                'name': 'Body',
                'characters': 'Body',
                'absoluteBoundingBox': {'x': 0, 'y': 10, 'width': 10, 'height': 10},
              },
            ],
          },
        },
      },
    });

    final report = buildSpecReport(
      store,
      nodeIds: const ['1:2'],
      file: file.path,
      renderer: const FigmaSpecRenderer(skipNamePrefixes: <String>['標題']),
    );
    final children = report.entries.single.node['children'] as List<dynamic>;
    expect(children.map((c) => (c as Map)['id']), <String>['1:4']);
    expect(report.markdowns.single, isNot(contains('標題 mock')));
  });
}
