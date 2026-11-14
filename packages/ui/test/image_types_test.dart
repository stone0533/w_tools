import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 刻意返回非 const 实例：值相等测试不能依赖 const canonicalization。
WImageLoadOptions _options(int retryCount) => WImageLoadOptions(retryCount: retryCount);

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

  testWidgets('WImageError.localizedMessage 跟随 Locale', (tester) async {
    const error = WImageError('raw', WImageErrorKind.network);

    Future<String> localized(Locale locale) async {
      late String value;
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              value = error.localizedMessage(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return value;
    }

    expect(await localized(const Locale('zh')), '网络图片加载失败');
    expect(await localized(const Locale('en')), 'Network image failed');
    expect(error.message, '网络图片加载失败');
  });

  group('WImageError.message', () {
    const expected = {
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

  test('WImageError 用 kind 区分分类与文案', () {
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
      expect(next.copyWith(borderRadius: null).borderRadius, isNotNull);
      expect(next.withoutBorderRadius().borderRadius, isNull);
    });

    test('validate 校验视觉约束', () {
      expect(
        () => const WImageStyle(aspectRatio: 2, width: 1, height: 1).validate(),
        throwsAssertionError,
      );
      expect(() => const WImageStyle(aspectRatio: 0).validate(), throwsAssertionError);
    });

    test('常用预设', () {
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

    test('cover().square() 会清空 aspectRatio，组合仍是合法样式', () {
      final style = WImageStyle.cover().square(40);
      expect(style.aspectRatio, isNull);
      expect(style.width, 40);
      expect(style.height, 40);
      expect(style.validate, returnsNormally);
    });

    test('copyWith 设置 width/height 时清空 aspectRatio', () {
      final style = WImageStyle.cover().copyWith(width: 100);
      expect(style.aspectRatio, isNull);
      expect(style.validate, returnsNormally);

      final height = WImageStyle.cover().copyWith(height: 100);
      expect(height.aspectRatio, isNull);
      expect(height.validate, returnsNormally);
    });

    test('默认值', () {
      const style = WImageStyle();
      expect(style.fit, BoxFit.cover);
      expect(style.alignment, Alignment.center);
      expect(style.filterQuality, FilterQuality.low);
    });

    test('copyWith(null) 保留字段，without* 才能清空', () {
      const style = WImageStyle(
        width: 10,
        height: 20,
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF000000))),
        semanticLabel: 'avatar',
      );
      final kept = style.copyWith(
        width: null,
        height: null,
        borderRadius: null,
        border: null,
        semanticLabel: null,
      );
      expect(kept.width, 10);
      expect(kept.height, 20);
      expect(kept.borderRadius, isNotNull);
      expect(kept.border, isNotNull);
      expect(kept.semanticLabel, 'avatar');
      expect(kept.fit, style.fit);

      final cleared = style
          .withoutWidth()
          .withoutHeight()
          .withoutBorderRadius()
          .withoutBorder()
          .withoutSemanticLabel();
      expect(cleared.width, isNull);
      expect(cleared.height, isNull);
      expect(cleared.borderRadius, isNull);
      expect(cleared.border, isNull);
      expect(cleared.semanticLabel, isNull);

      final changed = style.copyWith(fit: BoxFit.contain);
      expect(changed.width, 10);
      expect(changed.fit, BoxFit.contain);
    });
  });

  group('WImageLoadOptions', () {
    test('copyWith(null) 保留解码尺寸，without* 才能清空', () {
      const config = WImageLoadOptions(memCacheWidth: 100, retryCount: 2);
      expect(config.copyWith(memCacheWidth: null).memCacheWidth, 100);
      expect(config.withoutMemCacheWidth().memCacheWidth, isNull);
      expect(config.copyWith(retryCount: 3).retryCount, 3);
    });

    test('值相等可用于 InheritedWidget 比较（非 const 实例）', () {
      final a = _options(2);
      final b = _options(2);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(_options(3)));
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

  group('WImageError 值相等', () {
    test('data + kind 相同即相等，cause 不参与', () {
      const a = WImageError('x', WImageErrorKind.network);
      const b = WImageError('x', WImageErrorKind.network, cause: 'boom');
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const WImageError('y', WImageErrorKind.network)));
      expect(a, isNot(const WImageError('x', WImageErrorKind.asset)));
    });
  });

  group('WImageSlots', () {
    test('默认无 builder；同实例相等', () {
      const slots = WImageSlots();
      expect(slots.placeholderBuilder, isNull);
      expect(slots.errorWidgetBuilder, isNull);
      expect(slots, const WImageSlots());
      expect(slots.hashCode, const WImageSlots().hashCode);
    });
  });
}
