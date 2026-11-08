import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Get.testMode = true;
  });

  group('WRouteObserver（纯 Dart）', () {
    test('didPush 追加到指定 WRouteStack', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final route = _FakeRoute('/first');

      observer.didPush(route, null);
      expect(stack.routes, [route]);
    });

    test('didPop 按对象移除，不误删其它路由', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final r1 = _FakeRoute('/a');
      final r2 = _FakeRoute('/b');

      observer.didPush(r1, null);
      observer.didPush(r2, r1);
      observer.didPop(r2, r1);

      expect(stack.routes, [r1]);
      // 空列表上 pop 应为 no-op
      expect(() => observer.didPop(r1, null), returnsNormally);
    });

    test('didReplace 移除旧路由并记录新路由', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final oldRoute = _FakeRoute('/old');
      final newRoute = _FakeRoute('/new');

      observer.didPush(oldRoute, null);
      observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);

      expect(stack.routes, [newRoute]);
    });

    test('didRemove 直接移除路由', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final route = _FakeRoute('/a');

      observer.didPush(route, null);
      observer.didRemove(route, null);
      expect(stack.routes, isEmpty);
    });

    test('默认忽略 PopupRoute（底部弹窗 / 对话框）', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack);
      final popup = _FakePopupRoute();

      observer.didPush(popup, null);
      expect(stack.routes, isEmpty);
    });

    test('recordPopups: true 时记录 PopupRoute', () {
      final stack = WRouteStack();
      final observer = WRouteObserver(stack: stack, recordPopups: true);
      final popup = _FakePopupRoute();

      observer.didPush(popup, null);
      expect(stack.routes, [popup]);
    });

    test('routes 是只读视图', () {
      final stack = WRouteStack();
      expect(() => stack.routes.add(_FakeRoute('/x')), throwsUnsupportedError);
    });
  });

  group('WRouteStack（纯 Dart）', () {
    test('removeRouteIfExists 返回是否删除', () {
      final stack = WRouteStack();
      final route = _FakeRoute('/home');
      stack.addRoute(route);

      expect(stack.removeRouteIfExists('/not-exist'), isFalse);
      expect(stack.removeRouteIfExists('/home'), isTrue);
      expect(stack.routes, isEmpty);
    });

    test('removeRoutesAfter 返回删除数量并保留目标', () {
      final stack = WRouteStack();
      final r1 = _FakeRoute('/home');
      final r2 = _FakeRoute('/settings');
      final r3 = _FakeRoute('/detail');
      for (final route in [r1, r2, r3]) {
        stack.addRoute(route);
      }

      expect(stack.removeRoutesAfter('/not-exist'), 0);
      expect(stack.removeRoutesAfter('/settings'), 1);
      expect(stack.routes, [r1, r2]);
    });

    test('popUntilRoute 目标不存在时返回 false 且不动作', () {
      final stack = WRouteStack();
      stack.addRoute(_FakeRoute('/a'));

      expect(stack.popUntilRoute('/not-exist'), isFalse);
      expect(stack.routes, hasLength(1));
    });
  });

  group('WRouteStack（真实 Navigator）', () {
    testWidgets('push / pushReplacement / remove 与真实栈一致', (tester) async {
      final stack = WRouteStack();
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        GetMaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [WRouteObserver(stack: stack)],
          getPages: [
            GetPage(name: '/', page: () => const Text('home')),
            GetPage(name: '/b', page: () => const Text('b')),
            GetPage(name: '/c', page: () => const Text('c')),
          ],
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();
      expect(stack.routes.map((r) => r.settings.name), ['/']);

      Get.toNamed('/b');
      await tester.pumpAndSettle();
      expect(stack.routes.map((r) => r.settings.name), ['/', '/b']);

      navKey.currentState!.pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/c'),
          builder: (_) => const Text('c'),
        ),
      );
      await tester.pumpAndSettle();
      expect(stack.routes.map((r) => r.settings.name), ['/', '/c']);

      expect(stack.removeRouteIfExists('/c'), isTrue);
      await tester.pumpAndSettle();
      expect(stack.routes.map((r) => r.settings.name), ['/']);
    });

    testWidgets('popUntilRoute 成功回到目标页', (tester) async {
      final stack = WRouteStack();

      await tester.pumpWidget(
        GetMaterialApp(
          navigatorObservers: [WRouteObserver(stack: stack)],
          getPages: [
            GetPage(name: '/', page: () => const Text('home')),
            GetPage(name: '/b', page: () => const Text('b')),
            GetPage(name: '/c', page: () => const Text('c')),
          ],
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/b');
      await tester.pumpAndSettle();
      Get.toNamed('/c');
      await tester.pumpAndSettle();

      expect(stack.popUntilRoute('/'), isTrue);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/');
      expect(stack.routes.map((r) => r.settings.name), ['/']);
    });
  });
}

class _FakeRoute extends Route<void> {
  _FakeRoute(this._name);

  final String _name;

  @override
  RouteSettings get settings => RouteSettings(name: _name);
}

class _FakePopupRoute extends PopupRoute<void> {
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const SizedBox.shrink();
}
