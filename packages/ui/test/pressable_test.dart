import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/pressable.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('点击任意 child 触发 onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        WPressable(
          onTap: () => taps++,
          child: const Card(
            child: SizedBox(width: 120, height: 60, child: Text('card')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('禁用时阻断 child 的点击', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        WPressable(
          enabled: false,
          onTap: () => taps++,
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 40, child: Text('child')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('child'));
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('不声明 button 语义', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WPressable(
          onTap: () {},
          child: const Text('not-button'),
        ),
      ),
    );

    final semantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(WPressable),
        matching: find.byType(Semantics),
      ),
    );
    expect(
      semantics.where((s) => s.properties.button == true),
      isEmpty,
    );
    expect(
      semantics.where((s) => s.properties.onTap != null),
      isNotEmpty,
    );
  });

  testWidgets('opacity 效果按下', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WPressable(
          onTap: () {},
          pressedOpacity: 0.4,
          child: const Text('opacity'),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('opacity')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.4,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('scale 效果按下', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WPressable(
          onTap: () {},
          effect: WPressEffect.scale,
          pressedScale: 0.8,
          child: const Text('scale'),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('scale')),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.8,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('长按触发 onLongPress', (tester) async {
    var longPressed = 0;
    await tester.pumpWidget(
      _wrap(
        WPressable(
          onLongPress: () => longPressed++,
          child: const SizedBox(
            width: 80,
            height: 40,
            child: Text('long'),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('long'));
    await tester.pumpAndSettle();
    expect(longPressed, 1);
  });
}
