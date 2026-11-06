import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui_example/playground_config.dart';
import 'package:w_tools_ui_example/playground_controls.dart';

void main() {
  testWidgets('切换 border 回传新 config', (tester) async {
    PlaygroundConfig? next;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
              child: PlaygroundControls(
            config: const PlaygroundConfig(),
            onChanged: (value) => next = value,
            onRetry: () {},
            status: null,
            progress: null,
          )),
        ),
      ),
    );

    await tester.tap(find.text('WImageStyle.border'));
    await tester.pump();
    expect(next?.withBorder, isTrue);
    expect(next?.width, 320);
  });
}
