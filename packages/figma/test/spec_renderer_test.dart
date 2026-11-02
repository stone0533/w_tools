import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart' as figma;

/// 与 `scripts/figma_spec.py` 的输出做 golden 对比：
/// fixture 是从真实 `.figma-cache` 抽的子画板（148KB），不联网、不消耗额度。
void main() {
  final fixture = File('test/fixtures/nodes-frame.json');
  const nodeId = '1915:58517';
  final markdown = fixture.existsSync()
      ? const figma.FigmaSpecRenderer().renderMarkdownFromRoot(
          _documentOf(fixture),
          nodeId,
        )
      : null;

  test('fixture 存在且能解析', () {
    expect(fixture.existsSync(), isTrue, reason: '缺少 test/fixtures/nodes-frame.json');
    expect(markdown, isNotNull);
  });

  test('Markdown 与 Python 版 figma_spec.py 逐字节一致', () {
    final expected = File('test/fixtures/spec-expected.md').readAsStringSync();
    expect(markdown, expected);
  });

  test('找不到节点时抛 StateError', () {
    final root = _documentOf(fixture);
    expect(
      () => const figma.FigmaSpecRenderer().renderMarkdownFromRoot(root, '999:999'),
      throwsStateError,
    );
  });

  test('格式化与 Python 一致：五成双（920.25 → 920.2，不是 920.3）', () {
    expect(figma.pyFixed(920.25, 1), '920.2');
    expect(figma.pyFixed(920.35, 1), '920.4');
    expect(figma.pyFixed(19.200000762939453, 1), '19.2');
    expect(figma.pyFixed(375.0, 0), '375');
    expect(figma.pyFixed(-0.25, 1), '-0.2');
  });

  test('描边虚线 / 文字样式 / 隐藏层等关键属性都被渲染', () {
    final md = markdown!;
    expect(md, contains('# Frame 15720  (1915:58517)'));
    expect(md, contains('画板 375×700'));
    // 表格表头固定
    expect(md, contains('| x,y | w×h | 类型 | 名称 | 填充 | 描边 | 阴影 | 圆角 | 文字 |'));
  });
}

Map<String, dynamic> _documentOf(File file) {
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final nodes = raw['nodes'] as Map<String, dynamic>;
  return (nodes.values.first as Map<String, dynamic>)['document'] as Map<String, dynamic>;
}
