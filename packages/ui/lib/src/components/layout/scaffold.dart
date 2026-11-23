import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

/// 项目页面脚手架。
///
/// 只负责显式 [appBar] 与 body / 槽位；默认顶栏用
/// `WScaffold(appBar: WAppBar(title: ...), body: ...)`。
class WScaffold extends StatelessWidget {
  /// 顶部栏。
  ///
  /// 可以是任意 [PreferredSizeWidget]（如 Material `AppBar` / `SliverAppBar`）；
  /// 传 [WAppBar] 时会校验其包含状态栏。
  final PreferredSizeWidget? appBar;

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

  /// 没有 [appBar] 时，是否给 body 顶部补状态栏高度（`MediaQuery.padding.top`）。
  ///
  /// 默认 `false`：有 appBar 时不重复加；没有 appBar 又需要避开状态栏时显式传 `true`。
  final bool includeTopSafeArea;

  /// 没有 [bottomNavigationBar] 时，是否给 body 底部补 home indicator 高度。
  ///
  /// 默认 `true`；底栏存在时由底栏自己处理底部 inset。
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
  });

  @override
  Widget build(BuildContext context) {
    if (appBar case final WAppBar bar) {
      assert(
        bar.includeStatusBar,
        'WScaffold: 传 WAppBar 作为 appBar 时必须 includeStatusBar: true',
      );
    }

    Widget? content = body;
    final padding = MediaQuery.paddingOf(context);

    if (content != null) {
      if (includeTopSafeArea && appBar == null && padding.top > 0) {
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
      appBar: appBar,
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
