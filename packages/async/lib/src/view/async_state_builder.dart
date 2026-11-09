import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../state/async_state.dart';

/// 把 [WAsyncState] 交给调用方自行构建 UI。
///
/// 适合滚动页面、`SmartRefresher`、`CustomScrollView` 或需要完全控制
/// loading / empty / error 布局的场景。
///
/// 普通页面区块优先使用 `WAsyncView`。
///
/// [builder] 必须始终返回稳定的滚动壳（例如 `SmartRefresher` +
/// `CustomScrollView`）；loading / empty / error 只能作为壳内部的分支，
/// 不要在外层切换成 Center / ErrorView，否则滚动组件会被重新挂载。
///
/// [state] 是 `ValueListenable`，不是 `Rx`：本组件只用 `ValueListenableBuilder`
/// 重建自己。迁移自 `Obx` 的页面里，其它 Rx 状态上的 `Obx` 仍要保留
/// （放进 [builder] 内层）；删掉它不会有编译错误，但那些状态会静默失效。
class WAsyncStateBuilder<T> extends StatelessWidget {
  const WAsyncStateBuilder({
    super.key,
    required this.state,
    required this.builder,
  });

  final ValueListenable<WAsyncState<T>> state;
  final Widget Function(BuildContext context, WAsyncState<T> state) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WAsyncState<T>>(
      valueListenable: state,
      builder: (context, value, _) => builder(context, value),
    );
  }
}
