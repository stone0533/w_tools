import 'dart:collection';

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 根 Navigator 的路由栈记录。
///
/// 由 [WApp] 持有（`app.routeStack`），[WRouteObserver] 把 push/pop 记录到它。
/// 每个 [WApp] 实例拥有自己的栈，不再提供全局静态栈。
class WRouteStack {
  WRouteStack();

  final List<Route<dynamic>> _routes = [];

  /// 当前路由栈的只读视图。
  ///
  /// 返回的是视图，不是拷贝；读取成本为 O(1)。
  UnmodifiableListView<Route<dynamic>> get routes => UnmodifiableListView<Route<dynamic>>(_routes);

  /// 记录一条已入栈路由（供 [WRouteObserver.didPush] 调用）。
  @internal
  void addRoute(Route<dynamic> route) => _routes.add(route);

  /// 移除一条已出栈路由（供 [WRouteObserver.didPop] 调用）。
  @internal
  void removeRoute(Route<dynamic> route) => _routes.remove(route);

  /// 清空路由记录。
  @internal
  void clearRoutes() => _routes.clear();

  /// 按路由名称移除指定路由；返回是否找到并移除。
  bool removeRouteIfExists(String page) {
    final route = _routes.where((route) => route.settings.name == page).firstOrNull;
    if (route == null) return false;

    _routes.remove(route);
    if (route.isActive) Get.removeRoute(route);
    return true;
  }

  /// 移除指定路由之上的所有路由（保留该路由本身），返回移除数量。
  int removeRoutesAfter(String page) {
    final index = _routes.lastIndexWhere((route) => route.settings.name == page);
    if (index < 0) return 0;

    var removed = 0;
    for (var i = _routes.length - 1; i > index; i--) {
      final route = _routes.removeAt(i);
      if (route.isActive) Get.removeRoute(route);
      removed++;
    }
    return removed;
  }

  /// 返回到指定名称的路由（其上的路由全部出栈）；返回是否找到目标。
  ///
  /// 若 [page] 不在当前路由栈中，则不执行任何操作 ——
  /// `Get.until` 受 `Navigator.popUntil` 语义影响，条件永不满足时会一路弹到栈空。
  bool popUntilRoute(String page) {
    if (!_routes.any((route) => route.settings.name == page)) return false;
    Get.until((route) => route.settings.name == page);
    return true;
  }
}
