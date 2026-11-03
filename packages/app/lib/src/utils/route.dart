import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 路由栈（实例）。
///
/// 由 [WApp] 持有（`WApp.routeStack`），[WRouteObserver] 把 push/pop 记录到它。
/// 旧代码里的静态 `WRoute` 已弃用，委托到 [WRouteStack.defaultStack]。
class WRouteStack {
  WRouteStack();

  /// 全局默认栈（旧静态 [WRoute] 的落点；新代码请用 `WApp.routeStack`）
  static final WRouteStack defaultStack = WRouteStack();

  final List<Route<dynamic>> _routes = [];

  /// 当前路由栈的只读快照
  List<Route<dynamic>> get routes => List.unmodifiable(_routes);

  /// 记录一条已入栈路由（供 [WRouteObserver.didPush] 调用）
  void addRoute(Route<dynamic> route) => _routes.add(route);

  /// 移除一条已出栈路由（供 [WRouteObserver.didPop] 调用）
  void removeRoute(Route<dynamic> route) => _routes.remove(route);

  /// 清空路由记录
  void clearRoutes() => _routes.clear();

  /// 按路由名称移除指定路由（不存在则不执行任何操作）
  void removeRouteIfExists(String page) {
    final route = _routes.where((a) => a.settings.name == page).firstOrNull;
    if (route != null) {
      _routes.remove(route);
      Get.removeRoute(route);
    }
  }

  /// 移除指定路由之上的所有路由（保留该路由本身）
  void removeRoutesAfter(String page) {
    final index = _routes.lastIndexWhere((r) => r.settings.name == page);
    if (index < 0) return;
    for (int i = _routes.length - 1; i > index; i--) {
      final route = _routes[i];
      _routes.removeAt(i);
      Get.removeRoute(route);
    }
  }

  /// 返回到指定名称的路由（其上的路由全部出栈）
  ///
  /// 若 [page] 不在当前路由栈中，则不执行任何操作 ——
  /// `Get.until` 委托给 `Navigator.popUntil`，条件永不满足时会**一路弹到栈空**，
  /// 故此处先行校验。
  void popUntilRoute(String page) {
    if (!_routes.any((r) => r.settings.name == page)) return;
    // 用路由自身的 name 判断，避免 Get.currentRoute 与 settings.name 不一致时一路弹空
    Get.until((route) => route.settings.name == page);
  }
}
