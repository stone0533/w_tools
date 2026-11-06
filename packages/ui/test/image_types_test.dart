import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WImageProgress.fraction', () {
    test('正常值按比例并 clamp', () {
      expect(const WImageProgress(downloadedBytes: 50, totalBytes: 100).fraction, 0.5);
      expect(const WImageProgress(downloadedBytes: 150, totalBytes: 100).fraction, 1.0);
      expect(const WImageProgress(totalBytes: 100).fraction, 0.0);
    });

    test('总大小未知 / 非法时返回 null', () {
      expect(const WImageProgress(downloadedBytes: 10).fraction, isNull);
      expect(const WImageProgress(downloadedBytes: 10, totalBytes: 0).fraction, isNull);
      expect(const WImageProgress(downloadedBytes: 10, totalBytes: -1).fraction, isNull);
    });

    test('相等性与 toString', () {
      const a = WImageProgress(downloadedBytes: 1, totalBytes: 2);
      const b = WImageProgress(downloadedBytes: 1, totalBytes: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('1'));
    });
  });

  group('WImageError.message', () {
    const expected = {
      WImageErrorKind.empty: '图片数据为空',
      WImageErrorKind.network: '网络图片加载失败',
      WImageErrorKind.asset: '本地资源加载失败',
      WImageErrorKind.decode: 'Base64 解码失败',
      WImageErrorKind.provider: '图片解码失败',
      WImageErrorKind.file: '本地文件读取失败',
      WImageErrorKind.unsupported: '当前平台不支持该图片源',
    };

    for (final entry in expected.entries) {
      test('${entry.key.name} → ${entry.value}', () {
        final error = WImageError('raw', entry.key);
        expect(error.message, entry.value);
        expect(error.toString(), contains('raw'));
      });
    }
  });

  group('WImageLoadSnapshot', () {
    test('相等性 / hashCode / toString', () {
      const a = WImageLoadSnapshot(
        status: WImageLoadStatus.loading,
        attempt: 1,
        retryScheduled: true,
        retryDelayMs: 200,
      );
      const b = WImageLoadSnapshot(
        status: WImageLoadStatus.loading,
        attempt: 1,
        retryScheduled: true,
        retryDelayMs: 200,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isLoading, isTrue);
      expect(a.isCompleted, isFalse);
      expect(a.isFailed, isFalse);
      expect(a.toString(), contains('loading'));
    });
  });
  test('WImageError 用 kind 区分分类与文案', () {
    expect(const WImageError('x', WImageErrorKind.empty).kind, WImageErrorKind.empty);
    expect(const WImageError('x', WImageErrorKind.network).message, '网络图片加载失败');
    expect(const WImageError('x', WImageErrorKind.asset).message, '本地资源加载失败');
    expect(const WImageError('x', WImageErrorKind.decode).message, 'Base64 解码失败');
    expect(const WImageError('x', WImageErrorKind.provider).message, '图片解码失败');
    expect(const WImageError('x', WImageErrorKind.file).message, '本地文件读取失败');
    expect(const WImageError('x', WImageErrorKind.unsupported).message, '当前平台不支持该图片源');
  });
  group('WImageStyle', () {
    test('不可变：copyWith 返回新实例', () {
      const style = WImageStyle(width: 10, fit: BoxFit.contain);
      final next = style.copyWith(width: 20, borderRadius: BorderRadius.circular(8));
      expect(style.width, 10);
      expect(next.width, 20);
      expect(next.borderRadius, BorderRadius.circular(8));
      expect(next.copyWith(borderRadius: null).borderRadius, isNull);
    });

    test('validate 校验视觉约束', () {
      expect(
        () => const WImageStyle(aspectRatio: 2, width: 1, height: 1).validate(),
        throwsAssertionError,
      );
      expect(() => const WImageStyle(aspectRatio: 0).validate(), throwsAssertionError);
    });

    test('常用预设', () {
      final avatar = WImageStyle.avatar(80);
      expect(avatar.width, 80);
      expect(avatar.height, 80);
      expect(avatar.borderRadius, BorderRadius.circular(40));
      expect(avatar.fit, BoxFit.cover);

      final thumb = WImageStyle.thumbnail(80);
      expect(thumb.width, 80);
      expect(thumb.height, 80);

      final cover = WImageStyle.cover(aspectRatio: 2, radius: 12);
      expect(cover.aspectRatio, 2);
      expect(cover.borderRadius, BorderRadius.circular(12));
    });

    test('链式糖返回新实例', () {
      const base = WImageStyle();
      final next = base.square(40).rounded(20);
      expect(base.width, isNull);
      expect(next.width, 40);
      expect(next.height, 40);
      expect(next.borderRadius, BorderRadius.circular(20));
    });

    test('默认值', () {
      const style = WImageStyle();
      expect(style.fit, BoxFit.cover);
      expect(style.alignment, Alignment.center);
      expect(style.filterQuality, FilterQuality.low);
    });

    test('copyWith(null) 可清空可空字段', () {
      const style = WImageStyle(
        width: 10,
        height: 20,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF000000))),
        semanticLabel: 'avatar',
      );
      final cleared = style.copyWith(
        width: null,
        height: null,
        borderRadius: null,
        border: null,
        semanticLabel: null,
      );
      expect(cleared.width, isNull);
      expect(cleared.height, isNull);
      expect(cleared.borderRadius, isNull);
      expect(cleared.border, isNull);
      expect(cleared.semanticLabel, isNull);
      final kept = style.copyWith(fit: BoxFit.contain);
      expect(kept.width, 10);
      expect(kept.fit, BoxFit.contain);
    });
  });

  group('WImageLoadOptions', () {
    test('copyWith 支持清空可空字段', () {
      const config = WImageLoadOptions(memCacheWidth: 100, retryCount: 2);
      expect(config.copyWith(memCacheWidth: null).memCacheWidth, isNull);
      expect(config.copyWith(retryCount: 3).retryCount, 3);
    });

    test('值相等可用于 InheritedWidget 比较', () {
      const a = WImageLoadOptions(retryCount: 2);
      const b = WImageLoadOptions(retryCount: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const WImageLoadOptions(retryCount: 3)));
    });

    test('validate 校验加载约束', () {
      expect(() => const WImageLoadOptions(retryCount: -1).validate(), throwsAssertionError);
      expect(() => const WImageLoadOptions(retryDelay: -1).validate(), throwsAssertionError);
      expect(() => const WImageLoadOptions(memCacheWidth: 0).validate(), throwsAssertionError);
    });

    test('默认值', () {
      const config = WImageLoadOptions();
      expect(config.retryCount, 0);
      expect(config.retryDelay, 1000);
      expect(config.gaplessPlayback, isFalse);
      expect(config.memCacheWidth, isNull);
    });
  });

  group('WImageSlots', () {
    test('值相等 / validate / 默认值', () {
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
  });
}
