import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../extensions/widget.dart';
import 'appbar.dart';

/// 项目页面脚手架：默认顶部栏 + body + 常用 Scaffold 槽位。
///
/// 只传 `title` 时自动构建 [WAppBar]；特殊顶部栏用 [appBar] 覆盖。
class WScaffold extends StatelessWidget {
  /// 顶部栏覆盖；与 title/titleWidget/leading/actions/onBack 互斥。
  final WAppBar? appBar;

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  /// 默认顶部栏样式；仅在自动构建 WAppBar 时生效。
  final WAppBarStyle? appBarStyle;

  /// 默认顶部栏的 bottom（如 TabBar）。
  final PreferredSizeWidget? appBarBottom;

  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemStatusBarStyle;
  final Widget? underlayWidget;
  final bool includeTopSafeArea;
  final bool includeBottomSafeArea;
  final bool resizeToAvoidBottomInset;

  const WScaffold({
    super.key,
    this.appBar,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions = const <Widget>[],
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.appBarStyle,
    this.appBarBottom,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.systemStatusBarStyle,
    this.underlayWidget,
    this.includeTopSafeArea = false,
    this.includeBottomSafeArea = true,
    this.resizeToAvoidBottomInset = true,
  }) : assert(
          title == null || titleWidget == null,
          'WScaffold: title 与 titleWidget 只能选一个',
        );

  bool get _needsDefaultAppBar =>
      title != null ||
      titleWidget != null ||
      leading != null ||
      actions.isNotEmpty ||
      onBack != null ||
      appBarBottom != null;

  @override
  Widget build(BuildContext context) {
    assert(
      appBar == null ||
          (title == null &&
              titleWidget == null &&
              leading == null &&
              actions.isEmpty &&
              onBack == null &&
              appBarStyle == null &&
              appBarBottom == null),
      'WScaffold: 传了 appBar 时不要再传 title/leading/actions/onBack/appBarStyle/appBarBottom',
    );
    final bar = appBar ??
        (_needsDefaultAppBar
            ? WAppBar(
                title: title,
                titleWidget: titleWidget,
                leading: leading,
                actions: actions,
                bottom: appBarBottom,
                onBack: onBack,
                automaticallyImplyLeading: automaticallyImplyLeading,
                centerTitle: centerTitle,
                style: appBarStyle ?? const WAppBarStyle(),
              )
            : null);

    final appBarWidget = bar == null
        ? null
        : PreferredSize(
            preferredSize: Size.fromHeight(bar.contentHeight),
            child: bar,
          );

    Widget? content = body;

    if (content != null) {
      if (includeTopSafeArea && appBarWidget == null) {
        content = content.withTopSafeSpace();
      }
      if (includeBottomSafeArea && bottomNavigationBar == null) {
        content = content.withBottomSafeSpace();
      }
    }

    if (underlayWidget != null) {
      final children = <Widget>[underlayWidget!];
      if (content != null) children.add(content);
      content = Stack(fit: StackFit.expand, children: children);
    }

    final scaffold = Scaffold(
      appBar: appBarWidget,
      backgroundColor: backgroundColor,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );

    return systemStatusBarStyle == null
        ? scaffold
        : AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemStatusBarStyle!,
            child: scaffold,
          );
  }
}
