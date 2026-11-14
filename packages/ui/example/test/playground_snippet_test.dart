import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui_example/playground_config.dart';
import 'package:w_tools_ui_example/playground_preview.dart';
import 'package:w_tools_ui_example/playground_snippet.dart';

void main() {
  test('playground snippet 使用 options / slots 且包含尺寸', () {
    final snippet = buildPlaygroundSnippet(
      isNetwork: false,
      width: 320,
      height: 180,
      aspectRatio: null,
      fitName: 'cover',
      memCache: 240,
      radius: 12,
      withBorder: true,
      withShadow: false,
      customPlaceholder: true,
      retryCount: 0,
    );
    expect(snippet, contains('WImage.source('));
    expect(snippet, contains('options: WImageLoadOptions('));
    expect(snippet, contains('slots: WImageSlots('));
    expect(snippet, contains('width: 320'));
    expect(snippet, contains('border: Border.all'));
    expect(snippet, isNot(contains('config:')));
    expect(snippet, isNot(contains('controller:')));
    expect(snippet, contains('errorWidgetBuilder: (context, data, error, retry)'));
  });
  testWidgets('buildPlaygroundPreview 使用配置构造 WImage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: buildPlaygroundPreview(
          config: const PlaygroundConfig(
            isNetwork: false,
            width: 320,
            height: 180,
            aspectRatio: null,
            fit: BoxFit.cover,
            memCache: 240,
            radius: 12,
            retryCount: 1,
            customPlaceholder: true,
            withBorder: true,
            withShadow: false,
          ),
          onStatus: (_) {},
          onProgress: (_) {},
        ),
      ),
    );
    final image = tester.widget<WImage>(find.byType(WImage));
    expect(image.style.width, 320);
    expect(image.style.height, 180);
    expect(image.style.border, isNotNull);
    expect(image.options.retryCount, 1);
    expect(image.options.memCacheWidth, 240);
  });
}

// 预览配置与构建的拆分测试（先于实现添加）。
