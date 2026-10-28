import 'package:flutter/material.dart';

import 'image_config.dart';
import 'image_types.dart';

/// 不可变的图片样式。
///
/// 绿field 设计里 `WImage` 接收 [WImageStyle]；旧的可变 [WImageConfig]
/// 仍保留作为 builder 适配层，[WImageStyle.fromConfig] / [WImageStyle.toConfig]
/// 负责转换。
@immutable
class WImageStyle {
  /// 从可选配置创建（内部复制一份，之后修改原 config 不会影响 style）
  WImageStyle({WImageConfig? config}) : _config = (config ?? WImageConfig()).copy();

  /// 从旧配置创建
  WImageStyle.fromConfig(WImageConfig config) : _config = config.copy();

  final WImageConfig _config;

  double? get width => _config.width;
  double? get height => _config.height;
  BoxFit get fit => _config.fit;
  Alignment get alignment => _config.alignment;
  int? get memCacheWidth => _config.memCacheWidth;
  int? get memCacheHeight => _config.memCacheHeight;
  double? get aspectRatio => _config.aspectRatio;
  BorderRadius? get borderRadius => _config.borderRadius;
  BoxBorder? get border => _config.border;
  List<BoxShadow>? get boxShadow => _config.boxShadow;
  EdgeInsets? get margin => _config.margin;
  EdgeInsets? get padding => _config.padding;
  String? get semanticLabel => _config.semanticLabel;
  bool get excludeFromSemantics => _config.excludeFromSemantics;
  bool get gaplessPlayback => _config.gaplessPlayback;
  FilterQuality get filterQuality => _config.filterQuality;
  int get retryCount => _config.retryCount;
  int get retryDelay => _config.retryDelay;
  Widget? Function(BuildContext, String)? get placeholderBuilder => _config.placeholderBuilder;
  Widget? Function(BuildContext, String, WImageError)? get errorWidgetBuilder =>
      _config.errorWidgetBuilder;
  Widget? Function(BuildContext, String, WImageProgress)? get progressBuilder =>
      _config.progressBuilder;
  Widget? get placeholder => _config.placeholder;
  Widget? get errorWidget => _config.errorWidget;

  /// 校验（debug assert）
  void validate() => _config.validate();

  /// 转回旧配置（返回副本，修改它不会影响 style）
  WImageConfig toConfig() => _config.copy();

  static const Object _unset = Object();

  /// 复制并覆盖字段。
  ///
  /// nullable 字段支持显式传 `null` 清空；不传则保留原值。
  WImageStyle copyWith({
    Object? width = _unset,
    Object? height = _unset,
    Object? fit = _unset,
    Object? alignment = _unset,
    Object? memCacheWidth = _unset,
    Object? memCacheHeight = _unset,
    Object? aspectRatio = _unset,
    Object? borderRadius = _unset,
    Object? border = _unset,
    Object? boxShadow = _unset,
    Object? margin = _unset,
    Object? padding = _unset,
    Object? semanticLabel = _unset,
    Object? excludeFromSemantics = _unset,
    Object? gaplessPlayback = _unset,
    Object? filterQuality = _unset,
    Object? retryCount = _unset,
    Object? retryDelay = _unset,
    Object? placeholderBuilder = _unset,
    Object? errorWidgetBuilder = _unset,
    Object? progressBuilder = _unset,
    Object? placeholder = _unset,
    Object? errorWidget = _unset,
  }) {
    final c = _config.copy();
    if (!identical(width, _unset)) c.width = (width as num?)?.toDouble();
    if (!identical(height, _unset)) c.height = (height as num?)?.toDouble();
    if (!identical(fit, _unset)) c.fit = fit as BoxFit;
    if (!identical(alignment, _unset)) c.alignment = alignment as Alignment;
    if (!identical(memCacheWidth, _unset)) c.memCacheWidth = memCacheWidth as int?;
    if (!identical(memCacheHeight, _unset)) c.memCacheHeight = memCacheHeight as int?;
    if (!identical(aspectRatio, _unset)) c.aspectRatio = (aspectRatio as num?)?.toDouble();
    if (!identical(borderRadius, _unset)) c.borderRadius = borderRadius as BorderRadius?;
    if (!identical(border, _unset)) c.border = border as BoxBorder?;
    if (!identical(boxShadow, _unset)) c.boxShadow = boxShadow as List<BoxShadow>?;
    if (!identical(margin, _unset)) c.margin = margin as EdgeInsets?;
    if (!identical(padding, _unset)) c.padding = padding as EdgeInsets?;
    if (!identical(semanticLabel, _unset)) c.semanticLabel = semanticLabel as String?;
    if (!identical(excludeFromSemantics, _unset)) {
      c.excludeFromSemantics = excludeFromSemantics as bool;
    }
    if (!identical(gaplessPlayback, _unset)) c.gaplessPlayback = gaplessPlayback as bool;
    if (!identical(filterQuality, _unset)) c.filterQuality = filterQuality as FilterQuality;
    if (!identical(retryCount, _unset)) c.retryCount = retryCount as int;
    if (!identical(retryDelay, _unset)) c.retryDelay = retryDelay as int;
    if (!identical(placeholderBuilder, _unset)) {
      c.placeholderBuilder = placeholderBuilder as Widget? Function(BuildContext, String)?;
    }
    if (!identical(errorWidgetBuilder, _unset)) {
      c.errorWidgetBuilder =
          errorWidgetBuilder as Widget? Function(BuildContext, String, WImageError)?;
    }
    if (!identical(progressBuilder, _unset)) {
      c.progressBuilder =
          progressBuilder as Widget? Function(BuildContext, String, WImageProgress)?;
    }
    if (!identical(placeholder, _unset)) c.placeholder = placeholder as Widget?;
    if (!identical(errorWidget, _unset)) c.errorWidget = errorWidget as Widget?;
    return WImageStyle(config: c);
  }
}
