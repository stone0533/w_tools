import 'package:flutter/cupertino.dart';
import 'w.dart';

/// GetX 路由观察者，用于监听路由变化并维护路由列表
class GetXRouterObserver extends NavigatorObserver {
  /// 当路由被推入导航栈时调用
  ///
  /// @param route 被推入的路由
  /// @param previousRoute 之前的路由
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    //print('Page pushed: ${route.settings.name}');
    WGet.routes.add(route);
  }

  /// 当路由从导航栈中弹出时调用
  ///
  /// @param route 被弹出的路由
  /// @param previousRoute 之前的路由
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    //print('Page popped: ${route.settings.name}');
    WGet.routes.removeLast();
  }
}
