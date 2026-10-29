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
}

/// 标准顶部导航栏。
///
/// 只提供 leading / title / actions / bottom 的标准布局；
/// 任意叠放请使用 [WTopBar]。
///
/// 本组件不处理状态栏高度，也不实现 PreferredSizeWidget；
/// 作为 Scaffold.appBar 使用时套 [WAppBarPreferred]。
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
  final WAppBarStyle style;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final leadingWidget = leading ?? _buildLeading(context, localizations);
    final middle = _buildTitle();
    final trailing =
        actions.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: actions);

    final foreground = style.foregroundColor;
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

  Widget? _buildLeading(
    BuildContext context,
    MaterialLocalizations localizations,
  ) {
    if (!automaticallyImplyLeading) return null;
    if (onBack != null) {
      return IconButton(
        tooltip: localizations.backButtonTooltip,
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      );
    }
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

/// 把 [WAppBar] 适配为 Scaffold.appBar 使用的 PreferredSizeWidget。
class WAppBarPreferred extends StatelessWidget implements PreferredSizeWidget {
  const WAppBarPreferred({super.key, required this.appBar});

  final WAppBar appBar;

  @override
  Size get preferredSize => Size.fromHeight(
        appBar.style.height + (appBar.bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) => appBar;
}

/// 完全自定义的顶部区域。
///
/// 只负责高度与背景，不提供 leading/title/actions 布局，
/// 也不实现 PreferredSizeWidget。
class WTopBar extends StatelessWidget {
  const WTopBar({
    super.key,
    required this.child,
    this.height = 56,
    this.backgroundColor,
    this.gradient,
    this.systemOverlayStyle,
  });

  final Widget child;
  final double height;
  final Color? backgroundColor;
  final Gradient? gradient;
  final SystemUiOverlayStyle? systemOverlayStyle;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
      ),
      child: child,
    );

    final overlay = systemOverlayStyle;
    return overlay == null
        ? content
        : AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: content,
          );
  }
}
