import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
