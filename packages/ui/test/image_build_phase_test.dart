import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

void main() {
  testWidgets('build 期 markLoading 延迟到 post-frame，不抛 setState during build', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WImage(source: WImageSource.base64(_redPixel)),
      ),
    );

    // 首帧 build 时 frameBuilder 会走 _load.markLoading()；
    // _scheduleRebuild 必须把 setState 推到 post-frame。
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
