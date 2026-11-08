import 'package:flutter/widgets.dart';

import 'route_stack.dart';

/// 维护 [WRouteStack] 的观察者。
///
/// 每个 [WApp] 自动创建并挂到自己的栈；默认只记录页面路由，
/// `PopupRoute`（底部弹窗 / 对话框）不进入路由栈。
class WRouteObserver extends NavigatorObserver {
  WRouteObserver({required WRouteStack stack, this.recordPopups = false}) : _stack = stack;

  final WRouteStack _stack;
  final bool recordPopups;

  /// 本观察者写入的路由栈。
  WRouteStack get stack => _stack;

  bool _shouldRecord(Route<dynamic> route) => recordPopups || route is! PopupRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_shouldRecord(route)) _stack.addRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _stack.removeRoute(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _stack.removeRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _stack.removeRoute(oldRoute);
    if (newRoute != null && _shouldRecord(newRoute)) {
      _stack.removeRoute(newRoute); // 防御：替换成已记录的路由时不重复
      _stack.addRoute(newRoute);
    }
  }
}
