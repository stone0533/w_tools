import 'package:flutter/material.dart';

/// 产品语义文字样式。
///
/// Material 的 [TextTheme] 只有 15 个固定角色；业务里的
/// pageTitle / cardTitle / price / badge 等应该放在这里，而不是继续
/// 给每个 WText 写一长串 TextStyle。
enum WTextVariant {
  display,
  headline,
  title,
  body,
  bodyStrong,
  caption,
  label,
  button,
  price,
  number,
  badge,
}

/// WText 的全局语义样式。
///
/// 安装到 ThemeData.extensions 后，页面只需要：
///
/// ```dart
/// WText('标题', variant: WTextVariant.title)
/// ```
///
/// 没有安装时，[of] 会从当前 [TextTheme] 生成一组兜底样式。
///
/// 如果样式里使用 `flutter_screenutil` 的 `.sp`，必须在
/// `ScreenUtilInit` 之后构建；推荐在 `WAppPlugin.builderWrapper` 中
/// 懒构建 ThemeData + WTextStyles，不要在 main / 顶层 final 中计算。
@immutable
class WTextStyles extends ThemeExtension<WTextStyles> {
  const WTextStyles({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.caption,
    required this.label,
    required this.button,
    required this.price,
    required this.number,
    required this.badge,
  });

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle caption;
  final TextStyle label;
  final TextStyle button;
  final TextStyle price;
  final TextStyle number;
  final TextStyle badge;

  /// 从 Flutter TextTheme 生成兜底语义样式。
  factory WTextStyles.fromTextTheme(TextTheme textTheme) {
    final body = textTheme.bodyMedium ?? const TextStyle();
    final title = textTheme.titleLarge ?? const TextStyle();

    return WTextStyles(
      display: textTheme.displayLarge ?? const TextStyle(),
      headline: textTheme.headlineMedium ?? title,
      title: title,
      body: body,
      bodyStrong: body.copyWith(fontWeight: FontWeight.w600),
      caption: textTheme.bodySmall ?? body.copyWith(fontSize: 12),
      label: textTheme.labelMedium ?? body,
      button: textTheme.labelLarge ?? body,
      price: title,
      number: textTheme.bodyLarge ?? body,
      badge: textTheme.labelSmall ?? body.copyWith(fontSize: 12),
    );
  }

  static WTextStyles of(BuildContext context) {
    final extension = Theme.of(context).extension<WTextStyles>();
    return extension ?? WTextStyles.fromTextTheme(Theme.of(context).textTheme);
  }

  TextStyle resolve(WTextVariant variant) {
    return switch (variant) {
      WTextVariant.display => display,
      WTextVariant.headline => headline,
      WTextVariant.title => title,
      WTextVariant.body => body,
      WTextVariant.bodyStrong => bodyStrong,
      WTextVariant.caption => caption,
      WTextVariant.label => label,
      WTextVariant.button => button,
      WTextVariant.price => price,
      WTextVariant.number => number,
      WTextVariant.badge => badge,
    };
  }

  @override
  WTextStyles copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? button,
    TextStyle? price,
    TextStyle? number,
    TextStyle? badge,
  }) {
    return WTextStyles(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      caption: caption ?? this.caption,
      label: label ?? this.label,
      button: button ?? this.button,
      price: price ?? this.price,
      number: number ?? this.number,
      badge: badge ?? this.badge,
    );
  }

  @override
  WTextStyles lerp(ThemeExtension<WTextStyles>? other, double t) {
    if (other is! WTextStyles) return this;

    TextStyle? lerpStyle(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t);

    return WTextStyles(
      display: lerpStyle(display, other.display)!,
      headline: lerpStyle(headline, other.headline)!,
      title: lerpStyle(title, other.title)!,
      body: lerpStyle(body, other.body)!,
      bodyStrong: lerpStyle(bodyStrong, other.bodyStrong)!,
      caption: lerpStyle(caption, other.caption)!,
      label: lerpStyle(label, other.label)!,
      button: lerpStyle(button, other.button)!,
      price: lerpStyle(price, other.price)!,
      number: lerpStyle(number, other.number)!,
      badge: lerpStyle(badge, other.badge)!,
    );
  }
}
