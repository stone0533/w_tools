import 'package:flutter/material.dart';

import '../utils/screen.dart';
import '../components/common/button.dart';
import '../components/layout/container.dart';

/// Widget 扩展（通用工具方法，不依赖 ui 组件）
extension WWidgetExtension on Widget {
  /// 将 Widget 包装在 Expanded 中
  Widget expanded([int flex = 1]) {
    return Expanded(
      flex: flex,
      child: this,
    );
  }

  /// 添加底部安全空间（适配底部导航栏）
  Widget withBottomSafeSpace() {
    return Padding(
      padding: EdgeInsets.only(bottom: WScreen.bottomBarHeight),
      child: this,
    );
  }

  /// 添加自定义底部空间
  Widget withBottomSpace(double height) {
    return Padding(
      padding: EdgeInsets.only(bottom: height),
      child: this,
    );
  }

  /// 添加顶部安全空间（适配状态栏）
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
}

/// Widget 扩展（依赖 ui 组件）
extension WUiWidgetExtension on Widget {
  /// 将 Widget 包装在 WButton 中
  Widget toButton({
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    WButtonConfig? config,
  }) {
    return WButton(
      onTap: onTap,
      onLongPress: onLongPress,
      config: config,
      child: this,
    );
  }

  /// 将 Widget 包装在 Container 中
  Widget withContainer(WContainerConfig config) {
    return config.build(child: this);
  }
}
