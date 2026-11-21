import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/spec_handler.dart';

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
}
