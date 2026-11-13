import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _emptyItemBuilder(BuildContext context, int index) => const SizedBox.shrink();

void main() {
  test('WScreenData 值相等', () {
    expect(
      const WScreenData(size: Size(390, 844), padding: EdgeInsets.zero),
      const WScreenData(size: Size(390, 844), padding: EdgeInsets.zero),
    );
  });

  test('WStepStyle.resolve 返回命名类型 WStepColors', () {
    const scheme = ColorScheme.light();
    final colors = const WStepStyle().resolve(scheme);
    expect(colors, isA<WStepColors>());
    expect(colors.completed, scheme.primary);
    expect(colors.upcoming, scheme.outline);
  });

  testWidgets('WButtonStyleSet.of 返回命名类型 WButtonStyleSet', (tester) async {
    late WButtonStyleSet set;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            set = WButtonStyleSet.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(set.primary, isA<WButtonStyle>());
    expect(set.secondary, isA<WButtonStyle>());
    expect(set.text, isA<WButtonStyle>());
    expect(set.danger, isA<WButtonStyle>());
  });

  testWidgets('WButton 支持 motion / semantics 参数', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: WButton(
          label: '保存',
          motion: const WButtonMotion(effect: WPressEffect.scale),
          semantics: const WButtonSemantics(label: '保存按钮'),
          onTap: () {},
        ),
      ),
    );
    expect(tester.getSemantics(find.byType(WButton)).label, contains('保存按钮'));
    handle.dispose();
  });

  testWidgets('WBadge 默认使用 ColorScheme.error / onError', (tester) async {
    final theme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const WBadge(
          badgeContent: Text('3'),
          child: Icon(Icons.notifications),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(WBadge), matching: find.byType(DecoratedBox)).last,
    );
    expect((box.decoration as BoxDecoration).color, theme.colorScheme.error);

    final rich = tester.widget<RichText>(
      find.descendant(of: find.text('3'), matching: find.byType(RichText)),
    );
    expect(rich.text.style?.color, theme.colorScheme.onError);
  });

  testWidgets('WBadge 支持自有 position / style 类型', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WBadge(
          position: WBadgePosition.center(),
          style: WBadgeStyle(backgroundColor: Colors.green),
          badgeContent: Text('NEW'),
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    expect(find.text('NEW'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(WBadge), matching: find.byType(DecoratedBox)).last,
    );
    expect((box.decoration as BoxDecoration).color, Colors.green);
  });

  testWidgets('WStep 默认语义标签不写死英文', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: WStep(labels: ['下单', '付款'], current: 1)),
    );
    final label = tester.getSemantics(find.byType(WStep)).label;
    expect(label, contains('1/2'));
    expect(label, isNot(contains('Step')));
    handle.dispose();
  });

  testWidgets('WScreen.of 与静态 getter 在测试视图一致', (tester) async {
    late WScreenData data;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            data = WScreen.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(data.width, WScreen.screenWidth);
    expect(data.height, WScreen.screenHeight);
    expect(data.statusBarHeight, WScreen.statusBarHeight);
  });

  testWidgets('WTabBar 只用 style 构建', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 1,
          child: WTabBar(
            style: WTabBarStyle(isScrollable: true),
            tabs: [Tab(text: '全部')],
          ),
        ),
      ),
    );
    expect(find.byType(WTabBar), findsOneWidget);
  });

  testWidgets('WNotificationListener 是唯一通知入口', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WNotificationListener<ScrollNotification>(
          onNotificationPercentage: (_) {},
          child: ListView(children: const [SizedBox(height: 1000)]),
        ),
      ),
    );
    expect(find.byType(WNotificationListener<ScrollNotification>), findsOneWidget);
  });

  testWidgets('UI-021: WStep / WListView 的 const 用法仍然成立', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WStep(labels: ['a', 'b'], current: 1)),
    );
    expect(find.byType(WStep), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WListView(
            sliver: WListViewSliver.list(itemCount: 0, itemBuilder: _emptyItemBuilder),
          ),
        ),
      ),
    );
    expect(find.byType(WListView), findsOneWidget);
  });

  testWidgets('WAppBar 标题优先 WTextStyles.title', (tester) async {
    const styles = WTextStyles(
      display: TextStyle(fontSize: 1),
      headline: TextStyle(fontSize: 2),
      title: TextStyle(fontSize: 42),
      body: TextStyle(),
      bodyStrong: TextStyle(),
      caption: TextStyle(),
      label: TextStyle(),
      button: TextStyle(),
      price: TextStyle(),
      number: TextStyle(),
      badge: TextStyle(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData().withWTextStyles(styles),
        home: const Scaffold(appBar: WAppBar(title: '标题')),
      ),
    );
    expect(tester.widget<Text>(find.text('标题')).style?.fontSize, 42);
  });

  testWidgets('WStep 标签默认跟随 textTheme.bodySmall', (tester) async {
    final base = ThemeData.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: base.copyWith(
          textTheme: base.textTheme.copyWith(bodySmall: const TextStyle(fontSize: 9)),
        ),
        home: const WStep(labels: ['a'], current: 1),
      ),
    );
    expect(tester.widget<Text>(find.text('a')).style?.fontSize, 9);
  });

  testWidgets('WBadge topEnd 与 center 的位置不同', (tester) async {
    Widget app(Widget badge) => MaterialApp(home: Center(child: badge));

    await tester.pumpWidget(
      app(const WBadge(badgeContent: Text('3'), child: SizedBox(width: 40, height: 40))),
    );
    final topEnd = tester.getCenter(find.text('3'));

    await tester.pumpWidget(
      app(
        const WBadge(
          position: WBadgePosition.center(),
          badgeContent: Text('3'),
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    final center = tester.getCenter(find.text('3'));

    expect(center.dx, lessThan(topEnd.dx));
    expect(center.dy, greaterThan(topEnd.dy));
  });
}
