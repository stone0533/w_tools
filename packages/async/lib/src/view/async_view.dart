import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/async_state.dart';
import 'async_theme.dart';
import 'async_theme_views.dart';

/// 四态异步视图。
///
/// - loading：默认转圈；
/// - ready：调用 [readyBuilder]；
/// - empty：默认「暂无数据」；
/// - failed：默认 [WAsyncErrorView]，并通过 [onRetry] 重试；
/// - failed + 旧数据：保留内容，展示紧凑错误条；
/// - refreshing：保留内容，展示线性进度。
///
/// 默认 loading / empty / error 文案只是 fallback；正式项目应通过
/// [WAsyncTheme] 或显式 builder 覆盖。
///
/// [WAsyncView] 适合页面主体、Column 或 ListView item。
/// `refreshingBuilder` / `errorBannerBuilder` 的定位：
/// - 高度有界（`Scaffold.body`、`Expanded`）时占固定槽，内容让位，不遮挡列表；
/// - 高度无界（`Column` 子项、`ListView` item）时作为 content box 的 overlay，
///   需要固定到视口请外层给有界高度。
///
/// [onRetry] 为 null 时 [errorBuilder] / [errorBannerBuilder] 仍会收到 `null` 的
/// retry，由 builder 决定是否渲染按钮；包内默认视图不带按钮。
///
/// [readyBuilder] 返回内容本身；需要 `RefreshIndicator` / 自定义刷新壳
/// 时，把滚动组件放进 [readyBuilder] 内部，不要包在 [WAsyncView] 外面。
///
/// ready / refreshing / failed + 旧数据共用同一层内容容器，
/// 状态切换不会重建 `readyBuilder` 的子树。
///
/// `T` 可空时，`ready(null)` 仍会调用 [readyBuilder]；只有非 null 的旧数据
/// 才会在 refreshing / failed 时进入保留内容分支。
///
/// [state] 是 `ValueListenable`，不是 `Rx`：本组件只用 `ValueListenableBuilder`
/// 重建自己。页面里其它 Rx 状态（筛选条件、倒计时）上的 `Obx` 不会因此自动重建，
/// 迁移时仍要保留（放进 builder 内层）；删掉它不会有编译错误，但那些状态会静默失效。
class WAsyncView<T> extends StatelessWidget {
  const WAsyncView({
    super.key,
    required this.state,
    this.onRetry,
    required this.readyBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.errorBannerBuilder,
    this.refreshingBuilder,
  });

  final ValueListenable<WAsyncState<T>> state;

  /// 重试回调；为 null 时错误态不渲染重试按钮。
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, T data) readyBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WAsyncErrorWidgetBuilder? errorBuilder;

  /// failed + 旧数据时的紧凑错误条构建器。
  final WAsyncErrorWidgetBuilder? errorBannerBuilder;

  /// refreshing 时的进度指示器；默认 [LinearProgressIndicator]。
  final WidgetBuilder? refreshingBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) {
        final views = WAsyncThemeViews.of(context);
        final data = value.data;

        if (data != null && value.isRefreshing) {
          return _buildContent(
            context,
            data: data,
            leading: views.refreshing(
              context,
              explicit: refreshingBuilder,
            ),
          );
        }

        if (data != null && value.isFailed) {
          return _buildContent(
            context,
            data: data,
            trailing: views.errorBanner(
              context,
              value.error!,
              onRetry,
              explicit: errorBannerBuilder,
            ),
          );
        }

        return value.when(
          loading: () => views.loading(context, explicit: loadingBuilder),
          ready: (data) => _buildContent(context, data: data),
          empty: () => views.empty(context, explicit: emptyBuilder),
          failed: (error) => views.error(
            context,
            error,
            onRetry,
            explicit: errorBuilder,
          ),
        );
      },
    );
  }

  /// ready / refreshing / failed+data 都使用同一层容器，
  /// 避免 readyBuilder 的滚动子树在状态切换时被重新挂载。
  ///
  /// 高度有界时用固定槽 Column（leading / content / trailing 索引固定），
  /// 错误条和刷新条占空间而不是盖住内容；高度无界时退回 Stack overlay。
  Widget _buildContent(
    BuildContext context, {
    required T data,
    Widget? leading,
    Widget? trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = readyBuilder(context, data);

        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leading ?? const SizedBox.shrink(),
              // loose：滚动内容仍拿满可用高度，普通内容保持自身高度，不强行撑满。
              Flexible(fit: FlexFit.loose, child: content),
              trailing ?? const SizedBox.shrink(),
            ],
          );
        }

        final stack = Stack(
          children: [
            content,
            if (leading != null) Positioned(left: 0, right: 0, top: 0, child: leading),
            if (trailing != null) Positioned(left: 0, right: 0, bottom: 0, child: trailing),
          ],
        );

        if (!constraints.hasBoundedWidth) return stack;
        return SizedBox(width: constraints.maxWidth, child: stack);
      },
    );
  }
}
