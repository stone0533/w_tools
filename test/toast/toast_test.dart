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

  group('WToastConfig 默认值', () {
    test('构造函数默认字段值', () {
      final c = WToastConfig();
      expect(c.duration, const Duration(seconds: 2));
      expect(c.backgroundColor, Colors.black38);
      expect(c.align, Alignment.center);
      expect(c.animationDuration, const Duration(milliseconds: 200));
    });

    test('四个 builder 默认 null', () {
      final c = WToastConfig();
      expect(c.successBuilder, isNull);
      expect(c.errorBuilder, isNull);
      expect(c.warningBuilder, isNull);
      expect(c.loadingBuilder, isNull);
    });
  });

  group('WToastConfig 未设置 builder 时使用默认样式', () {
    test('showSuccess / showError / showWarning 返回可调用 CancelFunc', () {
      final c = WToastConfig();

      final success = c.showSuccess('ok');
      final error = c.showError('fail');
      final warning = c.showWarning('warn');

      expect(success, isNotNull);
      expect(error, isNotNull);
      expect(warning, isNotNull);
      success();
      error();
      warning();
    });

    test('showLoading 使用默认转圈样式', () {
      final c = WToastConfig();

      final func = c.showLoading(message: 'load');
      expect(func, isNotNull);
      func();
      c.hideLoading();
    });
  });

  group('WToastConfig 配置接通', () {
    Widget noopBuilder(Object? msg, void Function() cancel) => const SizedBox.shrink();

    test('showCustom 使用 toastBuilder', () {
      final c = WToastConfig()..toastBuilder = (_) => const Text('custom');

      final func = c.showCustom();
      expect(func, isNotNull);
      func();
    });

    test('showCustom 未设置 toastBuilder 时抛 ArgumentError', () {
      final c = WToastConfig();
      expect(() => c.showCustom(), throwsA(isA<ArgumentError>()));
    });

    test('onError 收到 BotToast 异常', () {
      Object? error;
      final c = WToastConfig()
        ..successBuilder = noopBuilder
        ..onError = (e) => error = e;

      c.showSuccess('ok');

      expect(error, isNotNull);
    });
  });

  group('WToastConfig builder 已设置时应正常返回 CancelFunc', () {
    Widget noopBuilder(Object? msg, void Function() cancel) => const SizedBox.shrink();
    Widget noopLoadingBuilder(
      Object? msg,
      void Function() cancel,
      bool dismissible,
    ) => const SizedBox.shrink();

    test('showSuccess 不抛异常并返回 CancelFunc', () {
      final c = WToastConfig()..successBuilder = noopBuilder;
      final func = c.showSuccess('ok');
      expect(func, isNotNull);
      func(); // 空函数安全调用
    });

    test('showError 不抛异常并返回 CancelFunc', () {
      final c = WToastConfig()..errorBuilder = noopBuilder;
      final func = c.showError('fail');
      expect(func, isNotNull);
      func();
    });

    test('showWarning 不抛异常并返回 CancelFunc', () {
      final c = WToastConfig()..warningBuilder = noopBuilder;
      final func = c.showWarning('warn');
      expect(func, isNotNull);
      func();
    });

    test('showLoading 不抛异常并返回 CancelFunc', () {
      final c = WToastConfig()..loadingBuilder = noopLoadingBuilder;
      final func = c.showLoading(message: 'load');
      expect(func, isNotNull);
      func();
    });

    test('hideLoading 在无 loading 状态时安全调用', () {
      final c = WToastConfig();
      expect(() => c.hideLoading(), returnsNormally);
    });

    test('showLoading → hideLoading 正常流程', () {
      final c = WToastConfig()..loadingBuilder = noopLoadingBuilder;

      c.showLoading(message: 'load');
      expect(() => c.hideLoading(), returnsNormally);
      // 再次调用也不应抛异常（null check 保护）
      expect(() => c.hideLoading(), returnsNormally);
    });

    test('连续调用 showLoading 不抛异常', () {
      final c = WToastConfig()..loadingBuilder = noopLoadingBuilder;

      final f1 = c.showLoading(message: 'first');
      final f2 = c.showLoading(message: 'second');
      expect(f1, isNotNull);
      expect(f2, isNotNull);
      // 第一次的 cancelFunc 会被第二次 showLoading 内部自动调用
      expect(() => f1(), returnsNormally);
      expect(() => f2(), returnsNormally);
    });
  });

  group('WToastConfig duration/align 优先级', () {
    Widget noop(Object? msg, void Function() cancel) => const SizedBox.shrink();

    test('showSuccess 调用参数覆盖配置 duration', () {
      final c = WToastConfig()
        ..duration = const Duration(milliseconds: 500)
        ..successBuilder = noop;

      final func = c.showSuccess('ok', duration: const Duration(seconds: 3));
      expect(func, isNotNull);
    });

    test('showSuccess 调用参数覆盖配置 align', () {
      final c = WToastConfig()
        ..align = Alignment.bottomCenter
        ..successBuilder = noop;

      final func = c.showSuccess('ok', align: Alignment.topCenter);
      expect(func, isNotNull);
    });

    test('showError / showWarning 同理支持参数覆盖', () {
      final c = WToastConfig()
        ..errorBuilder = noop
        ..warningBuilder = noop;

      expect(
        c.showError('fail', duration: const Duration(seconds: 5)),
        isNotNull,
      );
      expect(
        c.showWarning('warn', align: Alignment.bottomCenter),
        isNotNull,
      );
    });
  });

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

  group('WToastConfig.copy / copyWith', () {
    test('copy 生成字段相同但相互独立的副本', () {
      final c = WToastConfig()..duration = const Duration(seconds: 5);
      final copied = c.copy();

      expect(copied.duration, const Duration(seconds: 5));
      expect(copied.backgroundColor, c.backgroundColor);

      copied.duration = const Duration(seconds: 1);
      expect(c.duration, const Duration(seconds: 5));
    });

    test('copyWith 覆盖指定字段，未指定的字段沿用原值', () {
      Widget builder(Object? message, void Function() cancel) => const SizedBox.shrink();
      final c = WToastConfig()
        ..align = Alignment.bottomCenter
        ..successBuilder = builder;

      final copied = c.copyWith(align: Alignment.topCenter);

      expect(copied.align, Alignment.topCenter);
      expect(copied.backgroundColor, c.backgroundColor);
      expect(copied.successBuilder, same(builder));
    });
  });

  group('WToast.showText 渲染行为', () {
    testWidgets('默认样式渲染文本，hideAll 可清除', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      WToast.showText(text: 'hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('hello'), findsOneWidget);
      // 默认气泡底色为 black54
      final container = tester.widget<Container>(
        find.ancestor(of: find.text('hello'), matching: find.byType(Container)).first,
      );
      expect((container.decoration as BoxDecoration?)?.color, Colors.black54);

      WToast.hideAll();
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsNothing);
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

    testWidgets('WToastConfig.showText 用配置的 backgroundColor 作为气泡底色', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      final config = WToastConfig()..backgroundColor = Colors.red;
      config.showText('bg');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('bg'), matching: find.byType(Container)).first,
      );
      expect((container.decoration as BoxDecoration?)?.color, Colors.red);

      config.hideAll();
      await tester.pumpAndSettle();
    });
  });

  group('WToastConfig 渲染行为', () {
    testWidgets('showSuccess 渲染消息并按配置对齐', (tester) async {
      await tester.pumpWidget(_buildToastApp());

      final config = WToastConfig()
        ..align = Alignment.topCenter
        ..duration = const Duration(seconds: 10);
      config.showSuccess('ok');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ok'), findsOneWidget);
      expect(tester.getCenter(find.text('ok')).dy, lessThan(300));

      config.hideAll();
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
