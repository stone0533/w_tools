import 'package:flutter/material.dart';

/// 文本组件，用于显示和配置文本样式
class WText extends StatelessWidget {
  /// 文本配置
  final WTextConfig? config;

  /// 文本内容
  final String text;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 文本配置
  /// @param text 文本内容
  const WText({
    super.key,
    required this.text,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: config?._fontFamily,
        fontWeight: config?._fontWeight,
        fontSize: config?._fontSize,
        color: config?._color,
        letterSpacing: config?._letterSpacing,
        height: config?._height,
        overflow: config?._overflow,
        decoration: config?._decoration,
        decorationColor: config?._decorationColor,
      ),
      strutStyle: StrutStyle(
        fontFamily: config?._fontFamily,
        fontSize: config?._fontSize,
        height: config?._height,
        forceStrutHeight: config?._forceStrutHeight ?? true,
      ),
      textAlign: config?._textAlign,
    );
  }
}

/// 文本配置类，用于配置文本的样式
class WTextConfig {
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

  /// 行高
  double? _height;

  /// 是否强制使用行高
  bool? _forceStrutHeight;

  /// 文本溢出处理
  TextOverflow? _overflow;

  /// 文本装饰
  TextDecoration? _decoration;

  /// 文本装饰颜色
  Color? _decorationColor;

  /// 文本对齐方式
  TextAlign? _textAlign;

  /// 设置字体系列
  set fontFamily(String? value) {
    _fontFamily = value;
  }

  /// 设置字体粗细
  set fontWeight(FontWeight? value) {
    _fontWeight = value;
  }

  /// 设置字体大小
  set fontSize(double? value) {
    _fontSize = value;
  }

  /// 设置文本颜色
  set color(Color? value) {
    _color = value;
  }

  /// 设置字母间距
  set letterSpacing(double? value) {
    _letterSpacing = value;
  }

  /// 设置行高
  set height(double? value) {
    _height = value;
  }

  /// 设置是否强制使用行高
  set forceStrutHeight(bool? value) {
    _forceStrutHeight = value;
  }

  /// 设置文本溢出处理
  set overflow(TextOverflow? value) {
    _overflow = value;
  }

  /// 设置文本装饰
  set decoration(TextDecoration? value) {
    _decoration = value;
  }

  /// 设置文本装饰颜色
  set decorationColor(Color? value) {
    _decorationColor = value;
  }

  /// 设置文本对齐方式
  set textAlign(TextAlign? value) {
    _textAlign = value;
  }

  /// 设置字体系列（别名）
  set family(String? fontFamily) {
    _fontFamily = fontFamily;
  }

  /// 设置字体系列为 NotoSansTC
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig familyNotoSansTC() {
    _fontFamily = 'NotoSansTC';
    return this;
  }

  /// 设置字体系列为 ZenMaruGothic
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig familyZenMaruGothic() {
    _fontFamily = 'ZenMaruGothic';
    return this;
  }

  /// 设置字体粗细（通过数字值）
  ///
  /// @param fontWeight 字体粗细值（100-900）
  set weight(int? fontWeight) {
    switch (fontWeight) {
      case 100:
        _fontWeight = FontWeight.w100;
        break;
      case 200:
        _fontWeight = FontWeight.w200;
        break;
      case 300:
        _fontWeight = FontWeight.w300;
        break;
      case 400:
        _fontWeight = FontWeight.w400;
        break;
      case 500:
        _fontWeight = FontWeight.w500;
        break;
      case 600:
        _fontWeight = FontWeight.w600;
        break;
      case 700:
        _fontWeight = FontWeight.w700;
        break;
      case 800:
        _fontWeight = FontWeight.w800;
        break;
      case 900:
        _fontWeight = FontWeight.w900;
        break;
    }
  }

  /// 设置不强制使用行高
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig forceStrutHeightFalse() {
    _forceStrutHeight = false;
    return this;
  }

  /// 设置文本溢出为省略号
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig overflowEllipsis() {
    _overflow = TextOverflow.ellipsis;
    return this;
  }

  /// 设置文本装饰为下划线
  ///
  /// @param decorationColor 下划线颜色，默认为文本颜色
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig decorationUnderline({Color? decorationColor}) {
    _decoration = TextDecoration.underline;
    _decorationColor = decorationColor ?? _color;
    return this;
  }

  /// 设置文本对齐方式为居中
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignCenter() {
    _textAlign = TextAlign.center;
    return this;
  }

  /// 构建 WText 组件
  ///
  /// @param text 文本内容
  /// @return WText 实例
  WText build(String text) {
    return WText(
      text: text,
      config: this,
    );
  }

  /// 创建当前配置的副本
  ///
  /// @return WTextConfig 实例的副本
  WTextConfig copy() {
    final copy = WTextConfig();
    copy._fontFamily = _fontFamily;
    copy._fontWeight = _fontWeight;
    copy._fontSize = _fontSize;
    copy._color = _color;
    copy._letterSpacing = _letterSpacing;
    copy._height = _height;
    copy._forceStrutHeight = _forceStrutHeight;
    copy._overflow = _overflow;
    copy._decoration = _decoration;
    copy._decorationColor = _decorationColor;
    copy._textAlign = _textAlign;
    return copy;
  }
}
