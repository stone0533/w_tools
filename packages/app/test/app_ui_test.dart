import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  testWidgets('WBottomSheet 内容按自身高度布局，不整屏撑满', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WBottomSheet.show(
                const SizedBox(key: ValueKey('sheet'), height: 120, width: 200),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('sheet'))).height, 120);
  });
}
