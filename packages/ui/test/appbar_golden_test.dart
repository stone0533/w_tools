import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

// 与 image_golden_test 一致：golden 只在 macOS 生成 / 比对，其它平台跳过。
final _goldenSkip = !Platform.isMacOS || kIsWeb;

void main() {
  testWidgets('WAppBar leading + actions golden', skip: _goldenSkip, (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Center(
          child: SizedBox(
            width: 360,
            child: RepaintBoundary(
              key: const ValueKey('appbar_golden'),
              child: WAppBar(
                title: '订单详情',
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                  tooltip: '返回',
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    tooltip: '搜索',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                    tooltip: '更多',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('appbar_golden')),
      matchesGoldenFile('goldens/wappbar_basic.png'),
    );
  });
}
