import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image.dart';

/// 生成 >64KB 的 PNG，覆盖 `_decodeBase64` 的 isolate 分支（阈值 64KB）。
Future<String> _largePngBase64() async {
  const size = 256;
  final random = Random(42);
  final pixels = Uint8List(size * size * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    pixels[i] = random.nextInt(256);
    pixels[i + 1] = random.nextInt(256);
    pixels[i + 2] = random.nextInt(256);
    pixels[i + 3] = 255;
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    size,
    size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final image = await completer.future;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return base64Encode(data!.buffer.asUint8List());
}

void main() {
  testWidgets('大于 64KB 的 Base64 能通过异步解码渲染', (tester) async {
    final base64Text = (await tester.runAsync(_largePngBase64))!;
    expect(base64Text.length * 3 ~/ 4, greaterThan(64 * 1024));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WImage(
            data: 'data:image/png;base64,$base64Text',
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
      ),
    );

    // compute() 在真实 isolate 中执行，需要 runAsync 放行
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });
}
