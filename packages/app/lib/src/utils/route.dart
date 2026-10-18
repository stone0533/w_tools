import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 路由工具类：维护路由栈并按名称操作路由
///
/// 路由记录由 [WRouteObserver] 维护，**仅覆盖根 Navigator**
/// （observer 只挂在 GetMaterialApp.navigatorObservers，嵌套 Navigator 的栈不计入）；
/// 未接入该 observer 的导航方式也不会反映到 [routes]。
class WRoute {
  /// 路由栈记录，由 [WRouteObserver] 维护，外部请通过 [routes] 只读访问
  static final List<Route<dynamic>> _routes = [];

  /// 当前路由栈的只读快照
  static List<Route<dynamic>> get routes => List.unmodifiable(_routes);

  /// 记录一条已入栈路由（供 [WRouteObserver.didPush] 调用）
  static void addRoute(Route<dynamic> route) => _routes.add(route);

  /// 移除一条已出栈路由（供 [WRouteObserver.didPop] 调用）
  static void removeRoute(Route<dynamic> route) => _routes.remove(route);

  /// 清空路由记录
  static void clearRoutes() => _routes.clear();

  /// 按路由名称移除指定路由（不存在则不执行任何操作）
  ///
  /// - [page]：路由名称
  static void removeRouteIfExists(String page) {
    final route = _routes.where((a) => a.settings.name == page).firstOrNull;
    if (route != null) {
      _routes.remove(route);
      Get.removeRoute(route);
    }
  }

  /// 移除指定路由之上的所有路由（保留该路由本身）
  ///
  /// 若 [page] 不在当前路由栈中，则不执行任何操作。
  ///
  /// - [page]：路由名称
  static void removeRoutesAfter(String page) {
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
  /// 故此处先行校验（与 [removeRoutesAfter] 的"无匹配不动作"语义保持一致）。
  ///
  /// - [page]：路由名称
  static void popUntilRoute(String page) {
    if (!_routes.any((r) => r.settings.name == page)) return;
    Get.until((_) => Get.currentRoute == page);
  }
}
