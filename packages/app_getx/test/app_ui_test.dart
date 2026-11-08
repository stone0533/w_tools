import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

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

  testWidgets('WBottomSheet 返回 Get.back 的结果', (tester) async {
    String? result;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await WBottomSheet.show<String>(
                  Material(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: 'ok'),
                        child: const Text('close'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(result, 'ok');
  });

  testWidgets('isDismissible: false 时点遮罩不关闭', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WBottomSheet.show(
                const Material(
                  child: SizedBox(
                    key: ValueKey('sheet'),
                    height: 120,
                    child: Center(child: Text('sheet')),
                  ),
                ),
                isDismissible: false,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sheet')), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sheet')), findsOneWidget);
  });
}
