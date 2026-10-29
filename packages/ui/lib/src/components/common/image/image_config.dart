import 'package:flutter/material.dart';

import 'image_types.dart';

/// 不可变的图片加载配置。
///
/// 负责解码尺寸、重试、占位/错误/进度 UI 与 gaplessPlayback；
/// 视觉样式由 [WImageStyle] 负责。
@immutable
class WImageConfig {
  const WImageConfig({
    this.memCacheWidth,
    this.memCacheHeight,
    this.gaplessPlayback = false,
    this.retryCount = 0,
    this.retryDelay = 1000,
    this.placeholderBuilder,
    this.errorWidgetBuilder,
    this.progressBuilder,
    this.placeholder,
    this.errorWidget,
    this.showRetryButton = false,
    this.retryLabel = '重试',
  });

  /// 解码尺寸上限（物理像素）
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// 换图时保留上一帧
  final bool gaplessPlayback;

  /// 网络自动重试次数
  final int retryCount;

  /// 重试基础间隔（毫秒）
  final int retryDelay;

  final Widget? Function(BuildContext, String)? placeholderBuilder;
  final Widget? Function(BuildContext, String, WImageError)? errorWidgetBuilder;
  final Widget? Function(BuildContext, String, WImageProgress)? progressBuilder;

  /// 固定占位符（与 builder 二选一）
  final Widget? placeholder;

  /// 固定错误占位（与 builder 二选一）
  final Widget? errorWidget;

  /// 没有自定义错误占位时，是否显示内置的“错误 + 重试”视图
  final bool showRetryButton;

  /// 内置重试按钮文案
  final String retryLabel;

  void validate() {
    assert(retryCount >= 0, 'retryCount 不能为负');
    assert(retryDelay >= 0, 'retryDelay 不能为负');
    assert(memCacheWidth == null || memCacheWidth! > 0, 'memCacheWidth 必须大于 0');
    assert(memCacheHeight == null || memCacheHeight! > 0, 'memCacheHeight 必须大于 0');
    assert(
      !(placeholder != null && placeholderBuilder != null),
      'placeholder 与 placeholderBuilder 只能选一个（builder 优先）',
    );
    assert(
      !(errorWidget != null && errorWidgetBuilder != null),
      'errorWidget 与 errorWidgetBuilder 只能选一个（builder 优先）',
    );
  }

  static const Object _unset = Object();

  WImageConfig copyWith({
    Object? memCacheWidth = _unset,
    Object? memCacheHeight = _unset,
    bool? gaplessPlayback,
    int? retryCount,
    int? retryDelay,
    Object? placeholderBuilder = _unset,
    Object? errorWidgetBuilder = _unset,
    Object? progressBuilder = _unset,
    Object? placeholder = _unset,
    Object? errorWidget = _unset,
    bool? showRetryButton,
    String? retryLabel,
  }) {
    return WImageConfig(
      memCacheWidth: identical(memCacheWidth, _unset) ? this.memCacheWidth : memCacheWidth as int?,
      memCacheHeight:
          identical(memCacheHeight, _unset) ? this.memCacheHeight : memCacheHeight as int?,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      placeholderBuilder: identical(placeholderBuilder, _unset)
          ? this.placeholderBuilder
          : placeholderBuilder as Widget? Function(BuildContext, String)?,
      errorWidgetBuilder: identical(errorWidgetBuilder, _unset)
          ? this.errorWidgetBuilder
          : errorWidgetBuilder as Widget? Function(BuildContext, String, WImageError)?,
      progressBuilder: identical(progressBuilder, _unset)
          ? this.progressBuilder
          : progressBuilder as Widget? Function(BuildContext, String, WImageProgress)?,
      placeholder: identical(placeholder, _unset) ? this.placeholder : placeholder as Widget?,
      errorWidget: identical(errorWidget, _unset) ? this.errorWidget : errorWidget as Widget?,
      showRetryButton: showRetryButton ?? this.showRetryButton,
      retryLabel: retryLabel ?? this.retryLabel,
    );
  }
}
