import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

// 与 image_golden_test 一致：golden 只在 macOS 生成 / 比对，其它平台跳过。
final _goldenSkip = !Platform.isMacOS || kIsWeb;

void main() {
  testWidgets('icon + text golden', skip: _goldenSkip, (tester) async {
    final theme = ThemeData(useMaterial3: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('icon_text_golden'),
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WIconText(icon: Icons.star, text: '收藏'),
                      SizedBox(height: 12),
                      WIconText(
                        icon: Icons.location_on,
                        text: '上海市',
                        variant: WTextVariant.title,
                      ),
                      SizedBox(height: 12),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: WIconText(icon: Icons.info_outline, text: '说明'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('icon_text_golden')),
      matchesGoldenFile('goldens/icon_text.png'),
    );
  });
}
