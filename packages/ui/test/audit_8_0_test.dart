import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

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

  testWidgets('WButtonStyles.of 返回命名类型 WButtonStyleSet', (tester) async {
    late WButtonStyleSet set;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            set = WButtonStyles.of(context);
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
}
