import 'package:flutter/widgets.dart';

/// TextStyle 扩展类，提供从配置创建 TextStyle 的方法
extension WTextStyle on TextStyle {
  /// 从配置创建 TextStyle
  ///
  /// @param config 文本样式配置
  /// @return 创建的 TextStyle
  static TextStyle fromConfig({required WTextStyleConfig config}) {
    return config.build();
  }
}

/// 文本样式配置类，用于配置文本样式
class WTextStyleConfig {
  /// 字体系列
  String? _fontFamily;

  /// 字体粗细
  FontWeight? _fontWeight;

  /// 字体大小
  double? _fontSize;

  /// 文本颜色
  Color? _color;

  /// 字母间距
  double? _letterSpacing;

  /// 字间距
  double? _wordSpacing;

  /// 行高
  double? _height;

  /// 文本溢出处理
  TextOverflow? _overflow;

  /// 文本装饰
  TextDecoration? _decoration;

  /// 文本装饰颜色
  Color? _decorationColor;

  /// 文本装饰样式
  TextDecorationStyle? _decorationStyle;

  /// 缓存的 TextStyle
  TextStyle? _cachedTextStyle;

  /// 构建 TextStyle
  ///
  /// @return 构建的 TextStyle
  TextStyle build() {
    // 检查是否需要重新构建
    _cachedTextStyle ??= TextStyle(
      fontFamily: _fontFamily,
      fontWeight: _fontWeight,
      fontSize: _fontSize,
      color: _color,
      letterSpacing: _letterSpacing,
      wordSpacing: _wordSpacing,
      height: _height,
      overflow: _overflow,
      decoration: _decoration,
      decorationColor: _decorationColor,
      decorationStyle: _decorationStyle,
    );
    return _cachedTextStyle!;
  }

  /// 重置缓存，当配置更改时调用
  void _resetCache() {
    _cachedTextStyle = null;
  }

  /// 设置字体系列
  set fontFamily(String value) {
    _fontFamily = value;
    _resetCache();
  }

  /// 设置字体粗细
  set fontWeight(FontWeight value) {
    _fontWeight = value;
    _resetCache();
  }

  /// 设置字体大小
  set fontSize(double? value) {
    _fontSize = value;
    _resetCache();
  }

  /// 设置文本颜色
  set color(Color? value) {
    _color = value;
    _resetCache();
  }

  /// 设置字母间距
  set letterSpacing(double? value) {
    _letterSpacing = value;
    _resetCache();
  }

  /// 设置字间距
  set wordSpacing(double? value) {
    _wordSpacing = value;
    _resetCache();
  }

  /// 设置行高
  set height(double? value) {
    _height = value;
    _resetCache();
  }

  /// 设置文本溢出处理
  set overflow(TextOverflow? value) {
    _overflow = value;
    _resetCache();
  }

  /// 设置文本装饰
  set decoration(TextDecoration? value) {
    _decoration = value;
    _resetCache();
  }

  /// 设置文本装饰颜色
  set decorationColor(Color? value) {
    _decorationColor = value;
    _resetCache();
  }

  /// 设置文本装饰样式
  set decorationStyle(TextDecorationStyle? value) {
    _decorationStyle = value;
    _resetCache();
  }

  /// 设置字体系列（别名）
  set family(String fontFamily) {
    this.fontFamily = fontFamily;
  }

  /// 设置字体系列为 NotoSansTC
  ///
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig familyNotoSansTC() {
    fontFamily = 'NotoSansTC';
    return this;
  }

  /// 设置字体系列为 ZenMaruGothic
  ///
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig familyZenMaruGothic() {
    fontFamily = 'ZenMaruGothic';
    return this;
  }

  /// 设置字体粗细（通过数字值）
  ///
  /// @param fontWeight 字体粗细值（100-900）
  set weight(int fontWeight) {
    switch (fontWeight) {
      case 100:
        this.fontWeight = FontWeight.w100;
        break;
      case 200:
        this.fontWeight = FontWeight.w200;
        break;
      case 300:
        this.fontWeight = FontWeight.w300;
        break;
      case 400:
        this.fontWeight = FontWeight.w400;
        break;
      case 500:
        this.fontWeight = FontWeight.w500;
        break;
      case 600:
        this.fontWeight = FontWeight.w600;
        break;
      case 700:
        this.fontWeight = FontWeight.w700;
        break;
      case 800:
        this.fontWeight = FontWeight.w800;
        break;
      case 900:
        this.fontWeight = FontWeight.w900;
        break;
    }
  }

  /// 设置字体大小（别名）
  set size(double fontSize) {
    this.fontSize = fontSize;
  }

  /// 设置文本溢出为省略号
  ///
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig overflowEllipsis() {
    overflow = TextOverflow.ellipsis;
    return this;
  }

  /// 设置文本装饰为下划线
  ///
  /// @param decorationColor 下划线颜色，默认为文本颜色
  /// @param decorationStyle 下划线样式
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig decorationUnderline({
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    decoration = TextDecoration.underline;
    this.decorationColor = decorationColor ?? _color;
    this.decorationStyle = decorationStyle;
    return this;
  }

  /// 设置文本装饰为删除线
  ///
  /// @param decorationColor 删除线颜色，默认为文本颜色
  /// @param decorationStyle 删除线样式
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig decorationLineThrough({
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    decoration = TextDecoration.lineThrough;
    this.decorationColor = decorationColor ?? _color;
    this.decorationStyle = decorationStyle;
    return this;
  }

  /// 设置文本装饰为上划线
  ///
  /// @param decorationColor 上划线颜色，默认为文本颜色
  /// @param decorationStyle 上划线样式
  /// @return WTextStyleConfig 实例，用于链式调用
  WTextStyleConfig decorationOverline({
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    decoration = TextDecoration.overline;
    this.decorationColor = decorationColor ?? _color;
    this.decorationStyle = decorationStyle;
    return this;
  }

  /// 复制当前配置
  ///
  /// @return 新的 WTextStyleConfig 实例
  WTextStyleConfig copy() {
    final config = WTextStyleConfig();
    config._fontFamily = _fontFamily;
    config._fontWeight = _fontWeight;
    config._fontSize = _fontSize;
    config._color = _color;
    config._letterSpacing = _letterSpacing;
    config._wordSpacing = _wordSpacing;
    config._height = _height;
    config._overflow = _overflow;
    config._decoration = _decoration;
    config._decorationColor = _decorationColor;
    config._decorationStyle = _decorationStyle;
    return config;
  }
}
