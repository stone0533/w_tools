import 'package:flutter/material.dart';

import '../../utils/screen.dart';
import '../common/button.dart';
import '../common/text.dart';

/// 自定义导航栏组件
///
/// 提供可配置的导航栏，支持自定义返回回调、标题样式等。
///
/// **特性:**
/// - 原生 Navigator 导航（无第三方路由依赖）
/// - 支持自定义返回回调
/// - 标题支持三种优先级：组件（titleWidget）> 文本样式（titleTextConfig）> 纯文本（title）
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
  Widget build(BuildContext context) {
    // 标题优先级：titleWidget > titleTextConfig > title
    final Widget titleWidget = widget.titleWidget != null
        ? widget.titleWidget!
        : (widget.config?._titleTextConfig != null
            ? WText(
                text: widget.title ?? '',
                config: widget.config!._titleTextConfig,
              )
            : Text(
                widget.title ?? '',
                style: widget.config?._titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ));

    return Container(
      padding: EdgeInsets.only(top: WScreen.statusBarHeight),
      decoration: BoxDecoration(
        color: widget.config?._color,
        gradient: widget.config?._gradient,
      ),
      child: Stack(
        children: [
          // 标题（始终只渲染一个）
          Container(
            height: widget.config?._height,
            alignment: Alignment.center,
            padding: widget.config?._titlePadding,
            child: titleWidget,
          ),
          // 左侧组件/返回按钮和右侧操作按钮
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.leading ??
                    (widget.hideBackIcon == true
                        ? Container()
                        : Semantics(
                            button: true,
                            label: MaterialLocalizations.of(context).backButtonTooltip,
                            child: WButton(
                              onTap: () {
                                // 优先使用自定义返回回调，否则使用默认的 Navigator.pop
                                final onBackPressed = widget.config?._onBackPressed;
                                if (onBackPressed != null) {
                                  onBackPressed();
                                } else {
                                  Navigator.maybePop(context);
                                }
                              },
                              child: widget.config?._backIcon ?? const Icon(Icons.arrow_back),
                            ),
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
/// | `backIcon` | `Widget?` | 返回图标（未配置时使用 `Icons.arrow_back`） |
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
  /// 返回：WAppBarConfig 实例的副本
  WAppBarConfig copy() {
    return copyWith();
  }

  /// 创建当前配置的副本，并可以选择性地更新某些属性
  ///
  /// - [color]：导航栏背景颜色
  /// - [titleStyle]：标题样式
  /// - [height]：导航栏高度
  /// - [titlePadding]：标题内边距
  /// - [backIcon]：返回图标
  /// - [onBackPressed]：返回按钮点击回调
  /// - [gradient]：渐变背景
  /// - [titleTextConfig]：标题文本配置
  /// 返回：WAppBarConfig 实例，包含更新后的配置
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
