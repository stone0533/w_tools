// ignore_for_file: deprecated_member_use_from_same_package
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

/// BotToast 需要一个可用的 Overlay，widget 测试中通过 [BotToastInit] 提供；
/// `showCustomLoading` 默认 `crossPage = false`，必须挂载导航观察者，
/// 否则 BotToast 的初始化断言会失败。
Widget _buildToastApp() {
  return MaterialApp(
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    home: const Scaffold(body: SizedBox.expand()),
  );
}

void main() {
  // BotToast 在纯 Dart test() 环境（无 WidgetsFlutterBinding）下
  // showCustomLoading 会抛 LateInitializationError。
  // WToast.showCustomDialog 内部 try-catch 会吞掉该异常并返回 () {}，
  // 因此 builder 已设置时 showXxx 不应向外抛出任何异常，且返回非 null CancelFunc。
  // 注：CancelFunc 即 void Function()，此处直接用类型推导，无需显式 import bot_toast。

  group('WToast.showCustomDialog 签名', () {
    test('返回值是 CancelFunc，可安全调用', () {
      // 直接调用 WToast.showCustomDialog，验证在 try-catch 保护下
      // 即使 BotToast 抛异常也会返回 () {} 而不是崩溃
      final func = WToast.showCustomDialog(
        toastBuilder: (cancel) => const SizedBox.shrink(),
      );
      expect(func, isNotNull);
      func();
    });

    test('toastBuilder 为 required 且可传入自定义 Widget', () {
      final func = WToast.showCustomDialog(
        toastBuilder: (cancel) {
          // 直接调用 cancelFunc 验证可使用
          cancel();
          return const Text('hello');
        },
      );
      expect(func, isNotNull);
    });
  });

  group('WToast.showText 渲染行为', () {
    testWidgets('默认样式渲染文本，hideAll 可清除', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showText(text: 'hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('hello'), findsOneWidget);
      // 默认气泡底色来自主题的 inverseSurface（不写死 black54）
      final container = tester.widget<Container>(
        find.ancestor(of: find.text('hello'), matching: find.byType(Container)).first,
      );
      expect(
        (container.decoration as BoxDecoration?)?.color,
        ThemeData().colorScheme.inverseSurface,
      );

      WToast.hideAll();
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsNothing);
    });

    testWidgets('深色主题下文字取 onInverseSurface，气泡取 inverseSurface', (tester) async {
      final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      WToast.showText(text: 'dark');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final text = tester.widget<Text>(find.text('dark'));
      expect(text.style?.color, theme.colorScheme.onInverseSurface);

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('dark'), matching: find.byType(Container)).first,
      );
      expect((container.decoration as BoxDecoration?)?.color, theme.colorScheme.inverseSurface);
    });

    testWidgets('align 控制显示位置', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showText(text: 'top', align: Alignment.topCenter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 测试窗口高 600，topCenter 应位于上半屏
      expect(tester.getCenter(find.text('top')).dy, lessThan(300));

      WToast.hideAll();
      await tester.pumpAndSettle();
    });

    testWidgets('clickClose 为 true 时点击关闭并触发 onClose', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      var closed = false;
      WToast.showText(
        text: 'click',
        clickClose: true,
        onClose: () => closed = true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tapAt(tester.getCenter(find.text('click')));
      await tester.pumpAndSettle();

      expect(find.text('click'), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('duration 到期后自动关闭', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showText(text: 'auto', duration: const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('auto'), findsNothing);
    });

    testWidgets('WToast.showText 用 contentColor 作为气泡底色', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showText(text: 'bg', contentColor: Colors.red);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('bg'), matching: find.byType(Container)).first,
      );
      expect((container.decoration as BoxDecoration?)?.color, Colors.red);

      WToast.hideAll();
      await tester.pumpAndSettle();
    });
  });

  group('WToast 渲染行为', () {
    testWidgets('showSuccess 渲染消息并按 style 对齐', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showSuccess(
        'ok',
        style: const WToastStyle(
          align: Alignment.topCenter,
          duration: Duration(seconds: 10),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ok'), findsOneWidget);
      expect(tester.getCenter(find.text('ok')).dy, lessThan(300));

      WToast.hideAll();
      await tester.pumpAndSettle();
    });
  });

  // 该组必须放在最后：无 WidgetsFlutterBinding 时 BotToast 会在注册过程中抛异常，
  // 残留的取消函数会污染其静态缓存，影响后续 onlyOne 场景。
  group('WToast.showText / hideAll 在无绑定环境下的保护', () {
    test('showText 通过 onError 上报异常并返回可调用的 CancelFunc', () {
      Object? error;
      final func = WToast.showText(text: 'hello', onError: (e) => error = e);

      expect(func, isNotNull);
      func();
      expect(error, isNotNull);
    });

    test('hideAll 安全调用并上报异常', () {
      Object? error;
      expect(() => WToast.hideAll(onError: (e) => error = e), returnsNormally);
      expect(error, isNotNull);
    });
  });
}
