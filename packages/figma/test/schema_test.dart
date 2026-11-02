import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:test/test.dart';

JsonSchema load(String name) {
  final file = File('schema/$name');
  expect(file.existsSync(), isTrue, reason: '缺少 ${file.path}');
  return JsonSchema.create(jsonDecode(file.readAsStringSync()));
}

void main() {
  final cases = <String, Map<String, Object?>>{
    'frames.v1.json': {
      'schema': 'w_tools_figma.frames/1',
      'frames': [
        {
          'id': '1:2',
          'name': 'Demo',
          'width': 100,
          'height': 200,
          'children': 0,
          'cacheFile': 'nodes-K-1-2.json',
        },
      ],
    },
    'fetch.v1.json': {
      'schema': 'w_tools_figma.fetch/1',
      'cacheFile': 'nodes-K-1-2.json',
      'fromCache': false,
      'tierCalls': 1,
      'stale': false,
      'cachedVersion': null,
      'latestVersion': null,
    },
    'specs.v1.json': {
      'schema': 'w_tools_figma.specs/1',
      'items': [
        {
          'source': 'nodes-K-1-2.json',
          'nodeId': '1:2',
          'node': {'id': '1:2', 'type': 'FRAME'},
        },
      ],
    },
    'spec.v1.json': {
      'schema': 'w_tools_figma.spec/1',
      'source': 'nodes-K-1-2.json',
      'nodeId': '1:2',
      'markdown': '# demo  (1:2)\n',
      'node': {'id': '1:2', 'name': 'demo', 'type': 'FRAME'},
    },
    'tokens.v1.json': {
      'schema': 'w_tools_figma.tokens/1',
      'source': 'nodes-K-1-2.json',
      'nodeIds': ['1:2'],
      'counts': {'colors': 1, 'texts': 2, 'radii': 0, 'spacings': 3},
      'markdown': '# tokens\n',
    },
    'diff.v1.json': {
      'schema': 'w_tools_figma.diff/1',
      'fileKey': 'K',
      'nodeId': '1:2',
      'tierCalls': 1,
      'changes': [
        {
          'nodeId': '1:2',
          'name': 'demo',
          'field': 'size',
          'before': '1.0×1.0',
          'after': '2.0×2.0',
        },
      ],
      'nodes': [
        {'nodeId': '1:3', 'name': 'child', 'added': true},
      ],
    },
    'usage.v1.json': {
      'schema': 'w_tools_figma.usage/1',
      'month': '2026-11',
      'used': 1,
      'limit': 20,
      'remaining': 19,
      'recent': [
        {'at': '2026-11-02T00:00:00.000', 'kind': 'nodes', 'cache': 'nodes-K-1-2.json'},
      ],
    },
    'budget.v1.json': {
      'schema': 'w_tools_figma.budget/1',
      'limit': 20,
      'used': 1,
      'remaining': 19,
    },
  };

  for (final entry in cases.entries) {
    test('${entry.key} 校验代表性输出', () {
      final result = load(entry.key).validate(entry.value);
      expect(
        result.isValid,
        isTrue,
        reason: result.errors.map((e) => '${e.instancePath}: ${e.message}').join('\n'),
      );
    });
  }
}
