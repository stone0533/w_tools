import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  setUpAll(() {
    Get.testMode = true;
  });

  tearDown(() {
    WRoute.clearRoutes();
    Get.reset();
    Get.testMode = true;
  });

  group('WRouteObserver — 纯 Dart（Mock Route）', () {
    test('didPush 追加到 WRoute.routes', () {
      final observer = WRouteObserver();
      final route = _FakeRoute('/first');

      observer.didPush(route, null);
      expect(WRoute.routes.length, 1);
      expect(WRoute.routes.first, route);
    });

    test('didPop 按对象移除', () {
      final observer = WRouteObserver();
      final r1 = _FakeRoute('/a');
      final r2 = _FakeRoute('/b');

      observer.didPush(r1, null);
      observer.didPush(r2, null);
      expect(WRoute.routes.length, 2);

      observer.didPop(r2, r1);
      expect(WRoute.routes.length, 1);
      expect(WRoute.routes.first, r1);
    });

    test('didPop 弹出中间路由不影响其后路由（回归：曾用 removeLast）', () {
      final observer = WRouteObserver();
      final r1 = _FakeRoute('/a');
      final r2 = _FakeRoute('/b');
      final r3 = _FakeRoute('/c');

      observer.didPush(r1, null);
      observer.didPush(r2, r1);
      observer.didPush(r3, r2);

      // 弹出中间路由 r2（非栈顶），r1、r3 应保留
      observer.didPop(r2, r1);
      expect(WRoute.routes, [r1, r3]);

      // 空列表上 pop 应为 no-op（不再抛 StateError）
      WRoute.clearRoutes();
      expect(() => observer.didPop(r1, null), returnsNormally);
    });

    test('多次 push/pop 追踪栈正确', () {
      final observer = WRouteObserver();
      final r1 = _FakeRoute('/home');
      final r2 = _FakeRoute('/second');
      final r3 = _FakeRoute('/third');

      observer.didPush(r1, null);
      observer.didPush(r2, r1);
      observer.didPush(r3, r2);
      expect(WRoute.routes.length, 3);
      expect(WRoute.routes.last, r3);

      observer.didPop(r3, r2);
      expect(WRoute.routes.length, 2);
      expect(WRoute.routes.last, r2);

      observer.didPop(r2, r1);
      expect(WRoute.routes.length, 1);
      expect(WRoute.routes.first, r1);
    });

    test('didReplace 替换路由：移除旧、记录新', () {
      final observer = WRouteObserver();
      final oldRoute = _FakeRoute('/old');
      final newRoute = _FakeRoute('/new');

      observer.didPush(oldRoute, null);
      expect(WRoute.routes, [oldRoute]);

      // pushReplacement 场景不会触发 didPush，只会触发 didReplace
      observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      expect(WRoute.routes, [newRoute]);
    });

    test('didRemove 直接移除路由', () {
      final observer = WRouteObserver();
      final r1 = _FakeRoute('/a');
      final r2 = _FakeRoute('/b');

      observer.didPush(r1, null);
      observer.didPush(r2, r1);

      observer.didRemove(r2, r1);
      expect(WRoute.routes, [r1]);
    });

    testWidgets('pushReplacement 后路由记录与真实栈一致（回归）', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [WRouteObserver()],
          home: const Text('A'),
        ),
      );
      await tester.pumpAndSettle();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/b'),
          builder: (_) => const Text('B'),
        ),
      );
      await tester.pumpAndSettle();
      expect(WRoute.routes.map((r) => r.settings.name), contains('/b'));

      navKey.currentState!.pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/c'),
          builder: (_) => const Text('C'),
        ),
      );
      await tester.pumpAndSettle();

      final names = WRoute.routes.map((r) => r.settings.name).toList();
      expect(names, isNot(contains('/b'))); // 旧路由不再残留
      expect(names, contains('/c')); // 新路由被记录
    });
  });

  group('WRoute — 静态路由工具（纯 Dart）', () {
    test('routes 为只读快照，直接修改会抛 UnsupportedError', () {
      expect(WRoute.routes, isEmpty);
      expect(WRoute.routes, isA<List<Route<dynamic>>>());
      expect(() => WRoute.routes.add(_FakeRoute('/x')), throwsUnsupportedError);
    });

    test('removeRouteIfExists — 移除匹配名称', () {
      final mock1 = _FakeRoute('/home');
      final mock2 = _FakeRoute('/settings');
      final mock3 = _FakeRoute('/about');
      _seed([mock1, mock2, mock3]);

      WRoute.removeRouteIfExists('/settings');
      expect(WRoute.routes.length, 2);
      expect(WRoute.routes.contains(mock2), isFalse);
      expect(WRoute.routes.contains(mock1), isTrue);
    });

    test('removeRouteIfExists — 不存在不报错', () {
      _seed([_FakeRoute('/home')]);
      expect(() => WRoute.removeRouteIfExists('/not-exist'), returnsNormally);
      expect(WRoute.routes.length, 1);
    });

    test('removeRoutesAfter — 移除匹配项之上的路由（不含匹配）', () {
      final r1 = _FakeRoute('/home');
      final r2 = _FakeRoute('/settings');
      final r3 = _FakeRoute('/detail');
      final r4 = _FakeRoute('/edit');
      _seed([r1, r2, r3, r4]);

      // 移除 /settings 之上的 r3, r4，保留 r1, r2
      WRoute.removeRoutesAfter('/settings');
      expect(WRoute.routes.length, 2);
      expect(WRoute.routes.contains(r1), isTrue);
      expect(WRoute.routes.contains(r2), isTrue);
      expect(WRoute.routes.contains(r3), isFalse);
    });

    test('removeRoutesAfter — 匹配第一个元素 → 移除其后所有', () {
      _seed([_FakeRoute('/home'), _FakeRoute('/a'), _FakeRoute('/b')]);
      WRoute.removeRoutesAfter('/home');
      expect(WRoute.routes.length, 1);
      expect(WRoute.routes.first.settings.name, '/home');
    });

    test('removeRoutesAfter — 无匹配则不动（不再清空全部）', () {
      _seed([_FakeRoute('/a'), _FakeRoute('/b')]);
      WRoute.removeRoutesAfter('/not-exist');
      expect(WRoute.routes.length, 2);
    });

    test('popUntilRoute — 目标不在路由记录中时不动作（回归：曾会弹空路由栈）', () {
      _seed([_FakeRoute('/a'), _FakeRoute('/b')]);
      WRoute.popUntilRoute('/not-exist');
      expect(WRoute.routes.length, 2); // 未被弹空
    });

    testWidgets('popUntilRoute — 目标不存在时不弹空真实路由栈（回归）', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          navigatorObservers: [WRouteObserver()],
          getPages: [
            GetPage(name: '/', page: () => const Text('A')),
            GetPage(name: '/b', page: () => const Text('B')),
          ],
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/b');
      await tester.pumpAndSettle();
      final before = WRoute.routes.length;
      expect(before, greaterThan(0));

      // 修复前：Get.until 的断言永不成立，Navigator.popUntil 会一路弹到栈空
      WRoute.popUntilRoute('/not-exist');
      await tester.pumpAndSettle();

      expect(WRoute.routes.length, before); // 路由栈未被弹空
    });
  });
}

/// 批量注入路由记录（routes 已封装为只读，需通过 addRoute 注入）
void _seed(List<Route<dynamic>> routes) => routes.forEach(WRoute.addRoute);

// ——— 测试辅助：Fake Route ———

class _FakeRoute<T> extends Route<T> {
  _FakeRoute(this._name);
  final String _name;

  @override
  RouteSettings get settings => RouteSettings(name: _name);
}
