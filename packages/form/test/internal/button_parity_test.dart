import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `WFormButton` 与 `WFormFieldButton<T>` 的字段声明是两份（API 快照不跟随继承），
/// 这里用源码级对比防止新增/删除参数时只改一边。
void main() {
  test('WFormButton 与 WFormFieldButton 构造参数保持同步', () {
    final source = File('lib/src/components/direct_fields.dart').readAsStringSync();

    expect(
      _constructorParams(source, 'WFormButton'),
      _constructorParams(source, 'WFormFieldButton'),
    );
  });
}

List<String> _constructorParams(String source, String className) {
  final start = source.indexOf('const $className({');
  expect(start, isNot(-1), reason: '找不到 $className 构造函数');
  final end = source.indexOf('});', start);
  expect(end, isNot(-1), reason: '找不到 $className 构造函数结尾');
  final body = source.substring(start, end);
  return RegExp(r'(?:this|super)\.(\w+)').allMatches(body).map((match) => match.group(1)!).toList();
}
