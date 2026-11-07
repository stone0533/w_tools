import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('没有弹层时 WFormPopup.hide 不会 pop 当前页面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (pageContext) => Scaffold(
                      appBar: AppBar(title: const Text('第二页')),
                      body: Center(
                        child: ElevatedButton(
                          onPressed: () => WFormPopup.hide(pageContext),
                          child: const Text('关闭弹层'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('打开第二页'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开第二页'));
    await tester.pumpAndSettle();
    expect(find.text('第二页'), findsOneWidget);

    await tester.tap(find.text('关闭弹层'));
    await tester.pumpAndSettle();

    expect(find.text('第二页'), findsOneWidget);
  });
}
