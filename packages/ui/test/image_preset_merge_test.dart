import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WImageStyle.merge', () {
    test('保留预设字段', () {
      final merged = WImageStyle.avatar(40).merge(const WImageStyle(semanticLabel: '头像'));
      expect(merged.width, 40);
      expect(merged.height, 40);
      expect(merged.borderRadius, BorderRadius.circular(20));
      expect(merged.semanticLabel, '头像');
    });

    test('覆盖字段优先，null 参数不改变预设', () {
      final merged = WImageStyle.avatar(40).merge(
        WImageStyle(
          width: 64,
          borderRadius: BorderRadius.circular(8),
        ),
      );
      expect(merged.width, 64);
      expect(merged.height, 40);
      expect(merged.borderRadius, BorderRadius.circular(8));
    });

    test('merge(null) 返回自身', () {
      final style = WImageStyle.avatar(40);
      expect(identical(style.merge(null), style), isTrue);
    });
  });

  group('WImage 命名构造：style 是覆盖而不是替换', () {
    test('avatar 传 style 不再丢掉 40×40 与圆角', () {
      final image = WImage.avatar(
        'avatar.png',
        style: const WImageStyle(semanticLabel: '头像'),
      );

      expect(image.style.width, 40);
      expect(image.style.height, 40);
      expect(image.style.borderRadius, BorderRadius.circular(20));
      expect(image.style.semanticLabel, '头像');
    });

    test('avatar 的 size 仍是未给宽高时的 fallback', () {
      final image = WImage.avatar(
        'avatar.png',
        size: 64,
        style: const WImageStyle(semanticLabel: '头像'),
      );

      expect(image.style.width, 64);
      expect(image.style.height, 64);
      expect(image.style.borderRadius, BorderRadius.circular(32));
    });

    test('avatar 只覆盖宽度时仍保持正方形', () {
      final image = WImage.avatar(
        'avatar.png',
        style: const WImageStyle(width: 64),
      );

      expect(image.style.width, 64);
      expect(image.style.height, 64);
    });

    test('thumbnail 用合并后的尺寸推导解码上限', () {
      final image = WImage.thumbnail(
        'thumb.png',
        style: const WImageStyle(width: 120),
      );

      expect(image.style.width, 120);
      expect(image.style.height, 120);
      expect(image.config.memCacheWidth, 360);
      expect(image.config.memCacheHeight, 360);
    });

    test('cover 保留预设比例，style 圆角生效', () {
      final image = WImage.cover(
        'cover.png',
        style: WImageStyle(borderRadius: BorderRadius.circular(4)),
      );

      expect(image.style.aspectRatio, 16 / 9);
      expect(image.style.borderRadius, BorderRadius.circular(4));
    });
  });
}
