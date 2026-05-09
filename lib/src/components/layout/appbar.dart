import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/button.dart';
import '../common/text.dart';

/// 自定义导航栏组件
///
/// 提供可配置的导航栏，支持自定义返回回调、标题样式等。
///
/// **特性:**
/// - 原生 Navigator 导航（无第三方路由依赖）
/// - 支持自定义返回回调
/// - 双模式标题（文本/组件）
/// - 丰富的样式配置（背景色、渐变、高度等）
///
/// **使用示例:**
/// ```dart
/// // 基础用法
/// WAppBar(
///   title: '页面标题',
///   config: WAppBarConfig()..backIcon = Icon(Icons.arrow_back),
/// )
///
/// // 自定义返回逻辑
/// WAppBar(
///   title: '页面标题',
///   config: WAppBarConfig()
///     ..backIcon = Icon(Icons.arrow_back)
///     ..onBackPressed = () {
///       Navigator.pop(context);
///       // 额外的返回逻辑
///     },
/// )
/// ```
class WAppBar extends StatefulWidget {
  /// 导航栏配置
  final WAppBarConfig? config;

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
  const WAppBar({
    super.key,
    this.config,
    this.title,
    this.titleWidget,
    this.hideBackIcon,
    this.leading,
    this.actions,
  });

  @override
  State<WAppBar> createState() => _WAppBarState();
}

/// WAppBar 的状态类
class _WAppBarState extends State<WAppBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: ScreenUtil().statusBarHeight),
      decoration: BoxDecoration(
        color: widget.config?._color,
        gradient: widget.config?._gradient,
      ),
      child: Stack(
        children: [
          // 标题文本
          Container(
            height: widget.config?._height,
            alignment: Alignment.center,
            padding: widget.config?._titlePadding,
            child: widget.config?._titleTextConfig != null
                ? WText(
                    text: widget.title ?? '',
                    config: widget.config!._titleTextConfig,
                  )
                : Text(
                    widget.title ?? '',
                    style: widget.config?._titleStyle,
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
                              // 优先使用自定义返回回调，否则使用默认的 Navigator.pop
                              final onBackPressed = widget.config?._onBackPressed;
                              if (onBackPressed != null) {
                                onBackPressed();
                              } else {
                                Navigator.maybePop(context);
                              }
                            },
                            child: widget.config?._backIcon ?? Container(),
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
///
/// **配置参数:**
///
/// | 参数 | 类型 | 说明 |
/// |------|------|------|
/// | `color` | `Color?` | 背景颜色 |
/// | `titleStyle` | `TextStyle?` | 标题样式 |
/// | `height` | `double?` | 导航栏高度 |
/// | `titlePadding` | `EdgeInsetsGeometry?` | 标题内边距 |
/// | `backIcon` | `Widget?` | 返回图标 |
/// | `onBackPressed` | `VoidCallback?` | 返回按钮点击回调（默认 Navigator.maybePop） |
/// | `gradient` | `Gradient?` | 渐变背景 |
/// | `titleTextConfig` | `WTextConfig?` | 标题文本配置 |
class WAppBarConfig {
  Color? _color;
  TextStyle? _titleStyle;
  double? _height;
  EdgeInsetsGeometry? _titlePadding;
  Widget? _backIcon;
  Gradient? _gradient;
  WTextConfig? _titleTextConfig;
  
  /// 返回按钮点击回调
  VoidCallback? _onBackPressed;

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

  /// 设置标题文本配置
  set titleTextConfig(WTextConfig? value) {
    _titleTextConfig = value;
  }

  /// 设置返回按钮点击回调
  ///
  /// 如果不设置，默认使用 Navigator.maybePop(context)
  set onBackPressed(VoidCallback? value) {
    _onBackPressed = value;
  }

  /// 创建当前配置的副本
  ///
  /// @return WAppBarConfig 实例的副本
  WAppBarConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// @param color 导航栏背景颜色
  /// @param titleStyle 标题样式
  /// @param height 导航栏高度
  /// @param titlePadding 标题内边距
  /// @param backIcon 返回图标
  /// @param onBackPressed 返回按钮点击回调
  /// @param gradient 渐变背景
  /// @param titleTextConfig 标题文本配置
  /// @return WAppBarConfig 实例，包含更新后的配置
  WAppBarConfig copyWith({
    Color? color,
    TextStyle? titleStyle,
    double? height,
    EdgeInsetsGeometry? titlePadding,
    Widget? backIcon,
    VoidCallback? onBackPressed,
    Gradient? gradient,
    WTextConfig? titleTextConfig,
  }) {
    final copy = WAppBarConfig();
    copy._color = color ?? _color;
    copy._titleStyle = titleStyle ?? _titleStyle;
    copy._height = height ?? _height;
    copy._titlePadding = titlePadding ?? _titlePadding;
    copy._backIcon = backIcon ?? _backIcon;
    copy._onBackPressed = onBackPressed ?? _onBackPressed;
    copy._gradient = gradient ?? _gradient;
    copy._titleTextConfig = titleTextConfig ?? _titleTextConfig;
    return copy;
  }

  /// 构建导航栏组件
  WAppBar build({
    String? title,
    Widget? titleWidget,
    bool? hideBackIcon,
    Widget? leading,
    Widget? actions,
  }) {
    return WAppBar(
      config: this,
      title: title,
      titleWidget: titleWidget,
      hideBackIcon: hideBackIcon,
      leading: leading,
      actions: actions,
    );
  }
}
