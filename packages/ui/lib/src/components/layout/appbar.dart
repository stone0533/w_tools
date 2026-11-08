import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text/w_text_styles.dart';
import 'appbar_style.dart';

export 'appbar_style.dart';

class WAppBar extends StatelessWidget implements PreferredSizeWidget {
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

  /// [PreferredSizeWidget] 约定：不含状态栏（Scaffold 会按 primary 补 top padding）。
  @override
  Size get preferredSize => Size.fromHeight(contentHeight);

  @override
  Widget build(BuildContext context) {
    style.validate();
    final leadingWidget = leading ?? _buildLeading(context);
    final middle = _buildTitle(context);
    final trailing = actions.isEmpty
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actions);

    final foreground = style.foregroundColor;
    final statusBarHeight = includeStatusBar ? MediaQuery.paddingOf(context).top : 0.0;
    Widget toolbar = SizedBox(
      height: style.height,
      // merge 而不是替换：替换会丢掉 ThemeData.iconTheme / 上层 IconTheme，
      // 默认（foreground 为空）时图标会回落到 Flutter fallback 的黑色。
      child: IconTheme.merge(
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

  Widget? _buildTitle(BuildContext context) {
    final titleWidget = this.titleWidget;
    if (titleWidget != null) return titleWidget;

    final title = this.title;
    if (title == null || title.isEmpty) return null;

    // 与 Material AppBar 对齐：显式 style > AppBarTheme > 主题 titleLarge。
    // 都没有时不传 style，交给 Text 的默认样式。
    final theme = Theme.of(context);
    final baseStyle =
        style.titleStyle ?? theme.appBarTheme.titleTextStyle ?? WTextStyles.of(context).title;
    final foreground = style.foregroundColor;
    final titleStyle = foreground == null ? baseStyle : baseStyle.copyWith(color: foreground);

    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
  }
}
