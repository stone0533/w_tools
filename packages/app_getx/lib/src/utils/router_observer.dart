import 'package:flutter/widgets.dart';

import 'route.dart';

/// 维护路由栈的观察者。
///
/// 默认记录到 [WRouteStack.defaultStack]（兼容旧静态 `WRoute`）；
/// 传 [stack] 时记录到指定实例（`WApp` 会自动传 `WApp.routeStack`）。
class WRouteObserver extends NavigatorObserver {
  WRouteObserver({WRouteStack? stack}) : _stack = stack ?? WRouteStack.defaultStack;

  final WRouteStack _stack;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 记录**根 Navigator 中实际入栈**的路由；嵌套 Navigator 不会经过这里
    _stack.addRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.removeRoute(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    // 被 remove（而非 pop）的路由同样要清理，否则栈记录会残留失效路由，
    // 进而使基于 routes 的操作定位错误。
    _stack.removeRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _stack.removeRoute(oldRoute);
    if (newRoute != null) _stack.addRoute(newRoute);
  }
}
