import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/buttons/button.dart';

/// Widget 扩展，提供常用的布局辅助方法
extension WidgetExtension on Widget {
  /// 将 Widget 包装在 Expanded 中
  ///
  /// @param flex 弹性系数，默认为 1
  /// @return 包装在 Expanded 中的 Widget
  Widget expanded([int flex = 1]) {
    return Expanded(
      flex: flex,
      child: this,
    );
  }

  /// 添加底部安全空间（适配底部导航栏）
  ///
  /// @return 添加了底部安全空间的 Widget
  Widget withBottomSafeSpace() {
    return Padding(
      padding: EdgeInsets.only(bottom: ScreenUtil().bottomBarHeight),
      child: this,
    );
  }

  /// 添加自定义底部空间
  ///
  /// @param height 底部空间高度
  /// @return 添加了底部空间的 Widget
  Widget withBottomSpace(double height) {
    return Padding(
      padding: EdgeInsets.only(bottom: height),
      child: this,
    );
  }

  /// 添加顶部安全空间（适配状态栏）
  ///
  /// @return 添加了顶部安全空间的 Widget
  Widget withTopSafeSpace() {
    return Padding(
      padding: EdgeInsets.only(top: ScreenUtil().statusBarHeight),
      child: this,
    );
  }

  /// 添加水平 padding
  ///
  /// @param padding 水平方向的 padding 值
  /// @return 添加了水平 padding 的 Widget
  Widget withHorizontalPadding(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: this,
    );
  }

  /// 添加垂直 padding
  ///
  /// @param padding 垂直方向的 padding 值
  /// @return 添加了垂直 padding 的 Widget
  Widget withVerticalPadding(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: this,
    );
  }

  /// 添加左侧 padding
  ///
  /// @param padding 左侧 padding 值
  /// @return 添加了左侧 padding 的 Widget
  Widget withLeftPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(left: padding),
      child: this,
    );
  }

  /// 添加右侧 padding
  ///
  /// @param padding 右侧 padding 值
  /// @return 添加了右侧 padding 的 Widget
  Widget withRightPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(right: padding),
      child: this,
    );
  }

  /// 添加顶部 padding
  ///
  /// @param padding 顶部 padding 值
  /// @return 添加了顶部 padding 的 Widget
  Widget withTopPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding),
      child: this,
    );
  }

  /// 添加底部 padding
  ///
  /// @param padding 底部 padding 值
  /// @return 添加了底部 padding 的 Widget
  Widget withBottomPadding(double padding) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: this,
    );
  }

  /// 将 Widget 包装在 WButton 中
  ///
  /// @param onTap 点击回调
  /// @param onLongPress 长按回调
  /// @param config 按钮配置
  /// @return 包装在 WButton 中的 Widget
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
}
