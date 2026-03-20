import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../buttons/button.dart';

/// 自定义导航栏组件
class WAppbar extends StatefulWidget {
  /// 导航栏配置
  final WAppbarConfig config;

  /// 标题文本
  final String? title;

  /// 标题组件
  final Widget? titleWidget;

  /// 是否隐藏返回图标
  final bool? hideBackIcon;

  /// 左侧组件
  final Widget? leading;

  /// 右侧操作组件
  final Widget? actions;

  /// 创建导航栏
  const WAppbar({
    super.key,
    required this.config,
    this.title,
    this.titleWidget,
    this.hideBackIcon,
    this.leading,
    this.actions,
  });

  @override
  State<WAppbar> createState() => _WAppbarState();
}

/// WAppbar 的状态类
class _WAppbarState extends State<WAppbar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: ScreenUtil().statusBarHeight),
      decoration: BoxDecoration(color: widget.config._color, gradient: widget.config._gradient),
      child: Stack(
        children: [
          // 标题文本
          Container(
            height: widget.config._height,
            alignment: Alignment.center,
            padding: widget.config._titlePadding,
            child: Text(
              widget.title ?? '',
              style: widget.config._titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 标题组件
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: widget.titleWidget,
            ),
          ),
          // 左侧组件/返回按钮和右侧操作按钮
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.leading ??
                    (widget.hideBackIcon == true
                        ? Container()
                        : WButton(
                            onTap: () {
                              Get.back();
                            },
                            child: widget.config._backIcon ?? Container(),
                          )),
                widget.actions ?? Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 导航栏配置类
class WAppbarConfig {
  Color? _color;
  TextStyle? _titleStyle;
  double? _height;
  EdgeInsetsGeometry? _titlePadding;
  Widget? _backIcon;
  Gradient? _gradient;

  /// 设置导航栏背景颜色
  set color(Color? value) {
    _color = value;
  }

  /// 设置标题样式
  set titleStyle(TextStyle? value) {
    _titleStyle = value;
  }

  /// 设置导航栏高度
  set height(double? value) {
    _height = value;
  }

  /// 设置标题内边距
  set titlePadding(EdgeInsetsGeometry? value) {
    _titlePadding = value;
  }

  /// 设置返回图标
  set backIcon(Widget? value) {
    _backIcon = value;
  }

  /// 设置渐变背景
  set gradient(Gradient? value) {
    _gradient = value;
  }

  /// 构建导航栏组件
  WAppbar build({
    String? title,
    Widget? titleWidget,
    bool? hideBackIcon,
    Widget? leading,
    Widget? actions,
  }) {
    return WAppbar(
      config: this,
      title: title,
      titleWidget: titleWidget,
      hideBackIcon: hideBackIcon,
      leading: leading,
      actions: actions,
    );
  }
}
