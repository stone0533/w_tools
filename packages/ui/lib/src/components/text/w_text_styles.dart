import 'package:flutter/material.dart';

/// 产品语义文字样式。
///
/// Material 的 [TextTheme] 只有 15 个固定角色；业务里的
/// pageTitle / cardTitle / price / badge 等应该放在这里，而不是继续
/// 给每个 WText 写一长串 TextStyle。
/// 语义角色固定。
///
/// 不够用时按顺序处理：
/// 1. 一次性差异用 [WText.style] 局部覆盖；
/// 2. 项目内重复抽本地 helper / 组件；
/// 3. 稳定跨页面语义才新增 enum（公开 API 变更）。
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
/// WText(text: '标题', variant: WTextVariant.title)
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
  ///
  /// 与 [toTextTheme] 使用同一张表：`body` 取 `bodyMedium`（toTextTheme 同时写
  /// bodyLarge / bodyMedium），`number` 不投影、兜底取 `bodyLarge`。
  factory WTextStyles.fromTextTheme(TextTheme textTheme) {
    final body = textTheme.bodyMedium ?? const TextStyle();
    final title = textTheme.titleLarge ?? const TextStyle();

    return WTextStyles(
      display: textTheme.displayLarge ?? const TextStyle(),
      headline: textTheme.headlineMedium ?? title,
      title: title,
      body: body,
      bodyStrong: textTheme.titleMedium ?? body.copyWith(fontWeight: FontWeight.w600),
      caption: textTheme.bodySmall ?? body.copyWith(fontSize: 12),
      label: textTheme.labelMedium ?? body,
      button: textTheme.labelLarge ?? body,
      price: textTheme.headlineSmall ?? title,
      number: textTheme.bodyLarge ?? body,
      badge: textTheme.labelSmall ?? body.copyWith(fontSize: 12),
    );
  }

  /// 把语义角色写进 Material [TextTheme]。
  ///
  /// 映射按 **Material 的消费点**选取，而不是一一对应：
  /// - `body` 同时写 `bodyLarge`（`TextField` 输入）与 `bodyMedium`（普通正文）；
  /// - `number` **不投影**：`bodyLarge` 已被 body 占用，若把 number 写进去，
  ///   所有表单输入会变成数字样式；
  /// - 未涉及的槽位保留 [base]。
  ///
  /// 应用侧用 [WThemeDataExtension.withWTextStyles] 一次装好：
  /// 之后 form / toast / async 只读 `Theme.of(context).textTheme` 即可跟随，
  /// 不需要依赖 w_tools_ui。
  TextTheme toTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: display,
      headlineMedium: headline,
      titleLarge: title,
      headlineSmall: price,
      titleMedium: bodyStrong,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelMedium: label,
      labelLarge: button,
      labelSmall: badge,
    );
  }

  /// 兜底样式的缓存：未安装扩展时按 `TextTheme` 实例复用，避免每次 build 重建 11 个样式。
  static final Expando<WTextStyles> _fallbacks = Expando<WTextStyles>('WTextStyles.fallback');

  static WTextStyles of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<WTextStyles>();
    if (extension != null) return extension;
    return _fallbacks[theme.textTheme] ??= WTextStyles.fromTextTheme(theme.textTheme);
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

/// 应用侧的一次性安装入口：让 `TextTheme` 与语义角色同源。
///
/// 三个包（form / toast / async）只读 `Theme.of(context).textTheme`，
/// 因此不需要依赖 w_tools_ui；由应用在构建 ThemeData 时装一次即可。
extension WThemeDataExtension on ThemeData {
  /// 同时写入 [TextTheme]（供 Material 组件）与 [WTextStyles] 扩展（供 [WText]）。
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: ThemeData(colorScheme: scheme).withWTextStyles(styles),
  /// )
  /// ```
  ThemeData withWTextStyles(WTextStyles styles) {
    // 用 Map.of 而不是显式 <Object, ThemeExtension<dynamic>>{}：
    // ThemeExtension<T extends ThemeExtension<T>> 的边界不允许把 dynamic 写进类型参数，
    // 显式写会被 CFE 推断成 ThemeExtension<ThemeExtension<dynamic>> 而报错。
    final next = Map.of(extensions)
      ..removeWhere((key, value) => value is WTextStyles)
      ..[WTextStyles] = styles;
    return copyWith(
      textTheme: styles.toTextTheme(textTheme),
      extensions: next.values,
    );
  }
}
