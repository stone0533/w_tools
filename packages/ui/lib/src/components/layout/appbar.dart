import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 标准顶部栏样式。
@immutable
class WAppBarStyle {
  const WAppBarStyle({
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.titleStyle,
    this.height = 56,
    this.titleSpacing,
    this.systemOverlayStyle,
  });

  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? foregroundColor;
  final TextStyle? titleStyle;
  final double height;
  final double? titleSpacing;
  final SystemUiOverlayStyle? systemOverlayStyle;

  static const Object _unset = Object();

  WAppBarStyle copyWith({
    Object? backgroundColor = _unset,
    Object? gradient = _unset,
    Object? foregroundColor = _unset,
    Object? titleStyle = _unset,
    double? height,
    Object? titleSpacing = _unset,
    Object? systemOverlayStyle = _unset,
  }) {
    return WAppBarStyle(
      backgroundColor:
          identical(backgroundColor, _unset) ? this.backgroundColor : backgroundColor as Color?,
      gradient: identical(gradient, _unset) ? this.gradient : gradient as Gradient?,
      foregroundColor:
          identical(foregroundColor, _unset) ? this.foregroundColor : foregroundColor as Color?,
      titleStyle: identical(titleStyle, _unset) ? this.titleStyle : titleStyle as TextStyle?,
      height: height ?? this.height,
      titleSpacing: identical(titleSpacing, _unset) ? this.titleSpacing : titleSpacing as double?,
      systemOverlayStyle: identical(systemOverlayStyle, _unset)
          ? this.systemOverlayStyle
          : systemOverlayStyle as SystemUiOverlayStyle?,
    );
  }

  void validate() {
    assert(height >= 0 && height.isFinite, 'WAppBarStyle.height 非法');
    assert(
      titleSpacing == null || (titleSpacing!.isFinite && titleSpacing! >= 0),
      'WAppBarStyle.titleSpacing 必须非负',
    );
    assert(
      !(backgroundColor != null && gradient != null),
      'WAppBarStyle.backgroundColor 与 gradient 只能选一个',
    );
  }
}

/// 标准顶部导航栏。
///
/// 只提供 leading / title / actions / bottom 的标准布局；
/// 任意叠放请在页面层自己用 Container/Stack。
///
/// 默认包含状态栏背景；嵌套在 SafeArea 中时可传 `includeStatusBar: false`。
class WAppBar extends StatelessWidget {
  const WAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.includeStatusBar = true,
    this.style = const WAppBarStyle(),
  }) : assert(
          title == null || titleWidget == null,
          'WAppBar: title 与 titleWidget 只能选一个',
        );

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final bool includeStatusBar;
  final WAppBarStyle style;

  /// toolbar + bottom 的高度，不含状态栏。
  double get contentHeight => style.height + (bottom?.preferredSize.height ?? 0);

  @override
  Widget build(BuildContext context) {
    style.validate();
    final leadingWidget = leading ?? _buildLeading(context);
    final middle = _buildTitle();
    final trailing =
        actions.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: actions);

    final foreground = style.foregroundColor;
    final statusBarHeight = includeStatusBar ? MediaQuery.paddingOf(context).top : 0.0;
    Widget toolbar = SizedBox(
      height: style.height,
      child: IconTheme(
        data: foreground == null ? const IconThemeData() : IconThemeData(color: foreground),
        child: NavigationToolbar(
          leading: leadingWidget,
          middle: middle,
          trailing: trailing,
          centerMiddle: centerTitle,
          middleSpacing: style.titleSpacing ?? NavigationToolbar.kMiddleSpacing,
        ),
      ),
    );

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        toolbar,
        if (bottom != null) bottom!,
      ],
    );

    content = Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(
        color: style.gradient == null ? style.backgroundColor : null,
        gradient: style.gradient,
      ),
      child: content,
    );

    final overlay = style.systemOverlayStyle;
    return overlay == null
        ? content
        : AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: content,
          );
  }

  Widget? _buildLeading(BuildContext context) {
    // 显式 onBack 优先；automaticallyImplyLeading 只控制默认返回。
    if (onBack != null) return BackButton(onPressed: onBack);
    if (!automaticallyImplyLeading) return null;
    if (!Navigator.canPop(context)) return null;
    return const BackButton();
  }

  Widget? _buildTitle() {
    final titleWidget = this.titleWidget;
    if (titleWidget != null) return titleWidget;

    final title = this.title;
    if (title == null || title.isEmpty) return null;

    final foreground = style.foregroundColor;
    final titleStyle = foreground == null
        ? style.titleStyle
        : (style.titleStyle ?? const TextStyle()).copyWith(color: foreground);

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
  }
}
