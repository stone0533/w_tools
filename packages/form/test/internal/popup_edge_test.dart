import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/popup.dart';

void main() {
  testWidgets('锚点靠右 + 显式 width 超出屏幕时向右钳制', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const popupKey = Key('right-edge-popup');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                right: 0,
                top: 100,
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => WFormPopup.show(
                      context: context,
                      width: 300,
                      builder: (_) => const SizedBox(
                        key: popupKey,
                        height: 100,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final popupRect = tester.getRect(find.byKey(popupKey));
    // 弹层只能被裁进视口，不能越出右边缘（越界部分不可见也不可点）。
    expect(popupRect.right, lessThanOrEqualTo(400));
    expect(popupRect.left, greaterThanOrEqualTo(0));
  });
}
