import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  testWidgets('WContainer — 渲染 child（config 必填）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WContainer(
          config: WContainerConfig(),
          child: const Text('content'),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('WRichText — 渲染 RichText（itemBuilder 返回 TextSpan）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WRichText(
          config: WRichTextConfig(),
          data: const ['hello', 'world'],
          itemBuilder: (_, idx, s, cfg) => TextSpan(text: '$idx:$s'),
        ),
      ),
    );
    // RichText 会把 TextSpan.text 渲染到屏幕
    expect(find.byType(RichText), findsOneWidget);
  });

  testWidgets('WRichText — 未配置时跟随系统字体缩放', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: WRichText(
            config: WRichTextConfig(),
            data: const ['hello'],
            itemBuilder: (_, idx, s, cfg) => TextSpan(text: s),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.textScaler, const TextScaler.linear(2));
  });

  testWidgets('WStep — 渲染（config 必填）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WStep(config: WStepConfig()..length = 3),
      ),
    );
    expect(find.byType(WStep), findsOneWidget);
  });

  testWidgets('WScaffold — 渲染 body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WScaffold(body: Text('body content'))),
    );
    expect(find.text('body content'), findsOneWidget);
  });

  testWidgets('WKeepAliveWrapper — 渲染 child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WKeepAliveWrapper(child: Text('alive'))),
    );
    expect(find.text('alive'), findsOneWidget);
  });

  testWidgets('WGradientCircularProgressIndicator — 渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [Colors.red, Colors.blue],
        ),
      ),
    );
    expect(find.byType(WGradientCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WNotificationListenerBuilder — build() 返回 NotificationListener', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WNotificationListenerBuilder<ScrollNotification>(
          child: const Text('listening'),
        ).build(),
      ),
    );
    expect(find.text('listening'), findsOneWidget);
  });

  testWidgets('WNotificationListenerBuilder — 链式 onNotification 可用', (tester) async {
    final wrapper = WNotificationListenerBuilder<ScrollNotification>(
      child: const Text('listen'),
    ).onNotification((_) => true);

    await tester.pumpWidget(MaterialApp(home: wrapper.build()));
    expect(find.text('listen'), findsOneWidget);
  });

  testWidgets('WNotificationListenerBuilder — 自定义回调与百分比可同时生效', (tester) async {
    var notifications = 0;
    double? percentage;

    final wrapper =
        WNotificationListenerBuilder<ScrollNotification>(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(height: 20, child: Text('row-$i')),
              ),
            ),
          )
          ..onNotification((_) {
            notifications++;
            return false;
          })
          ..onNotificationPercentage((value) => percentage = value);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper.build())));
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();

    expect(notifications, greaterThan(0));
    expect(percentage, isNotNull);
    expect(percentage!.isNaN, isFalse);
    expect(percentage, inInclusiveRange(0.0, 1.0));
  });

  test('WGradientCircularProgressIndicator — strokeWidth 不小于直径时断言失败', () {
    expect(
      () => WGradientCircularProgressIndicator(
        radius: 1,
        strokeWidth: 2,
        colors: const [Colors.red],
      ),
      throwsAssertionError,
    );
  });

  testWidgets('WAppBar — 默认返回图标与语义', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 56,
            child: WAppBar(titleWidget: Text('my bar')),
          ),
        ),
      ),
    );

    expect(find.text('my bar'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    final backSemantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .firstWhere((s) => s.properties.button == true && s.properties.label != null);
    expect(backSemantics.properties.label, isNotNull);
  });

  testWidgets('WAppBar — 单独渲染（不是 PreferredSizeWidget）', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 56,
            child: WAppBar(titleWidget: Text('my bar')),
          ),
        ),
      ),
    );
    expect(find.text('my bar'), findsOneWidget);
  });

  group('GlobalKey 扩展', () {
    testWidgets('rect() 返回全局坐标矩形（回归：曾返回局部 paintBounds）', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 50, top: 30),
              child: SizedBox(key: key, width: 100, height: 40),
            ),
          ),
        ),
      );

      final offset = key.offset();
      final rect = key.rect();

      expect(offset, isNotNull);
      expect(rect, isNotNull);
      // 全局坐标：矩形左上角应与 offset() 一致（若为局部坐标则恒为 Offset.zero）
      expect(rect!.topLeft, offset);
      expect(rect.size, const Size(100, 40));
    });

    testWidgets('未挂载时 offset()/rect() 返回 null', (tester) async {
      final key = GlobalKey();
      expect(key.offset(), isNull);
      expect(key.rect(), isNull);
    });
  });
}
