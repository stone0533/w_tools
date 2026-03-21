import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Get 扩展工具类，提供路由管理和弹窗显示功能
class WGet {
  /// 路由列表，用于跟踪当前导航栈中的路由
  static List<Route<dynamic>> routes = [];

  /// 根据路由名称移除指定路由
  ///
  /// @param page 路由名称
  static void removeRouteIfExistByName(String page) {
    var route = routes.where((a) => a.settings.name?.compareTo(page) == 0).firstOrNull;
    if (route != null) {
      routes.remove(route);
      Get.removeRoute(route);
    }
  }

  /// 移除指定路由之前的所有路由
  ///
  /// @param page 路由名称
  static void removeRouteUntil(String page) {
    for (int i = routes.length - 1; i >= 0; i--) {
      var route = routes[i];
      if (route.settings.name?.compareTo(page) == 0) {
        break;
      }
      routes.remove(route);
      Get.removeRoute(route);
    }
  }

  /// 导航到指定路由
  ///
  /// @param page 路由名称
  static void until(String page) {
    Get.until((route) => Get.currentRoute == page);
  }

  /// 显示底部弹窗
  ///
  /// @param bottomSheet 弹窗内容
  /// @description 显示一个带有遮罩层的底部弹窗，点击遮罩层可关闭弹窗
  static bottomSheet(Widget bottomSheet) {
    Get.bottomSheet(
      Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(),
            ),
          ),
          bottomSheet,
        ],
      ),
      isScrollControlled: true,
    );
  }
}
