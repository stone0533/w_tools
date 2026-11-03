// ignore_for_file: deprecated_member_use_from_same_package
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

Widget _app({ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    home: const Scaffold(body: SizedBox.expand()),
  );
}

void main() {
  group('WToastStyle', () {
    test('copyWith 保留未指定的字段，传 null 可清空', () {
      void onClose() {}
      final style = WToastStyle(
        onClose: onClose,
        backgroundColor: Colors.blue,
        successBuilder: (message, cancel) => const SizedBox.shrink(),
      );

      final copy = style.copyWith(duration: const Duration(seconds: 5));
      expect(copy.duration, const Duration(seconds: 5));
      expect(copy.onClose, same(onClose));
      expect(copy.backgroundColor, Colors.blue);

      final cleared = style.copyWith(onClose: null, successBuilder: null, backgroundColor: null);
      expect(cleared.onClose, isNull);
      expect(cleared.successBuilder, isNull);
      expect(cleared.backgroundColor, isNull);
      // 原对象不受影响
      expect(style.backgroundColor, Colors.blue);
    });

    test('defaults 是 2 秒居中', () {
      expect(WToastStyle.defaults.duration, const Duration(seconds: 2));
      expect(WToastStyle.defaults.align, Alignment.center);
    });
  });

  group('WToast 静态入口 + WToastStyle', () {
    testWidgets('showSuccess 使用自定义 builder', (tester) async {
      await tester.pumpWidget(_app());

      WToast.showSuccess(
        'ok',
        style: WToastStyle(
          successBuilder: (message, cancel) => Text('custom-$message'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('custom-ok'), findsOneWidget);
      WToast.hideAll();
      await tester.pumpAndSettle();
    });

    testWidgets('未设置 builder 时默认样式跟随主题', (tester) async {
      final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);
      await tester.pumpWidget(_app(theme: theme));

      WToast.showSuccess('done');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final text = tester.widget<Text>(find.text('done'));
      expect(text.style?.color, theme.colorScheme.onInverseSurface);
      WToast.hideAll();
      await tester.pumpAndSettle();
    });

    testWidgets('showCustom 没有 builder 时抛 ArgumentError', (tester) async {
      await tester.pumpWidget(_app());
      expect(() => WToast.showCustom(), throwsArgumentError);
    });

    testWidgets('showLoading 全局唯一，hideLoading 可关闭', (tester) async {
      await tester.pumpWidget(_app());

      WToast.showLoading(message: 'first');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('first'), findsOneWidget);

      WToast.showLoading(message: 'second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);

      WToast.hideLoading();
      await tester.pumpAndSettle();
      expect(find.text('second'), findsNothing);
    });
  });
}
