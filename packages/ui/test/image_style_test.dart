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

  test('validate 校验视觉约束', () {
    expect(
      () => const WImageStyle(aspectRatio: 2, width: 1, height: 1).validate(),
      throwsAssertionError,
    );
    expect(
      () => const WImageStyle(aspectRatio: 0).validate(),
      throwsAssertionError,
    );
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
}
