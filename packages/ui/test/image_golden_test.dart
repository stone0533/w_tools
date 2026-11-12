// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Localizations.override(
        context: context,
        locale: const Locale('zh'),
        child: Scaffold(
          body: Center(
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    ),
  );
}

const _errorBox = ColoredBox(
  color: Color(0xFFFFEBEE),
  child: Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: ColoredBox(color: Color(0xFFEF9A9A)),
    ),
  ),
);

// 用 dart:io 的平台判断：`flutter test` 里 defaultTargetPlatform 固定为 android，
// 用它判断会导致 golden 在所有平台（包括 macOS）都被跳过。
final _goldenSkip = !Platform.isMacOS || kIsWeb;

void main() {
  testWidgets('loaded golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      _wrap(
        WImage.source(
          source: WImageSource.base64(_redPixel),
          style: const WImageStyle(
            width: 64,
            height: 64,
            borderRadius: BorderRadius.all(Radius.circular(12)),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0xFF3949AB), width: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(WImage),
      matchesGoldenFile('goldens/wimage_loaded.png'),
    );
  });

  testWidgets('avatar golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      _wrap(
        WImage.source(
          source: WImageSource.parse('data:image/png;base64,$_redPixel'),
          style: WImageStyle.avatar(64),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(WImage),
      matchesGoldenFile('goldens/wimage_avatar.png'),
    );
  });

  testWidgets('retry error golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      _wrap(
        WImage.source(
          source: WImageSource.parse('data:image/png;base64,@@invalid@@'),
          style: const WImageStyle(width: 160, height: 120),
          slots: const WImageSlots(showRetryButton: true),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(WImage),
      matchesGoldenFile('goldens/wimage_retry.png'),
    );
  });

  testWidgets('error golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      _wrap(
        WImage.source(
          source: WImageSource.parse('data:image/png;base64,@@invalid@@'),
          style: const WImageStyle(width: 64, height: 64),
          slots: const WImageSlots(errorWidget: _errorBox),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(WImage),
      matchesGoldenFile('goldens/wimage_error.png'),
    );
  });

  testWidgets('empty golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      _wrap(
        WImage.source(
          source: WImageSource.parse(''),
          style: const WImageStyle(width: 64, height: 64),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(WImage),
      matchesGoldenFile('goldens/wimage_empty.png'),
    );
  });
}
