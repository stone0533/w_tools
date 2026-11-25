import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

bool _isNear(Color actual, Color expected) {
  return (actual.r - expected.r).abs() < 0.02 &&
      (actual.g - expected.g).abs() < 0.02 &&
      (actual.b - expected.b).abs() < 0.02;
}

void main() {
  testWidgets('overlap 最后一项顶部不会被上一项的溢出盖住', (tester) async {
    const colors = [Colors.red, Colors.green, Colors.blue];
    const shotKey = Key('overlap-shot');

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: shotKey,
            child: SizedBox(
              width: 200,
              height: 400,
              child: WListView(
                sliver: WListViewSliver.overlap(
                  itemExtent: 200,
                  overlap: 60,
                  itemCount: 3,
                  itemBuilder: (_, i) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Container(height: 200, color: colors[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final width = boundary.size.width.toInt();
    late ByteData data;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    Color pixelAt(int x, int y) {
      final offset = (y * width + x) * 4;
      return Color.fromARGB(
        data.getUint8(offset + 3),
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      );
    }

    // item2 从 280 开始；item1 的溢出（140..340）不应盖住 item2 顶部。
    expect(_isNear(pixelAt(100, 300), Colors.blue), isTrue);
  });
}
