import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_frame.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  testWidgets('WImageFrame 只做装饰，留白交给外层', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Padding(
          padding: EdgeInsets.all(8),
          child: WImageFrame(
            style: WImageStyle(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            ),
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );

    // 外层 Padding + 内部前景边框 DecoratedBox
    expect(find.byType(Padding), findsWidgets);
    expect(find.byType(DecoratedBox), findsOneWidget);
  });

  test('WImageFrame 应用边框 / 阴影', () {
    const style = WImageStyle(
      border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
      boxShadow: [BoxShadow(color: Colors.black12)],
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    const frame = WImageFrame(style: style, child: SizedBox(width: 10, height: 10));
    expect(frame.style.border, isNotNull);
    expect(frame.style.boxShadow, isNotEmpty);
    expect(frame.style.borderRadius, const BorderRadius.all(Radius.circular(6)));
  });

  testWidgets('WImageFrame 构建阴影与前景边框', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WImageFrame(
          style: WImageStyle(
            border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            boxShadow: [BoxShadow(color: Colors.black12)],
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    expect(find.byType(DecoratedBox), findsNWidgets(2));
  });

  testWidgets('没有装饰时不增加任何层', (tester) async {
    const child = SizedBox(width: 10, height: 10);
    await tester.pumpWidget(
      const MaterialApp(
        home: WImageFrame(style: WImageStyle(), child: child),
      ),
    );
    expect(find.byType(DecoratedBox), findsNothing);
    expect(find.byType(ClipRRect), findsNothing);
  });
}
