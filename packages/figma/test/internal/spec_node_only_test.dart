import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/src/cache/cache_store.dart';
import 'package:w_tools_figma/src/cli/spec_handler.dart';
import 'package:w_tools_figma/src/spec/spec_renderer.dart';

/// 记账 renderer：只关心"被调了几次"，不关心渲染内容。
class _RecordingRenderer extends FigmaSpecRenderer {
  int calls = 0;

  @override
  String renderMarkdownFromRoot(Map root, String targetId) {
    calls++;
    return '# fake $targetId\n';
  }
}

void main() {
  late Directory root;
  late Directory home;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_spec_no_md_');
    home = Directory.systemTemp.createTempSync('figma_spec_no_md_home_');
    CacheStore.homeOverride = home.path;
    final cache = File('${CacheStore(root).dir.path}/nodes-K-1-2.json');
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
                'characters': 'hi',
                'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
              },
            ],
          },
        },
      },
    }));
  });

  tearDown(() {
    CacheStore.homeOverride = null;
    // runSpec 会写全局 exitCode；不还原会让测试进程非 0 退出。
    exitCode = 0;
    if (root.existsSync()) root.deleteSync(recursive: true);
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  test('--json --node-only 不渲染 markdown', () async {
    final renderer = _RecordingRenderer();

    await runSpec(['1:2', '--json', '--node-only', '--root=${root.path}'], renderer: renderer);

    expect(exitCode, 0);
    expect(renderer.calls, 0, reason: 'node-only 时不该再渲染一遍 markdown');
  });

  test('--json 不带 node-only 仍渲染（正向对照）', () async {
    final renderer = _RecordingRenderer();

    await runSpec(['1:2', '--json', '--root=${root.path}'], renderer: renderer);

    expect(exitCode, 0);
    expect(renderer.calls, 1);
  });

  test('文本模式仍渲染（输出就是 markdown）', () async {
    final renderer = _RecordingRenderer();

    await runSpec(['1:2', '--root=${root.path}'], renderer: renderer);

    expect(exitCode, 0);
    expect(renderer.calls, 1);
  });
}
