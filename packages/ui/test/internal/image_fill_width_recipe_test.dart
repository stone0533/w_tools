import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 24x240，红 / 绿 / 蓝 三段各 80px（1:10 的窄图）。
const _threeBandImage =
    'iVBORw0KGgoAAAANSUhEUgAAABgAAADwCAIAAACVAjNAAAAAYklEQVR4nO3OoQ0AQAgEweu/ad7DSwRiktWTTSUr7SggEAgEAoFAIBAIBAKBQCAQCAQC/aGDSyAQCAQCgUAgEAgEAoFAIBAIBAJN6OASCAQCgUAgEAgEAoFAIBAIBAKBQK0HSslqy1sL7uYAAAAASUVORK5CYII=';

const _shotKey = ValueKey('shot');

void main() {
  Uint8List bytes() => base64Decode(_threeBandImage);

  /// 宽度铺满 + 高度上限：ConstrainedBox(maxHeight) + width: double.infinity + fitWidth。
  Widget recipe({
    required double maxHeight,
    Alignment alignment = Alignment.center,
  }) {
    return SizedBox(
      width: 300,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: WImage.source(
          source: WImageSource.provider(MemoryImage(bytes())),
          style: WImageStyle(
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: alignment,
          ),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pumpAndSettle();
  }

  Future<Color> pixelAt(WidgetTester tester, int x, int y) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    final width = boundary.size.width.toInt();
    late ByteData data;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });
    final offset = (y * width + x) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  }

  testWidgets('未超过上限时与普通 fitWidth 一致', (tester) async {
    await pump(tester, SingleChildScrollView(child: recipe(maxHeight: 5000)));
    // 1:10 窄图在 300 宽下 fitWidth 高度是 3000，未被 5000 截断
    expect(tester.getSize(find.byType(Image)), const Size(300, 3000));
  });

  testWidgets('超过上限时盒子固定在 maxHeight，alignment 决定保留哪一段', (tester) async {
    final cases = <(Alignment, Color)>[
      (Alignment.topCenter, const Color(0xFFFF0000)),
      (Alignment.center, const Color(0xFF00FF00)),
      (Alignment.bottomCenter, const Color(0xFF0000FF)),
    ];
    for (final (alignment, expected) in cases) {
      await pump(
        tester,
        RepaintBoundary(
          key: _shotKey,
          child: recipe(maxHeight: 500, alignment: alignment),
        ),
      );
      expect(tester.getSize(find.byType(Image)), const Size(300, 500));
      expect(
        await pixelAt(tester, 150, 250),
        expected,
        reason: 'alignment = $alignment 应保留对应颜色的那一段',
      );
    }
  });
}
