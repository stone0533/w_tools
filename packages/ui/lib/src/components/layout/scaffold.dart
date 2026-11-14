import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

/// 项目页面脚手架。
///
/// - [WScaffold]：显式传 [appBar]（任意 [PreferredSizeWidget]），只负责 body / 槽位；
/// - [WScaffold.basic]：只传标题等参数，自动构建 [WAppBar]。
///
/// 两种入口分开，避免“传了 appBar 又传 title”的互斥分支。
class WScaffold extends StatelessWidget {
  /// 顶部栏；仅主构造器使用，与 [WScaffold.basic] 互斥。
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

  /// 默认顶部栏样式；仅 [WScaffold.basic] 使用。
  final WAppBarStyle? appBarStyle;

  /// 默认顶部栏的 bottom（如 TabBar）；仅 [WScaffold.basic] 使用。
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
  final bool includeTopSafeArea;
  final bool includeBottomSafeArea;

  /// 给 [bottomNavigationBar] 包一层 `SafeArea(top: false)`。
  ///
  /// `WNavBar` 已自带 `safeArea: true`，不要再开；底栏是普通 Widget（非 WNavBar）时
  /// 打开这个开关，避免压在 home indicator 上。
  final bool bottomNavigationBarSafeArea;
  final bool resizeToAvoidBottomInset;

  /// 是否由 [WScaffold.basic] 自动构建 WAppBar。
  final bool _basic;

  /// 显式顶部栏入口。
  const WScaffold({
    super.key,
    this.appBar,
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
    this.includeTopSafeArea = false,
    this.includeBottomSafeArea = true,
    this.bottomNavigationBarSafeArea = false,
    this.resizeToAvoidBottomInset = true,
  }) : title = null,
       titleWidget = null,
       leading = null,
       actions = const <Widget>[],
       onBack = null,
       automaticallyImplyLeading = true,
       centerTitle = true,
       appBarStyle = null,
       appBarBottom = null,
       _basic = false;

  /// 默认顶部栏入口：自动用 [WAppBar] 渲染 [title] / [titleWidget]。
  const WScaffold.basic({
    super.key,
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
    this.includeTopSafeArea = false,
    this.includeBottomSafeArea = true,
    this.bottomNavigationBarSafeArea = false,
    this.resizeToAvoidBottomInset = true,
  }) : appBar = null,
       _basic = true,
       assert(
         title != null || titleWidget != null,
         'WScaffold.basic: title 与 titleWidget 至少提供一个',
       ),
       assert(
         title == null || titleWidget == null,
         'WScaffold.basic: title 与 titleWidget 只能选一个',
       );

  @override
  Widget build(BuildContext context) {
    if (appBar case final WAppBar bar) {
      assert(
        bar.includeStatusBar,
        'WScaffold: 传 WAppBar 作为 appBar 时必须 includeStatusBar: true',
      );
    }

    final PreferredSizeWidget? appBarWidget;
    if (_basic) {
      // .basic 构造器已断言 title / titleWidget 至少一个，这里不再按文案是否为空
      // 二次判断，否则 title: '' 会静默丢掉整条顶栏（连返回按钮一起消失）。
      appBarWidget = WAppBar(
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
    } else {
      appBarWidget = appBar;
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
