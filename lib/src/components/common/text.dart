import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  /// 设置字体粗细为 w100
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w100() {
    _fontWeight = FontWeight.w100;
    return this;
  }

  /// 设置字体粗细为 w200
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w200() {
    _fontWeight = FontWeight.w200;
    return this;
  }

  /// 设置字体粗细为 w300
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w300() {
    _fontWeight = FontWeight.w300;
    return this;
  }

  /// 设置字体粗细为 w400（常规）
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w400() {
    _fontWeight = FontWeight.w400;
    return this;
  }

  /// 设置字体粗细为 w500（中等）
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w500() {
    _fontWeight = FontWeight.w500;
    return this;
  }

  /// 设置字体粗细为 w600
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w600() {
    _fontWeight = FontWeight.w600;
    return this;
  }

  /// 设置字体粗细为 w700（加粗）
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w700() {
    _fontWeight = FontWeight.w700;
    return this;
  }

  /// 设置字体粗细为 w800
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w800() {
    _fontWeight = FontWeight.w800;
    return this;
  }

  /// 设置字体粗细为 w900
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig w900() {
    _fontWeight = FontWeight.w900;
    return this;
  }

  /// 设置字体大小为 12.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize12sp() {
    _fontSize = 12.sp;
    return this;
  }

  /// 设置字体大小为 14.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize14sp() {
    _fontSize = 14.sp;
    return this;
  }

  /// 设置字体大小为 16.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize16sp() {
    _fontSize = 16.sp;
    return this;
  }

  /// 设置字体大小为 18.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize18sp() {
    _fontSize = 18.sp;
    return this;
  }

  /// 设置字体大小为 20.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize20sp() {
    _fontSize = 20.sp;
    return this;
  }

  /// 设置字体大小为 24.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize24sp() {
    _fontSize = 24.sp;
    return this;
  }

  /// 设置字体大小为 26.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize26sp() {
    _fontSize = 26.sp;
    return this;
  }

  /// 设置字体大小为 28.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize28sp() {
    _fontSize = 28.sp;
    return this;
  }

  /// 设置字体大小为 30.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize30sp() {
    _fontSize = 30.sp;
    return this;
  }

  /// 设置字体大小为 32.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize32sp() {
    _fontSize = 32.sp;
    return this;
  }

  /// 设置字体大小为 34.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize34sp() {
    _fontSize = 34.sp;
    return this;
  }

  /// 设置字体大小为 36.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize36sp() {
    _fontSize = 36.sp;
    return this;
  }

  /// 设置字体大小为 38.sp
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig fontSize38sp() {
    _fontSize = 38.sp;
    return this;
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

  /// 设置文本溢出为裁剪
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig overflowClip() {
    _overflow = TextOverflow.clip;
    return this;
  }

  /// 设置文本溢出为淡出
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig overflowFade() {
    _overflow = TextOverflow.fade;
    return this;
  }

  /// 设置文本溢出为可见
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig overflowVisible() {
    _overflow = TextOverflow.visible;
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

  /// 设置文本装饰为上划线
  ///
  /// @param decorationColor 上划线颜色，默认为文本颜色
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig decorationOverline({Color? decorationColor}) {
    _decoration = TextDecoration.overline;
    _decorationColor = decorationColor ?? _color;
    return this;
  }

  /// 设置文本装饰为删除线
  ///
  /// @param decorationColor 删除线颜色，默认为文本颜色
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig decorationLineThrough({Color? decorationColor}) {
    _decoration = TextDecoration.lineThrough;
    _decorationColor = decorationColor ?? _color;
    return this;
  }

  /// 移除文本装饰
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig decorationNone() {
    _decoration = TextDecoration.none;
    _decorationColor = null;
    return this;
  }

  /// 设置文本对齐方式为居中
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignCenter() {
    _textAlign = TextAlign.center;
    return this;
  }

  /// 设置文本对齐方式为左对齐
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignLeft() {
    _textAlign = TextAlign.left;
    return this;
  }

  /// 设置文本对齐方式为右对齐
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignRight() {
    _textAlign = TextAlign.right;
    return this;
  }

  /// 设置文本对齐方式为两端对齐
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignJustify() {
    _textAlign = TextAlign.justify;
    return this;
  }

  /// 设置文本对齐方式为起始对齐
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignStart() {
    _textAlign = TextAlign.start;
    return this;
  }

  /// 设置文本对齐方式为结束对齐
  ///
  /// @return WTextConfig 实例，用于链式调用
  WTextConfig textAlignEnd() {
    _textAlign = TextAlign.end;
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
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param fontFamily 字体系列
  /// @param fontWeight 字体粗细
  /// @param fontSize 字体大小
  /// @param color 文本颜色
  /// @param letterSpacing 字母间距
  /// @param height 行高
  /// @param forceStrutHeight 是否强制使用行高
  /// @param overflow 文本溢出处理
  /// @param decoration 文本装饰
  /// @param decorationColor 文本装饰颜色
  /// @param textAlign 文本对齐方式
  /// @return WTextConfig 实例，包含更新后的配置
  WTextConfig copyWith({
    String? fontFamily,
    FontWeight? fontWeight,
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    bool? forceStrutHeight,
    TextOverflow? overflow,
    TextDecoration? decoration,
    Color? decorationColor,
    TextAlign? textAlign,
  }) {
    final copy = WTextConfig();
    copy._fontFamily = fontFamily ?? _fontFamily;
    copy._fontWeight = fontWeight ?? _fontWeight;
    copy._fontSize = fontSize ?? _fontSize;
    copy._color = color ?? _color;
    copy._letterSpacing = letterSpacing ?? _letterSpacing;
    copy._height = height ?? _height;
    copy._forceStrutHeight = forceStrutHeight ?? _forceStrutHeight;
    copy._overflow = overflow ?? _overflow;
    copy._decoration = decoration ?? _decoration;
    copy._decorationColor = decorationColor ?? _decorationColor;
    copy._textAlign = textAlign ?? _textAlign;
    return copy;
  }

  /// 将当前配置转换为 TextStyle
  ///
  /// @return TextStyle 实例，包含当前配置的所有样式属性
  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: _fontFamily,
      fontWeight: _fontWeight,
      fontSize: _fontSize,
      color: _color,
      letterSpacing: _letterSpacing,
      height: _height,
      overflow: _overflow,
      decoration: _decoration,
      decorationColor: _decorationColor,
    );
  }

  /// 将当前配置转换为 StrutStyle
  ///
  /// @return StrutStyle 实例，包含当前配置的 strut 样式属性
  StrutStyle toStrutStyle() {
    return StrutStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      height: _height,
      forceStrutHeight: _forceStrutHeight ?? true,
    );
  }

  /// 创建标题文本配置
  ///
  /// @return WTextConfig 实例，包含标题文本的默认样式
  static WTextConfig title() {
    return WTextConfig()
      ..fontSize = 24
      ..fontWeight = FontWeight.w700
      ..color = Colors.black;
  }

  /// 创建副标题文本配置
  ///
  /// @return WTextConfig 实例，包含副标题文本的默认样式
  static WTextConfig subtitle() {
    return WTextConfig()
      ..fontSize = 20
      ..fontWeight = FontWeight.w600
      ..color = Colors.black87;
  }

  /// 创建正文文本配置
  ///
  /// @return WTextConfig 实例，包含正文文本的默认样式
  static WTextConfig body() {
    return WTextConfig()
      ..fontSize = 16
      ..fontWeight = FontWeight.w400
      ..color = Colors.black87
      ..height = 1.5;
  }

  /// 创建小文本配置
  ///
  /// @return WTextConfig 实例，包含小文本的默认样式
  static WTextConfig small() {
    return WTextConfig()
      ..fontSize = 14
      ..fontWeight = FontWeight.w400
      ..color = Colors.black54;
  }

  /// 创建按钮文本配置
  ///
  /// @return WTextConfig 实例，包含按钮文本的默认样式
  static WTextConfig button() {
    return WTextConfig()
      ..fontSize = 16
      ..fontWeight = FontWeight.w500
      ..color = Colors.white;
  }

  /// 创建链接文本配置
  ///
  /// @return WTextConfig 实例，包含链接文本的默认样式
  static WTextConfig link() {
    return WTextConfig()
      ..fontSize = 16
      ..fontWeight = FontWeight.w400
      ..color = Colors.blue
      ..decoration = TextDecoration.underline;
  }
}
