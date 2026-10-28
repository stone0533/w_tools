import 'package:flutter/material.dart';
import 'package:w_tools_ui/src/components/common/image/image_style.dart';
import 'package:w_tools_ui/src/components/common/image/image_types.dart';

/// 测试用可变样式构造器（生产 API 是不可变 WImageStyle）。
class TestImageStyle {
  double? width;
  double? height;
  BoxFit fit = BoxFit.cover;
  Alignment alignment = Alignment.center;
  int? memCacheWidth;
  int? memCacheHeight;
  double? aspectRatio;
  BorderRadius? borderRadius;
  BoxBorder? border;
  List<BoxShadow>? boxShadow;
  EdgeInsets? margin;
  EdgeInsets? padding;
  String? semanticLabel;
  bool excludeFromSemantics = false;
  bool gaplessPlayback = false;
  FilterQuality filterQuality = FilterQuality.low;
  int retryCount = 0;
  int retryDelay = 1000;
  Widget? Function(BuildContext, String)? placeholderBuilder;
  Widget? Function(BuildContext, String, WImageError)? errorWidgetBuilder;
  Widget? Function(BuildContext, String, WImageProgress)? progressBuilder;
  Widget? placeholder;
  Widget? errorWidget;

  TestImageStyle fitCover() {
    fit = BoxFit.cover;
    return this;
  }

  TestImageStyle fitContain() {
    fit = BoxFit.contain;
    return this;
  }

  TestImageStyle dimensions(double? w, double? h) {
    width = w;
    height = h;
    return this;
  }

  TestImageStyle circle(double radius) {
    width = radius * 2;
    height = radius * 2;
    borderRadius = BorderRadius.circular(radius);
    return this;
  }

  WImageStyle build() => WImageStyle(
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        aspectRatio: aspectRatio,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        margin: margin,
        padding: padding,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        gaplessPlayback: gaplessPlayback,
        filterQuality: filterQuality,
        retryCount: retryCount,
        retryDelay: retryDelay,
        placeholderBuilder: placeholderBuilder,
        errorWidgetBuilder: errorWidgetBuilder,
        progressBuilder: progressBuilder,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
}
