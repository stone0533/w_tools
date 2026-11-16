import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:w_tools_async/w_tools_async.dart';

/// 业务页面单区块的规范入口。
///
/// 内部使用 [WAsyncView]：
/// - `onRetry` 固定接 [WAsyncController.load]，失败态默认有恢复入口；
/// - loading / error 外观走 `WAsyncTheme`；
/// - 空态可用 [emptyBuilder] 覆盖。
///
/// [controller] 由页面持有；请在页面 `initState` / `onInit` 调 `controller.load()`，
/// 并在 dispose / onClose 调 `controller.dispose()`。
class WAsyncSection<T> extends StatelessWidget {
  const WAsyncSection({
    super.key,
    required this.controller,
    required this.builder,
    this.emptyBuilder,
  });

  final WAsyncController<T> controller;
  final Widget Function(BuildContext context, T data) builder;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return WAsyncView<T>(
      state: controller.state,
      onRetry: () => unawaited(controller.load()),
      readyBuilder: builder,
      emptyBuilder: emptyBuilder,
    );
  }
}
