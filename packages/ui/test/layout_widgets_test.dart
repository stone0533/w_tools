import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
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

  testWidgets('WStep — 默认色跟随 ColorScheme（暗色）', (tester) async {
    final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: WStep(labels: ['下单', '付款'], current: 1),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(WStep), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, theme.colorScheme.primary);
  });

  testWidgets('WStep — completed / current / upcoming 默认状态', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WStep(
          current: 2,
          labels: ['A', 'B', 'C'],
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('WStep — WStepFlow.copyWith', (tester) async {
    final flow = WStepFlow(labels: const ['A', 'B', 'C']);
    final copy = flow.copyWith(labels: const ['X', 'Y']);

    await tester.pumpWidget(
      MaterialApp(
        home: copy.build(current: 2),
      ),
    );

    expect(find.text('X'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
    expect(copy.labels, isNot(same(flow.labels)));
  });

  testWidgets('WStep — itemSize 必须大于 0', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WStep(
          current: 1,
          labels: ['A'],
          style: WStepStyle(itemSize: 0),
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
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

  testWidgets('WScaffold — 接受任意 PreferredSizeWidget 作为 appBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WScaffold(
          appBar: AppBar(title: const Text('自定义顶栏')),
          body: const Text('body'),
        ),
      ),
    );
    expect(find.text('自定义顶栏'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
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

  test('WGradientCircularProgressIndicator — 默认背景色不由组件写死', () {
    const indicator = WGradientCircularProgressIndicator(
      radius: 12,
      colors: [Colors.red, Colors.orange],
    );
    expect(indicator.backgroundColor, isNull);
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

  testWidgets('WGradientCircularProgressIndicator — 语义进度会 clamp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [Colors.red, Colors.blue],
          value: 1.5,
          semanticsLabel: '加载中',
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '加载中' &&
            widget.properties.value == '100%',
      ),
      findsOneWidget,
    );
  });

  testWidgets('WGradientCircularProgressIndicator — 暴露进度语义', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [Colors.red, Colors.blue],
          value: 0.5,
          semanticsLabel: '加载中',
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '加载中' &&
            widget.properties.value == '50%',
      ),
      findsOneWidget,
    );
  });

  testWidgets('WGradientCircularProgressIndicator — value 非有限数断言', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [Colors.red, Colors.blue],
          value: double.nan,
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('WGradientCircularProgressIndicator — colors 为空断言', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('WGradientCircularProgressIndicator — stops 长度断言', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WGradientCircularProgressIndicator(
          radius: 40,
          colors: [Colors.red, Colors.blue],
          stops: [0.5],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('WNotificationListener — 通知与百分比同时生效', (tester) async {
    final notifications = <Notification>[];
    double? percentage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WNotificationListener<ScrollNotification>(
            onNotification: (notification) {
              notifications.add(notification);
              return false;
            },
            onNotificationPercentage: (value) => percentage = value,
            child: ListView(
              children: List.generate(
                50,
                (index) => SizedBox(height: 40, child: Text('$index')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(notifications.whereType<ScrollUpdateNotification>(), isNotEmpty);
    expect(percentage, isNotNull);
    expect(percentage, greaterThan(0));
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

  testWidgets('WAppBar — gradient / systemOverlayStyle / includeStatusBar: false', (tester) async {
    const overlay = SystemUiOverlayStyle.light;
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: Scaffold(
            body: WAppBar(
              title: '渐变',
              includeStatusBar: false,
              style: WAppBarStyle(
                gradient: LinearGradient(colors: [Colors.red, Colors.blue]),
                systemOverlayStyle: overlay,
              ),
            ),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(WAppBar), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.gradient, isNotNull);
    expect(decoration.color, isNull);
    expect(container.padding, EdgeInsets.zero);

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.descendant(
        of: find.byType(WAppBar),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
    );
    expect(region.value, overlay);
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

  testWidgets('WAppBar — 标题跟随 AppBarTheme.titleTextStyle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(fontSize: 26, color: Colors.green),
          ),
        ),
        home: const Scaffold(body: WAppBar(title: '标题')),
      ),
    );

    final title = tester.widget<Text>(find.text('标题'));
    expect(title.style?.fontSize, 26);
    expect(title.style?.color, Colors.green);
  });

  testWidgets('WAppBar — 无主题样式时标题用 titleLarge，而不是正文样式', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WAppBar(title: '标题')),
      ),
    );

    final element = tester.element(find.text('标题'));
    final title = tester.widget<Text>(find.text('标题'));
    expect(title.style, Theme.of(element).textTheme.titleLarge);
  });

  testWidgets('WAppBar — 图标继承 ThemeData.iconTheme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(iconTheme: const IconThemeData(color: Colors.red)),
        home: Scaffold(
          body: WAppBar(title: '标题', onBack: () {}),
        ),
      ),
    );

    final backButton = tester.element(find.byType(BackButton));
    expect(IconTheme.of(backButton).color, Colors.red);
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
    // 8.0 起 copyWith 的 null 表示保留，不能再用它清空字段。
    expect(next.titleSpacing, 8);
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

  group('WStepStyle copyWith', () {
    test('传 null 表示保留，未传同样保留', () {
      const style = WStepStyle(
        labelStyle: TextStyle(fontSize: 12),
        completedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      );

      final kept = style.copyWith(
        labelStyle: null,
        completedLabelStyle: null,
        itemSize: 32,
      );
      expect(kept.labelStyle, style.labelStyle);
      expect(kept.completedLabelStyle, style.completedLabelStyle);
      expect(kept.itemSize, 32);
    });
  });

  test('WStepStyle.resolve 按 ColorScheme 兜底', () {
    final scheme = ThemeData.light().colorScheme;
    final resolved = const WStepStyle().resolve(scheme);
    expect(resolved.completed, scheme.primary);
    expect(resolved.current, scheme.primary);
    expect(resolved.upcoming, scheme.outline);

    final custom = const WStepStyle(
      completedColor: Colors.green,
      currentColor: Colors.orange,
      upcomingColor: Colors.grey,
    ).resolve(scheme);
    expect(custom.completed, Colors.green);
    expect(custom.current, Colors.orange);
    expect(custom.upcoming, Colors.grey);
  });
  testWidgets('WScaffold appBar 与便捷参数互斥', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WScaffold(
          appBar: WAppBar(title: 'A'),
          title: 'B',
          body: SizedBox.shrink(),
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
