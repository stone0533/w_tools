import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:w_tools_figma/w_tools_figma.dart';

/// `diff` 的测试：用 fake client 提供「改版后」的数据，旧数据来自本地缓存。
class _Client implements FigmaClient {
  _Client(this.payload);

  final Map<String, dynamic> payload;
  final calls = <Uri>[];

  @override
  Future<Map<String, dynamic>> getJson(Uri url) async {
    calls.add(url);
    return payload;
  }

  @override
  void close() {}
}

Map<String, dynamic> _tree({
  required String label,
  required double size,
  bool extraChild = false,
}) {
  return {
    'nodes': {
      '1:2': {
        'document': {
          'id': '1:2',
          'type': 'FRAME',
          'name': 'Demo',
          'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 375, 'height': 700},
          'children': [
            {
              'id': '1:3',
              'type': 'TEXT',
              'name': 'Title',
              'absoluteBoundingBox': {'x': 0, 'y': 0, 'width': 100, 'height': 24},
              'characters': label,
              'fills': [
                {
                  'type': 'SOLID',
                  'color': {'r': 0.2, 'g': 0.2, 'b': 0.2},
                },
              ],
              'style': {
                'fontFamily': 'Noto Sans',
                'fontWeight': 700,
                'fontSize': size,
                'lineHeightPx': size * 1.6,
                'letterSpacing': 0,
                'textAlignHorizontal': 'LEFT',
              },
            },
            if (extraChild)
              {
                'id': '1:4',
                'type': 'RECTANGLE',
                'name': 'NewBadge',
                'absoluteBoundingBox': {'x': 0, 'y': 40, 'width': 20, 'height': 20},
                'fills': [
                  {
                    'type': 'SOLID',
                    'color': {'r': 1, 'g': 0, 'b': 0},
                  },
                ],
              },
          ],
        },
      },
    },
  };
}

void main() {
  late Directory root;
  late CacheStore store;

  late Directory home;

  setUp(() {
    root = Directory.systemTemp.createTempSync('figma_diff_');
    home = Directory.systemTemp.createTempSync('figma_diff_home_');
    store = CacheStore(root, home: home.path);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    home.deleteSync(recursive: true);
  });

  test('无变化时返回空结果', () async {
    final payload = _tree(label: 'Hello', size: 16);
    // 旧缓存 = 新数据
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), payload);
    final result = await DiffCommand(store: store, client: _Client(payload)).run(
      fileKey: 'K',
      nodeId: '1:2',
    );
    expect(result.isEmpty, isTrue);
    expect(result.tierCalls, 1);
    final target = store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2');
    expect(File('${target.path}.prev').existsSync(), isFalse);
  });

  test('字号与文案变化都能报出来', () async {
    final before = _tree(label: 'Hello', size: 16);
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), before);
    final after = _tree(label: 'Hello!', size: 18);

    final result = await DiffCommand(store: store, client: _Client(after)).run(
      fileKey: 'K',
      nodeId: '1:2',
    );
    final fields = result.changes.map((c) => c.field).toSet();
    expect(fields, containsAll(['characters', 'text']));
    expect(
      result.changes.any((c) => c.field == 'text' && c.after.contains('18.0px')),
      isTrue,
      reason: '字号从 16 变成 18，应体现在 text 属性里',
    );
    expect(
      result.changes.any((c) => c.field == 'characters' && c.after == 'Hello!'),
      isTrue,
    );
  });

  test('位置 / 间距 / padding / 四角圆角变化都能报出来', () {
    final before = _tree(label: 'Hi', size: 16);
    final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
    final doc = (after['nodes'] as Map)['1:2'] as Map;
    final child = ((doc['document'] as Map)['children'] as List).first as Map;
    (child['absoluteBoundingBox'] as Map)['x'] = 24;
    child['itemSpacing'] = 8;
    child['paddingLeft'] = 12;
    child['paddingRight'] = 12;
    child['paddingTop'] = 8;
    child['paddingBottom'] = 8;
    child['rectangleCornerRadii'] = [4, 8, 4, 8];

    final beforeDoc = ((before['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final afterDoc = ((after['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final fields = const SpecDiff().changes(beforeDoc, afterDoc).map((c) => c.field).toSet();
    expect(fields, containsAll(<String>['position', 'layout', 'radius']));
  });

  test('layoutMode / 主轴对齐变化也报 layout', () {
    final before = _tree(label: 'Hi', size: 16);
    final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
    final beforeDoc = ((before['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final afterDoc = ((after['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final beforeChild = (beforeDoc['children'] as List).first as Map;
    final afterChild = (afterDoc['children'] as List).first as Map;
    beforeChild['layoutMode'] = 'HORIZONTAL';
    beforeChild['primaryAxisAlignItems'] = 'MIN';
    afterChild['layoutMode'] = 'VERTICAL';
    afterChild['primaryAxisAlignItems'] = 'CENTER';

    final change =
        const SpecDiff().changes(beforeDoc, afterDoc).firstWhere((c) => c.field == 'layout');

    expect(change.before, contains('layoutMode=HORIZONTAL'));
    expect(change.after, contains('layoutMode=VERTICAL'));
    expect(change.after, contains('primary=CENTER'));
  });

  test('rotation / mask / clip / 文字 decoration / paint opacity 变化都能报', () {
    final before = _tree(label: 'Hi', size: 16);
    final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
    final beforeDoc = ((before['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final afterDoc = ((after['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final beforeChild = (beforeDoc['children'] as List).first as Map;
    final afterChild = (afterDoc['children'] as List).first as Map;

    beforeChild['rotation'] = 0;
    afterChild['rotation'] = 12;
    beforeChild['isMask'] = false;
    afterChild['isMask'] = true;
    beforeChild['clipsContent'] = false;
    afterChild['clipsContent'] = true;
    beforeChild['style']['textDecoration'] = 'NONE';
    afterChild['style']['textDecoration'] = 'UNDERLINE';
    (beforeChild['fills'] as List).first['opacity'] = 1;
    (afterChild['fills'] as List).first['opacity'] = 0.5;

    final fields = const SpecDiff().changes(beforeDoc, afterDoc).map((c) => c.field).toSet();

    expect(
      fields,
      containsAll(<String>[
        'rotation',
        'isMask',
        'clipsContent',
        'textDecoration',
        'fills',
      ]),
    );
  });

  test('渐变 / 图片的具体内容参与 diff，不只看 GRAD/IMG', () {
    Map<String, dynamic> node(List<Map<String, Object?>> fills) => {
          'id': '1:2',
          'type': 'RECTANGLE',
          'name': 'Bg',
          'fills': fills,
        };
    const differ = SpecDiff();

    final gradientA = node([
      {
        'type': 'GRADIENT_LINEAR',
        'gradientStops': [
          {
            'position': 0,
            'color': {'r': 1, 'g': 0, 'b': 0},
          },
          {
            'position': 1,
            'color': {'r': 0, 'g': 0, 'b': 1},
          },
        ],
      },
    ]);
    final gradientB = jsonDecode(jsonEncode(gradientA)) as Map<String, dynamic>;
    ((((gradientB['fills'] as List).first as Map)['gradientStops'] as List).first as Map)['color'] =
        {'r': 0, 'g': 1, 'b': 0};
    expect(differ.changes(gradientA, gradientB).any((c) => c.field == 'fills'), isTrue);

    final imageA = node([
      {'type': 'IMAGE', 'imageRef': 'a'},
    ]);
    final imageB = node([
      {'type': 'IMAGE', 'imageRef': 'b'},
    ]);
    expect(differ.changes(imageA, imageB).any((c) => c.field == 'fills'), isTrue);

    final rotated = jsonDecode(jsonEncode(gradientA)) as Map<String, dynamic>;
    (((rotated['fills'] as List).first as Map)['gradientHandlePositions'] = [
      {'x': 1, 'y': 0},
      {'x': 0, 'y': 1},
    ]);
    expect(
      differ.changes(gradientA, rotated).any((c) => c.field == 'fills'),
      isTrue,
      reason: '同 stops、不同渐变方向也要报 fills',
    );
  });

  test('整页平移只报父节点位置，不刷子节点', () {
    final before = _tree(label: 'Hi', size: 16);
    final after = jsonDecode(jsonEncode(before)) as Map<String, dynamic>;
    final beforeDoc = ((before['nodes'] as Map)['1:2'] as Map)['document'] as Map;
    final afterDoc = ((after['nodes'] as Map)['1:2'] as Map)['document'] as Map;

    (afterDoc['absoluteBoundingBox'] as Map)['x'] = 100;
    (afterDoc['absoluteBoundingBox'] as Map)['y'] = 100;
    final child = (afterDoc['children'] as List).first as Map;
    (child['absoluteBoundingBox'] as Map)['x'] = 100;
    (child['absoluteBoundingBox'] as Map)['y'] = 100;

    final positionChanges = const SpecDiff()
        .changes(beforeDoc, afterDoc)
        .where((change) => change.field == 'position')
        .map((change) => change.nodeId)
        .toList();
    expect(positionChanges, <String>['1:2'], reason: '子节点相对父节点没动');
  });

  test('新增节点报为 +', () async {
    final before = _tree(label: 'Hi', size: 16);
    store.write(store.cacheFile(kind: 'nodes', fileKey: 'K', ids: '1:2'), before);
    final after = _tree(label: 'Hi', size: 16, extraChild: true);

    final result = await DiffCommand(store: store, client: _Client(after)).run(
      fileKey: 'K',
      nodeId: '1:2',
    );
    expect(result.nodes.length, 1);
    expect(result.nodes.first.added, isTrue);
    expect(result.nodes.first.name, 'NewBadge');
  });

  test('没有旧缓存时退化为「只拉新」，不报改动', () async {
    final payload = _tree(label: 'Hi', size: 16);
    final result = await DiffCommand(store: store, client: _Client(payload)).run(
      fileKey: 'K',
      nodeId: '1:2',
    );
    expect(result.isEmpty, isTrue);
    expect(result.tierCalls, 1);
  });
}
