import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui_example/main.dart';

Finder _navItem(String label) =>
    find.descendant(of: find.byType(WNavBar), matching: find.text(label));

int _index(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack).first).index!;

void main() {
  testWidgets('示例 App 能构建并显示导航', (tester) async {
    await tester.pumpWidget(const WUiExampleApp());
    expect(find.text('w_tools_ui 示例'), findsOneWidget);
    expect(find.byType(WNavBar), findsOneWidget);
  });

  testWidgets('每个页面都能切换并渲染', (tester) async {
    await tester.pumpWidget(const WUiExampleApp());
    expect(_index(tester), 0);

    const pages = <(String, int)>[
      ('状态矩阵', 1),
      ('常用配方', 2),
      ('按钮', 3),
      ('组件', 4),
      ('更多', 5),
    ];
    for (final (label, index) in pages) {
      await tester.tap(_navItem(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(_index(tester), index, reason: '切到「$label」');
    }

    await tester.tap(_navItem('Playground'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(_index(tester), 0);
    expect(find.text('asset'), findsOneWidget);
  });

  testWidgets('更多页能打开三级示例并返回', (tester) async {
    await tester.pumpWidget(const WUiExampleApp());

    await tester.tap(_navItem('更多'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    const demos = [
      'WScaffold / WAppBar / WScreen',
      'WText / WTextStyles',
      '扩展方法',
      'WListView / 通知 / keepAlive',
      'WNavBar / WNavController',
      'WStep',
    ];
    for (final title in demos) {
      await tester.scrollUntilVisible(
        find.text(title),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text(title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(title), findsOneWidget, reason: '打开「$title」');

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
  });

  testWidgets('Playground 代码面板使用 6.0 的 WImage.source', (tester) async {
    await tester.pumpWidget(const WUiExampleApp());

    final list = find.byType(ListView).first;
    await tester.scrollUntilVisible(
      find.text('当前代码'),
      300,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    await tester.pump();

    final snippet = tester.widget<SelectableText>(find.byType(SelectableText).first).data!;
    expect(snippet, contains('WImage.source('));
    expect(snippet, contains('WImageSource.'));
    expect(snippet, isNot(contains('WImage.network')));
    expect(snippet, isNot(contains('WImage.asset(')));
  });
}
