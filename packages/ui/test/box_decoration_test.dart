import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  const base = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  group('WBoxDecorationExtension', () {
    test('withGradient 保留其他字段', () {
      final next = base.withGradient(
        WGradients.vertical(const [Colors.red, Colors.blue]),
      );

      expect(next.color, Colors.white);
      expect(next.borderRadius, const BorderRadius.all(Radius.circular(12)));
      expect(next.gradient, isA<LinearGradient>());
    });

    test('withShadow 保留背景和圆角', () {
      final next = base
          .withGradient(WGradients.horizontal(const [Colors.red, Colors.blue]))
          .withShadow(WShadows.card);

      expect(next.gradient, isNotNull);
      expect(next.borderRadius, base.borderRadius);
      expect(next.boxShadow, WShadows.card);
    });

    test('without* 可以显式清空', () {
      final decorated = base
          .withGradient(WGradients.diagonal(const [Colors.red, Colors.blue]))
          .withShadow(WShadows.card)
          .withBorder(Border.all(color: Colors.black));

      expect(decorated.withoutGradient().gradient, isNull);
      expect(decorated.withoutShadow().boxShadow, isNull);
      expect(decorated.withoutBorder().border, isNull);
      expect(decorated.withoutBorderRadius().borderRadius, isNull);
      expect(decorated.withoutColor().color, isNull);
    });

    test('circle 清空 borderRadius', () {
      final circle = base.circle();

      expect(circle.shape, BoxShape.circle);
      expect(circle.borderRadius, isNull);
    });

    test('circle 后不能再设置 borderRadius', () {
      expect(
        () => base.circle().withBorderRadius(BorderRadius.circular(8)),
        throwsAssertionError,
      );
    });

    test('已有 borderRadius 时不能直接 withShape(circle)', () {
      expect(
        () => base.withShape(BoxShape.circle),
        throwsAssertionError,
      );
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
