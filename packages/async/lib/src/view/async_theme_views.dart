import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'async_error_banner.dart';
import 'async_error_view.dart';
import 'async_strings.dart';
import 'async_theme.dart';

/// 四态视图的统一解析入口：显式 builder > [WAsyncTheme] > 包内默认。
///
/// [WAsyncView] / [WAsyncStateSliver] 内部都走这里，保证两条渲染路径的默认值
/// 不会各自漂移。本类不从 barrel 导出；需要完全自定义布局时直接写
/// `ValueListenableBuilder` + 自己的视图。
///
/// 约定：
/// - `retry` 为 null 时仍会调用显式 / 主题 builder，并把 `null` 传进去；
///   builder 自己决定是否渲染重试按钮。包内默认视图不带按钮。
/// - 默认错误视图不渲染异常原文，只显示 `errorTitle`；需要详情时用
///   [WAsyncTheme.errorBuilder] 或自定义 builder。
///
/// 非公开 API：不从 barrel 导出，只供 [WAsyncView] / [WAsyncStateSliver] 内部使用。
@internal
class WAsyncThemeViews {
  const WAsyncThemeViews._(this._theme);

  /// 读取最近的 [WAsyncTheme]；没有时全部回退到包内默认。
  static WAsyncThemeViews of(BuildContext context) {
    return WAsyncThemeViews._(WAsyncTheme.maybeOf(context));
  }

  final WAsyncTheme? _theme;

  WAsyncStrings get _strings => _theme?.strings ?? const WAsyncStrings();

  /// 加载中：默认转圈，带 `liveRegion` 与可本地化的 `loading` 文案。
  Widget loading(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.loadingBuilder?.call(context) ??
        Semantics(
          liveRegion: true,
          label: _strings.loading,
          excludeSemantics: true,
          child: const Center(child: CircularProgressIndicator()),
        );
  }

  /// 空数据：默认使用 `WAsyncStrings.empty`，带 `liveRegion`。
  Widget empty(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.emptyBuilder?.call(context) ??
        Semantics(
          liveRegion: true,
          child: Center(child: Text(_strings.empty)),
        );
  }

  /// 加载失败：默认 [WAsyncErrorView]；没有 retry 时不带按钮。
  Widget error(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.errorBuilder?.call(context, error, retry) ??
        WAsyncErrorView(
          title: _strings.errorTitle,
          retryText: _strings.retry,
          onRetry: retry,
        );
  }

  /// 刷新失败但保留旧数据：默认 [WAsyncErrorBanner]。
  Widget errorBanner(
    BuildContext context,
    Object error,
    VoidCallback? retry, {
    WAsyncErrorWidgetBuilder? explicit,
  }) {
    return explicit?.call(context, error, retry) ??
        _theme?.errorBannerBuilder?.call(context, error, retry) ??
        WAsyncErrorBanner(
          title: _strings.errorTitle,
          retryText: _strings.retry,
          onRetry: retry,
        );
  }

  /// 刷新中：默认线性进度条。
  Widget refreshing(BuildContext context, {WidgetBuilder? explicit}) {
    return explicit?.call(context) ??
        _theme?.refreshingBuilder?.call(context) ??
        const LinearProgressIndicator();
  }
}
