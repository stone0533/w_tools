import 'package:flutter/widgets.dart';

import 'route.dart';

/// 路由观察者：监听路由变化并维护 [WRoute] 中的路由列表
class WRouteObserver extends NavigatorObserver {
  /// 路由入栈时记录
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WRoute.addRoute(route);
  }

  /// 路由出栈时移除记录
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WRoute.removeRoute(route);
  }

  /// 路由被替换时调用（如 `Navigator.pushReplacement`）
  ///
  /// 该场景**不会**触发 [didPush]，若不处理会导致路由记录漂移（旧路由残留、新路由缺失），
  /// 进而使基于 [WRoute.routes] 的操作定位错误。
  ///
  /// - [newRoute]：新路由；为 null 表示无新路由
  /// - [oldRoute]：被替换的路由；为 null 表示无旧路由
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) WRoute.removeRoute(oldRoute);
    if (newRoute != null) WRoute.addRoute(newRoute);
  }

  /// 路由被直接移除时调用（如 `Navigator.removeRoute`）
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WRoute.removeRoute(route);
  }
}
