// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/src/components/common/image/image.dart';

/// 真实浏览器环境下运行：`flutter test --platform chrome test/image_web_browser_test.dart`
void main() {
  testWidgets('Web 上 WImage.file 渲染 unsupported', (tester) async {
    WImageError? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: WImage.source(
          source: WImageSource.file('/tmp/a.png'),
          slots: WImageSlots(
            errorWidgetBuilder: (context, url, error) {
              captured = error;
              return const Text('UNSUPPORTED');
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(captured?.kind, WImageErrorKind.unsupported);
    expect(find.text('UNSUPPORTED'), findsOneWidget);
  });
}
