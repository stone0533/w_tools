import 'package:flutter/material.dart';

import '../components/common/press_effect.dart';
import '../components/common/pressable.dart';

/// Widget 扩展（布局 / 安全区 / 装饰 / 点击糖）
extension WWidgetExtension on Widget {
  /// 将 Widget 包装在 Expanded 中
  Widget expanded([int flex = 1]) {
    return Expanded(
      flex: flex,
      child: this,
    );
  }

  /// 添加底部安全空间；读取最近的 [MediaQuery]（分屏 / 多窗口 / 测试可注入）。
  Widget withBottomSafeSpaceOf(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: this,
    );
  }

  /// 添加顶部安全空间；读取最近的 [MediaQuery]。
  Widget withTopSafeSpaceOf(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: this,
    );
  }

  /// 添加起始侧 padding（LTR 左、RTL 右）。
  Widget withStartPadding(double padding) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: padding),
      child: this,
    );
  }

  /// 添加结束侧 padding（LTR 右、RTL 左）。
  Widget withEndPadding(double padding) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: padding),
      child: this,
    );
  }

  /// 给任意 Widget 包一层装饰。
  ///
  /// 只负责绘制，不提供 padding / margin / 裁剪；
  /// 需要这些能力时用 Container。
  Widget withDecoration(BoxDecoration decoration) {
    return DecoratedBox(
      decoration: decoration,
      child: this,
    );
  }

  /// 将 Widget 包装在 IntrinsicHeight 中。
  Widget withIntrinsicHeight() {
    return IntrinsicHeight(child: this);
  }

  /// 给任意 Widget 添加点击能力（不声明 button 语义）。
  Widget toPressable({
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    bool enabled = true,
    WPressEffect effect = WPressEffect.opacity,
  }) {
    return WPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: enabled,
      effect: effect,
      child: this,
    );
  }
}
