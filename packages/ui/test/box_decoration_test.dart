import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  const base = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
    boxShadow: WShadows.card,
  );

  group('WBoxDecorationExtension', () {
    test('withBackground(color:) 清空 gradient，保留其他字段', () {
      final next = base
          .withBackground(gradient: WGradients.vertical(const [Colors.red, Colors.blue]))
          .withBackground(color: Colors.black);

      expect(next.color, Colors.black);
      expect(next.gradient, isNull);
      expect(next.borderRadius, base.borderRadius);
      expect(next.border, base.border);
      expect(next.boxShadow, base.boxShadow);
    });

    test('withBackground(gradient:) 清空 color', () {
      final next = base.withBackground(
        gradient: WGradients.vertical(const [Colors.red, Colors.blue]),
      );

      expect(next.color, isNull);
      expect(next.gradient, isA<LinearGradient>());
      expect(next.borderRadius, base.borderRadius);
    });

    test('withBackground 必须且只能传一个背景', () {
      expect(() => base.withBackground(), throwsAssertionError);
      expect(
        () => base.withBackground(
          color: Colors.black,
          gradient: WGradients.vertical(const [Colors.red, Colors.blue]),
        ),
        throwsAssertionError,
      );
    });

    test('circle 清空 borderRadius，保留背景与阴影', () {
      final circle = base.circle();

      expect(circle.shape, BoxShape.circle);
      expect(circle.borderRadius, isNull);
      expect(circle.color, Colors.white);
      expect(circle.border, base.border);
      expect(circle.boxShadow, base.boxShadow);
    });
  });

  group('WGradients', () {
    test('vertical / horizontal / diagonal 方向正确', () {
      final colors = <Color>[Colors.red, Colors.blue];

      expect(WGradients.vertical(colors).begin, Alignment.topCenter);
      expect(WGradients.vertical(colors).end, Alignment.bottomCenter);
      expect(WGradients.horizontal(colors).begin, Alignment.centerLeft);
      expect(WGradients.horizontal(colors).end, Alignment.centerRight);
      expect(WGradients.diagonal(colors).begin, Alignment.topLeft);
      expect(WGradients.diagonal(colors).end, Alignment.bottomRight);
    });

    test('非法 colors / stops 断言', () {
      expect(
        () => WGradients.vertical(const [Colors.red]),
        throwsAssertionError,
      );
      expect(
        () => WGradients.vertical(
          const [Colors.red, Colors.blue],
          stops: const [0],
        ),
        throwsAssertionError,
      );
    });

    test('radial 支持 stops 和 radius', () {
      final gradient = WGradients.radial(
        const [Colors.red, Colors.blue],
        stops: const [0, 1],
        radius: 0.8,
      );

      expect(gradient.stops, const [0, 1]);
      expect(gradient.radius, 0.8);
    });
  });

  group('WShadows', () {
    test('预设阴影可用', () {
      expect(WShadows.none, isEmpty);
      expect(WShadows.card, isNotEmpty);
      expect(WShadows.elevated, isNotEmpty);
      expect(WShadows.floating, isNotEmpty);
    });
  });

  testWidgets('WWidgetExtension.withDecoration 渲染 DecoratedBox', (tester) async {
    const decoration = BoxDecoration(color: Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: const Text('box').withDecoration(decoration),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && widget.decoration == decoration,
      ),
      findsOneWidget,
    );
  });
}
