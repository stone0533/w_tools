import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

/// 项目页面脚手架：默认顶部栏 + body + 常用 Scaffold 槽位。
///
/// 只传 `title` 时自动构建 [WAppBar]；特殊顶部栏用 [appBar] 覆盖。
/// 两种方式二选一：显式 [appBar] 时不要再传便捷参数；新代码推荐显式 `appBar: WAppBar(...)`。
class WScaffold extends StatelessWidget {
  /// 顶部栏覆盖；与 title/titleWidget/leading/actions/onBack 互斥。
  ///
  /// 可以是任意 [PreferredSizeWidget]（如 Material `AppBar` / `SliverAppBar`）；
  /// 传 [WAppBar] 时会校验其包含状态栏。
  final PreferredSizeWidget? appBar;

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
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomSheet;
  final List<Widget>? persistentFooterButtons;
  final bool extendBody;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemStatusBarStyle;
  final Widget? underlayWidget;
  final bool includeTopSafeArea;
  final bool includeBottomSafeArea;

  /// 给 [bottomNavigationBar] 包一层 `SafeArea(top: false)`。
  ///
  /// `WNavBar` 已自带 `safeArea: true`，不要再开；底栏是普通 Widget（非 WNavBar）时
  /// 打开这个开关，避免压在 home indicator 上。
  final bool bottomNavigationBarSafeArea;
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
    this.drawer,
    this.endDrawer,
    this.bottomSheet,
    this.persistentFooterButtons,
    this.extendBody = false,
    this.backgroundColor,
    this.systemStatusBarStyle,
    this.underlayWidget,
    this.includeTopSafeArea = false,
    this.includeBottomSafeArea = true,
    this.bottomNavigationBarSafeArea = false,
    this.resizeToAvoidBottomInset = true,
  }) : assert(
         title == null || titleWidget == null,
         'WScaffold: title 与 titleWidget 只能选一个',
       );

  bool get _needsDefaultAppBar =>
      (title?.isNotEmpty ?? false) ||
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
              appBarBottom == null &&
              automaticallyImplyLeading &&
              centerTitle),
      'WScaffold: 传了 appBar 时不要再传 title/leading/actions/onBack/appBarStyle/appBarBottom；'
      'WScaffold 自身的 leading/centerTitle 参数保持默认',
    );
    if (appBar case final WAppBar bar) {
      assert(
        bar.includeStatusBar,
        'WScaffold: 传 WAppBar 作为 appBar 时必须 includeStatusBar: true',
      );
    }

    final PreferredSizeWidget? appBarWidget;
    if (appBar != null) {
      appBarWidget = appBar;
    } else if (_needsDefaultAppBar) {
      final bar = WAppBar(
        title: title,
        titleWidget: titleWidget,
        leading: leading,
        actions: actions,
        bottom: appBarBottom,
        onBack: onBack,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        style: appBarStyle ?? const WAppBarStyle(),
      );
      appBarWidget = bar;
    } else {
      appBarWidget = null;
    }

    Widget? content = body;
    final padding = MediaQuery.paddingOf(context);

    if (content != null) {
      if (includeTopSafeArea && appBarWidget == null && padding.top > 0) {
        content = Padding(
          padding: EdgeInsets.only(top: padding.top),
          child: content,
        );
      }
      if (includeBottomSafeArea && bottomNavigationBar == null && padding.bottom > 0) {
        content = Padding(
          padding: EdgeInsets.only(bottom: padding.bottom),
          child: content,
        );
      }
    }

    if (underlayWidget != null) {
      final children = <Widget>[underlayWidget!];
      if (content != null) children.add(content);
      content = Stack(fit: StackFit.expand, children: children);
    }

    final bottomBar = bottomNavigationBar == null || !bottomNavigationBarSafeArea
        ? bottomNavigationBar
        : SafeArea(top: false, child: bottomNavigationBar!);

    final scaffold = Scaffold(
      appBar: appBarWidget,
      backgroundColor: backgroundColor,
      body: content,
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      persistentFooterButtons: persistentFooterButtons,
      extendBody: extendBody,
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
