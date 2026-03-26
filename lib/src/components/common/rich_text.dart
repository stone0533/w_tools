import 'package:flutter/material.dart';

/// 富文本组件，用于显示包含多种样式的文本
class WRichText extends StatelessWidget {
  /// 富文本配置
  final WRichTextConfig config;

  /// 数据源
  final List<String> data;

  /// 项目构建器
  final Object? Function(BuildContext, int, String, WRichTextConfig) itemBuilder;

  /// 构造函数
  ///
  /// @param key 组件键
  /// @param config 富文本配置
  /// @param data 数据源
  /// @param itemBuilder 项目构建器
  const WRichText({
    super.key,
    required this.config,
    required this.data,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: config.toTextStyle(),
        children: data.asMap().entries.map((entry) {
          int index = entry.key;
          String item = entry.value;
          Object? result = itemBuilder(context, index, item, config.copy());
          
          return _convertToInlineSpan(result, item, config);
        }).toList(),
      ),
      textAlign: config._textAlign ?? TextAlign.left,
      textDirection: config._textDirection,
      softWrap: config._softWrap ?? true,
      overflow: config._overflow ?? TextOverflow.clip,
      textScaler: config._textScaler ?? TextScaler.noScaling,
      maxLines: config._maxLines,
    );
  }
  
  /// 将结果转换为 InlineSpan
  InlineSpan _convertToInlineSpan(Object? result, String item, WRichTextConfig config) {
    if (result is InlineSpan) {
      return result;
    } else if (result is WRichTextConfig) {
      return TextSpan(text: item, style: result.toTextStyle());
    } else if (result is TextStyle) {
      return TextSpan(text: item, style: result);
    } else if (result is String) {
      return TextSpan(text: result, style: config.toTextStyle());
    } else {
      return TextSpan(text: item, style: config.toTextStyle());
    }
  }
}

/// 富文本配置类，用于配置富文本的样式
class WRichTextConfig {
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

  /// 文本溢出处理
  TextOverflow? _overflow;

  /// 文本装饰
  TextDecoration? _decoration;

  /// 文本装饰颜色
  Color? _decorationColor;

  /// 文本对齐方式
  TextAlign? _textAlign;

  /// 文本方向
  TextDirection? _textDirection;

  /// 是否软换行
  bool? _softWrap;

  /// 文本缩放器
  TextScaler? _textScaler;

  /// 最大行数
  int? _maxLines;

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

  /// 设置文本方向
  set textDirection(TextDirection? value) {
    _textDirection = value;
  }

  /// 设置是否软换行
  set softWrap(bool? value) {
    _softWrap = value;
  }

  /// 设置文本缩放器
  set textScaler(TextScaler? value) {
    _textScaler = value;
  }

  /// 设置最大行数
  set maxLines(int? value) {
    _maxLines = value;
  }

  /// 设置字体系列（别名）
  set family(String? fontFamily) {
    _fontFamily = fontFamily;
  }

  /// 设置字体系列为 NotoSansTC
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig familyNotoSansTC() {
    _fontFamily = 'NotoSansTC';
    return this;
  }

  /// 设置字体系列为 ZenMaruGothic
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig familyZenMaruGothic() {
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

  /// 设置文本溢出为省略号
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig overflowEllipsis() {
    _overflow = TextOverflow.ellipsis;
    return this;
  }

  /// 设置文本装饰为下划线
  ///
  /// @param decorationColor 下划线颜色，默认为文本颜色
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig decorationUnderline({Color? decorationColor}) {
    _decoration = TextDecoration.underline;
    _decorationColor = decorationColor ?? _color;
    return this;
  }

  /// 设置文本对齐方式为居中
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig textAlignCenter() {
    _textAlign = TextAlign.center;
    return this;
  }

  /// 设置文本对齐方式为左对齐
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig textAlignLeft() {
    _textAlign = TextAlign.left;
    return this;
  }

  /// 设置文本对齐方式为右对齐
  ///
  /// @return WRichTextConfig 实例，用于链式调用
  WRichTextConfig textAlignRight() {
    _textAlign = TextAlign.right;
    return this;
  }

  /// 构建 WRichText 组件
  ///
  /// @param data 数据源
  /// @param itemBuilder 项目构建器
  /// @return WRichText 实例
  WRichText build({
    required List<String> data,
    required Object? Function(BuildContext, int, String, WRichTextConfig) itemBuilder,
  }) {
    return WRichText(
      data: data,
      itemBuilder: itemBuilder,
      config: this,
    );
  }

  /// 创建当前配置的副本
  ///
  /// @return WRichTextConfig 实例的副本
  WRichTextConfig copy() {
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
  /// @param overflow 文本溢出处理
  /// @param decoration 文本装饰
  /// @param decorationColor 文本装饰颜色
  /// @param textAlign 文本对齐方式
  /// @param textDirection 文本方向
  /// @param softWrap 是否软换行
  /// @param textScaler 文本缩放器
  /// @param maxLines 最大行数
  /// @return WRichTextConfig 实例，包含更新后的配置
  WRichTextConfig copyWith({
    String? fontFamily,
    FontWeight? fontWeight,
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    TextOverflow? overflow,
    TextDecoration? decoration,
    Color? decorationColor,
    TextAlign? textAlign,
    TextDirection? textDirection,
    bool? softWrap,
    TextScaler? textScaler,
    int? maxLines,
  }) {
    final copy = WRichTextConfig();
    copy._fontFamily = fontFamily ?? _fontFamily;
    copy._fontWeight = fontWeight ?? _fontWeight;
    copy._fontSize = fontSize ?? _fontSize;
    copy._color = color ?? _color;
    copy._letterSpacing = letterSpacing ?? _letterSpacing;
    copy._height = height ?? _height;
    copy._overflow = overflow ?? _overflow;
    copy._decoration = decoration ?? _decoration;
    copy._decorationColor = decorationColor ?? _decorationColor;
    copy._textAlign = textAlign ?? _textAlign;
    copy._textDirection = textDirection ?? _textDirection;
    copy._softWrap = softWrap ?? _softWrap;
    copy._textScaler = textScaler ?? _textScaler;
    copy._maxLines = maxLines ?? _maxLines;
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
}