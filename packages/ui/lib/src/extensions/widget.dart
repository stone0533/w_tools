import 'package:flutter/material.dart';

import '../utils/screen.dart';
import '../components/common/pressable.dart';

/// Widget 扩展（通用工具方法，不依赖 ui 组件）
extension WWidgetExtension on Widget {
  /// 将 Widget 包装在 Expanded 中
  Widget expanded([int flex = 1]) {
    return Expanded(
      flex: flex,
      child: this,
    );
  }

  /// 添加底部安全空间（适配底部导航栏）。
  ///
  /// 读取 [WScreen.bottomBarHeight]，不读取当前 [MediaQuery]。
  Widget withBottomSafeSpace() {
    return Padding(
      padding: EdgeInsets.only(bottom: WScreen.bottomBarHeight),
      child: this,
    );
  }

  /// 添加自定义底部空间。
  @Deprecated('Use withBottomPadding instead')
  Widget withBottomSpace(double height) => withBottomPadding(height);

  /// 添加顶部安全空间（适配状态栏）。
  ///
  /// 读取 [WScreen.statusBarHeight]，不读取当前 [MediaQuery]。
  Widget withTopSafeSpace() {
    return Padding(
      padding: EdgeInsets.only(top: WScreen.statusBarHeight),
      child: this,
    );
  }

  /// 添加水平 padding
  Widget withHorizontalPadding(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: this,
    );
  }

  /// 添加垂直 padding
  Widget withVerticalPadding(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: this,
    );
  }

  /// 添加左侧 padding
  Widget withLeftPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding),
      child: this,
    );
  }

  /// 添加右侧 padding
  Widget withRightPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: this,
    );
  }

  /// 添加顶部 padding
  Widget withTopPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: this,
    );
  }

  /// 添加底部 padding
  Widget withBottomPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
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
}

/// Widget 扩展（依赖 ui 组件）
extension WUiWidgetExtension on Widget {
  /// 给任意 Widget 添加点击能力（不声明 button 语义）
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
