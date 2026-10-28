import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image_config.dart';
import 'package:w_tools_ui/src/components/common/image_style.dart';

void main() {
  test('创建后修改原 config 不影响 style', () {
    final config = WImageConfig()
      ..width = 10
      ..fit = BoxFit.contain;
    final style = WImageStyle.fromConfig(config);
    config.width = 99;
    expect(style.width, 10);
    expect(style.fit, BoxFit.contain);
  });

  test('copyWith 覆盖并支持清空 nullable 字段', () {
    final style = WImageStyle(config: WImageConfig()..width = 10);
    final next = style.copyWith(width: 20, borderRadius: BorderRadius.circular(8));
    expect(style.width, 10);
    expect(next.width, 20);
    expect(next.borderRadius, BorderRadius.circular(8));
    expect(next.copyWith(borderRadius: null).borderRadius, isNull);
  });

  test('toConfig 返回独立副本', () {
    final style = WImageStyle(config: WImageConfig()..width = 10);
    final copy = style.toConfig()..width = 99;
    expect(style.width, 10);
    expect(copy.width, 99);
  });

  test('validate 复用 WImageConfig 的规则', () {
    final style = WImageStyle(config: WImageConfig()..retryCount = -1);
    expect(style.validate, throwsAssertionError);
  });
}
