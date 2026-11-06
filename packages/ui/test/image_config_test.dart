import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_config.dart';
import 'package:w_tools_ui/src/components/common/image/image_defaults.dart';

void main() {
  test('WImageLoadOptions copyWith 支持清空可空字段', () {
    const config = WImageLoadOptions(
      memCacheWidth: 100,
      retryCount: 2,
    );
    expect(config.copyWith(memCacheWidth: null).memCacheWidth, isNull);
    expect(config.copyWith(retryCount: 3).retryCount, 3);
  });

  test('WImageLoadOptions 值相等可用于 InheritedWidget 比较', () {
    const a = WImageLoadOptions(retryCount: 2);
    const b = WImageLoadOptions(retryCount: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const WImageLoadOptions(retryCount: 3)));
  });

  test('WImageLoadOptions validate 校验加载约束', () {
    expect(
      () => const WImageLoadOptions(retryCount: -1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageLoadOptions(retryDelay: -1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageLoadOptions(memCacheWidth: 0).validate(),
      throwsAssertionError,
    );
  });

  test('WImageLoadOptions 默认值', () {
    const config = WImageLoadOptions();
    expect(config.retryCount, 0);
    expect(config.retryDelay, 1000);
    expect(config.gaplessPlayback, isFalse);
    expect(config.memCacheWidth, isNull);
  });

  test('WImageSlots 值相等 / validate / 默认值', () {
    const a = WImageSlots(showRetryButton: true);
    const b = WImageSlots(showRetryButton: true);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(const WImageSlots().showRetryButton, isNull);
    expect(const WImageSlots().retryLabel, isNull);
    expect(
      () => WImageSlots(
        placeholder: const Text('p'),
        placeholderBuilder: (_, __) => const Text('b'),
      ).validate(),
      throwsAssertionError,
    );
    expect(
      () => WImageSlots(
        errorWidget: const Text('e'),
        errorWidgetBuilder: (_, __, ___) => const Text('b'),
      ).validate(),
      throwsAssertionError,
    );
  });
}
