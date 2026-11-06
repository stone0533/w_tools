import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui_example/playground_config.dart';

void main() {
  test('copyWith 可清空 aspectRatio / memCache', () {
    const config = PlaygroundConfig(aspectRatio: 16 / 9, memCache: 240);
    expect(config.copyWith(aspectRatio: null).aspectRatio, isNull);
    expect(config.copyWith(memCache: null).memCache, isNull);
    expect(config.copyWith(width: 400).aspectRatio, 16 / 9);
    expect(config.copyWith(width: 400).memCache, 240);
  });

  test('默认值', () {
    const config = PlaygroundConfig();
    expect(config.isNetwork, isFalse);
    expect(config.width, 320);
    expect(config.height, 180);
    expect(config.fit, BoxFit.cover);
  });
}
