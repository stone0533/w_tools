import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image_frame.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  testWidgets('WImageFrame：margin 在外、padding 在装饰层内', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WImageFrame(
          style: WImageStyle(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(4),
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
          ),
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );

    final decorated = find.byType(DecoratedBox);
    expect(decorated, findsOneWidget);

    // padding 在 DecoratedBox 内部
    expect(
      find.descendant(of: decorated, matching: find.byType(Padding)),
      findsWidgets,
    );
    // margin 是 DecoratedBox 的祖先
    expect(
      find.ancestor(of: decorated, matching: find.byType(Padding)),
      findsWidgets,
    );
  });

  test('WImageFrame 应用边框 / 阴影 / margin / padding', () {
    const style = WImageStyle(
      border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
      boxShadow: [BoxShadow(color: Colors.black12)],
      margin: EdgeInsets.all(2),
      padding: EdgeInsets.all(3),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
    const frame = WImageFrame(style: style, child: SizedBox(width: 10, height: 10));
    expect(frame.style.border, isNotNull);
    expect(frame.style.boxShadow, isNotEmpty);
    expect(frame.style.margin, const EdgeInsets.all(2));
  });

  testWidgets('WImageFrame 构建阴影与前景边框', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WImageFrame(
          style: WImageStyle(
            border: Border.fromBorderSide(BorderSide(color: Colors.black12)),
            boxShadow: [BoxShadow(color: Colors.black12)],
            borderRadius: BorderRadius.all(Radius.circular(6)),
            margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(3),
          ),
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    expect(find.byType(DecoratedBox), findsNWidgets(2));
  });
}
