import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
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

  testWidgets('WStep — 默认显示 1 基 label / 状态', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WStep(
          current: 1,
          labels: ['One', 'Two', 'Three'],
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('WStep — itemBuilder / separatorBuilder 使用 1 基索引', (tester) async {
    final states = <int, WStepState>{};
    final separators = <int, bool>{};

    await tester.pumpWidget(
      MaterialApp(
        home: WStep(
          current: 2,
          labels: const ['A', 'B', 'C'],
          itemBuilder: (context, index, state) {
            states[index] = state;
            return Text('item-$index');
          },
          separatorBuilder: (context, index, completed) {
            separators[index] = completed;
            return const SizedBox(height: 2);
          },
        ),
      ),
    );

    expect(states, {
      1: WStepState.completed,
      2: WStepState.current,
      3: WStepState.upcoming,
    });
    expect(separators, {
      1: true,
      2: false,
    });
  });

  testWidgets('WStep — WStepFlow 复用流程定义', (tester) async {
    final flow = WStepFlow(
      labels: ['A', 'B', 'C'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: flow.build(current: 3),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(() => flow.labels.add('D'), throwsUnsupportedError);
  });

  testWidgets('WStep — semanticLabelBuilder 自定义语义标签', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WStep(
          current: 2,
          labels: const ['A', 'B', 'C'],
          semanticLabelBuilder: (current, total) => '第 $current 步，共 $total 步',
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '第 2 步，共 3 步',
      ),
      findsOneWidget,
    );
  });

  test('WStepStyle — copyWith 返回新实例', () {
    const style = WStepStyle(itemSize: 30);
    final copy = style.copyWith(itemSize: 40, completedColor: Colors.green);
    expect(copy.itemSize, 40);
    expect(copy.completedColor, Colors.green);
    expect(style.itemSize, 30);
  });

  testWidgets('WStep — current 越界断言', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WStep(
          current: 4,
          labels: ['A', 'B', 'C'],
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('WStep — labels 为空断言', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WStep(
          current: 1,
          labels: [],
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
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

    final wrapper = WNotificationListenerBuilder<ScrollNotification>(
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

  testWidgets('WAppBar — 默认高度与无 canPop 时不显示返回', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WAppBar(titleWidget: Text('my bar')),
        ),
      ),
    );

    expect(find.text('my bar'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(tester.getSize(find.byType(NavigationToolbar)).height, 56);
  });

  testWidgets('WAppBar — onBack 显示标准返回按钮', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WAppBar(
            titleWidget: const Text('my bar'),
            onBack: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(taps, 1);
  });

  testWidgets('WAppBar — actions 列表与 title 不重叠', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WAppBar(
            title: '标题',
            actions: [
              Icon(Icons.search),
              SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );

    expect(find.text('标题'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  test('WAppBar — contentHeight 不含状态栏', () {
    const bar = WAppBar(title: '标题');
    expect(bar.contentHeight, 56);
  });

  testWidgets('WScaffold — title 自动生成默认 AppBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          title: '标题',
          body: Text('body'),
        ),
      ),
    );

    expect(find.text('标题'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('WScaffold — appBar 覆盖默认顶部栏', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          appBar: WAppBar(title: '自定义'),
          body: Text('body'),
        ),
      ),
    );

    expect(find.text('自定义'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('WScaffold — 状态栏只计算一次', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: WScaffold(
            title: '标题',
            body: Text('body'),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('body')).dy, 80);
  });

  testWidgets('WScaffold — appBar 覆盖时状态栏只计算一次', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: WScaffold(
            appBar: WAppBar(title: '自定义'),
            body: Text('body'),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('body')).dy, 80);
  });

  testWidgets('WScaffold — appBar 覆盖可自定义 centerTitle / 返回', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          appBar: WAppBar(
            title: '自定义',
            centerTitle: false,
            automaticallyImplyLeading: false,
          ),
          body: Text('body'),
        ),
      ),
    );

    expect(find.text('自定义'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('WScaffold — appBarBottom 会触发默认 AppBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          appBarBottom: PreferredSize(
            preferredSize: Size.fromHeight(20),
            child: Text('tab'),
          ),
          body: Text('body'),
        ),
      ),
    );

    expect(find.text('tab'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  test('WAppBarStyle — copyWith / validate', () {
    const style = WAppBarStyle(height: 56, titleSpacing: 8);
    final next = style.copyWith(height: 64, titleSpacing: null);
    expect(next.height, 64);
    expect(next.titleSpacing, isNull);
    expect(() => style.copyWith(height: -1).validate(), throwsAssertionError);
    expect(
      () => const WAppBarStyle(
        backgroundColor: Colors.white,
        gradient: LinearGradient(colors: [Colors.red, Colors.blue]),
      ).validate(),
      throwsAssertionError,
    );
    expect(
      () => style.copyWith(titleSpacing: -1.0).validate(),
      throwsAssertionError,
    );
  });

  testWidgets('WScaffold — 无 AppBar 时使用 MediaQuery 顶部安全区', (tester) async {
    final data = MediaQueryData.fromView(tester.view).copyWith(
      padding: const EdgeInsets.only(top: 24),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: data,
          child: const WScaffold(
            includeTopSafeArea: true,
            body: Align(
              alignment: Alignment.topCenter,
              child: Text('body'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('body')).dy, 24);
  });

  testWidgets('WScaffold — 无 bottomNavigationBar 时 body 加底部安全区', (tester) async {
    final data = MediaQueryData.fromView(tester.view).copyWith(
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: data,
          child: const WScaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Text('body'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getBottomLeft(find.text('body')).dy, 580);
  });

  testWidgets('WScaffold — 有 bottomNavigationBar 时 body 不重复加底部安全区', (tester) async {
    final data = MediaQueryData.fromView(tester.view).copyWith(
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: data,
          child: const WScaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Text('body'),
            ),
            bottomNavigationBar: SizedBox(
              height: 40,
              child: Text('nav'),
            ),
          ),
        ),
      ),
    );

    expect(tester.getBottomLeft(find.text('body')).dy, 560);
  });

  testWidgets('WScaffold — appBarBottom 高度包含状态栏', (tester) async {
    final data = MediaQueryData.fromView(tester.view).copyWith(
      padding: const EdgeInsets.only(top: 24),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: data,
          child: const WScaffold(
            appBarBottom: PreferredSize(
              preferredSize: Size.fromHeight(20),
              child: Text('tab'),
            ),
            body: Text('body'),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.text('body')).dy, 100);
  });

  testWidgets('WScaffold — 空标题不创建 AppBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          title: '',
          body: Text('body'),
        ),
      ),
    );

    expect(find.byType(NavigationToolbar), findsNothing);
  });

  testWidgets('WScaffold — onBack 优先于 automaticallyImplyLeading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WScaffold(
          title: '标题',
          automaticallyImplyLeading: false,
          onBack: () => taps++,
          body: const Text('body'),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(taps, 1);
  });

  testWidgets('WScaffold — 支持 bottomNavigationBar / floatingActionButton', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          title: '标题',
          body: Text('body'),
          bottomNavigationBar: Text('nav'),
          floatingActionButton: FloatingActionButton(onPressed: null),
        ),
      ),
    );

    expect(find.text('nav'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
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
