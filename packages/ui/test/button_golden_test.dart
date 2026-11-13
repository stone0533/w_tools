import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

// 与 image_golden_test 一致：golden 只在 macOS 生成 / 比对，其它平台跳过。
final _goldenSkip = !Platform.isMacOS || kIsWeb;

Widget _buildButtons(BuildContext context) {
  final styles = WButtonStyleSet.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      WButton(style: styles.primary, icon: Icons.star, label: 'Primary', onTap: () {}),
      const SizedBox(height: 8),
      WButton(style: styles.secondary, icon: Icons.add, label: 'Secondary', onTap: () {}),
      const SizedBox(height: 8),
      WButton(style: styles.text, icon: Icons.info_outline, label: 'Text', onTap: () {}),
      const SizedBox(height: 8),
      WButton(style: styles.danger, icon: Icons.delete_outline, label: 'Danger', onTap: () {}),
    ],
  );
}

void main() {
  testWidgets('button icon + label golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: ValueKey('button_golden'),
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Builder(builder: _buildButtons),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('button_golden')),
      matchesGoldenFile('goldens/button_icon_text.png'),
    );
  });
}
