import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_config.dart';

void main() {
  test('copyWith 支持清空可空字段', () {
    const config = WImageConfig(
      memCacheWidth: 100,
      retryCount: 2,
      placeholder: Text('p'),
    );
    expect(config.copyWith(memCacheWidth: null).memCacheWidth, isNull);
    expect(config.copyWith(placeholder: null).placeholder, isNull);
    expect(config.copyWith(retryCount: 3).retryCount, 3);
  });

  test('validate 校验加载约束', () {
    expect(
      () => const WImageConfig(retryCount: -1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageConfig(retryDelay: -1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageConfig(memCacheWidth: 0).validate(),
      throwsAssertionError,
    );
    expect(
      () => WImageConfig(
        placeholder: const Text('p'),
        placeholderBuilder: (_, __) => const Text('b'),
      ).validate(),
      throwsAssertionError,
    );
  });

  test('默认值', () {
    const config = WImageConfig();
    expect(config.retryCount, 0);
    expect(config.retryDelay, 1000);
    expect(config.gaplessPlayback, isFalse);
    expect(config.showRetryButton, isFalse);
    expect(config.retryLabel, '重试');
  });
}
