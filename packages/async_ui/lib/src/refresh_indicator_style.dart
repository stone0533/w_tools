import 'package:flutter/material.dart';

/// `WAsyncPagedList` 标准下拉刷新头的样式。
///
/// 只映射 Flutter [RefreshIndicator] 的样式参数；不包含自定义刷新头、
/// 完成 / 失败文案或下拉物理。需要这些能力时用 `WAsyncPagedSliver` +
/// 自己的滚动壳。
@immutable
class WAsyncRefreshIndicatorStyle {
  const WAsyncRefreshIndicatorStyle({
    this.color,
    this.backgroundColor,
    this.strokeWidth,
    this.displacement,
    this.edgeOffset,
    this.triggerMode,
  });

  /// 转圈颜色；null 时使用 Flutter 主题默认值。
  final Color? color;

  /// 刷新头背景色；null 时使用 Flutter 主题默认值。
  final Color? backgroundColor;

  /// 转圈线宽；null 时为 Flutter 默认值 2。
  final double? strokeWidth;

  /// 刷新头距顶部的位移；null 时为 Flutter 默认值 40。
  final double? displacement;

  /// 刷新头与滚动边缘的偏移；null 时为 Flutter 默认值 0。
  final double? edgeOffset;

  /// 触发刷新的模式；null 时为 [RefreshIndicatorTriggerMode.onEdge]。
  final RefreshIndicatorTriggerMode? triggerMode;
}
