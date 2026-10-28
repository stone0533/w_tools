import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_style.dart';

void main() {
  test('不可变：copyWith 返回新实例', () {
    const style = WImageStyle(width: 10, fit: BoxFit.contain);
    final next = style.copyWith(width: 20, borderRadius: BorderRadius.circular(8));
    expect(style.width, 10);
    expect(next.width, 20);
    expect(next.borderRadius, BorderRadius.circular(8));
    expect(next.copyWith(borderRadius: null).borderRadius, isNull);
  });

  test('validate 复用统一规则', () {
    expect(
      () => const WImageStyle(retryCount: -1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageStyle(aspectRatio: 2, width: 1, height: 1).validate(),
      throwsAssertionError,
    );
  });

  test('placeholder 与 builder 不能同时设置', () {
    expect(
      () => WImageStyle(
        placeholder: const Text('p'),
        placeholderBuilder: (_, __) => const Text('b'),
      ).validate(),
      throwsAssertionError,
    );
  });

  test('默认值', () {
    const style = WImageStyle();
    expect(style.fit, BoxFit.cover);
    expect(style.alignment, Alignment.center);
    expect(style.retryCount, 0);
    expect(style.retryDelay, 1000);
    expect(style.filterQuality, FilterQuality.low);
  });
}
