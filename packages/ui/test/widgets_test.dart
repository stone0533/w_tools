import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

void main() {
  group('WText Widget', () {
    testWidgets('渲染文本内容', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WText(text: 'Hello')),
        ),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('默认渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WText(text: 'default')),
        ),
      );
      expect(find.text('default'), findsOneWidget);
    });

    testWidgets('variant 使用 WTextStyles 主题', (tester) async {
      final styles = WTextStyles.fromTextTheme(ThemeData.light().textTheme).copyWith(
        body: const TextStyle(fontSize: 42, color: Colors.green),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [styles]),
          home: const Scaffold(
            body: WText(text: 'semantic', variant: WTextVariant.body),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('semantic'));
      expect(text.style?.fontSize, 42);
      expect(text.style?.color, Colors.green);
    });

    testWidgets('style / color 可覆盖 variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WText(
              text: 'override',
              variant: WTextVariant.body,
              color: Colors.red,
              style: TextStyle(fontSize: 19),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('override'));
      expect(text.style?.color, Colors.red);
      expect(text.style?.fontSize, 19);
    });

    testWidgets('支持 maxLines / softWrap / textScaler', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WText(
              text: 'standard text props',
              variant: WTextVariant.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              softWrap: false,
              textScaler: TextScaler.linear(1.5),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('standard text props'));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.textAlign, TextAlign.center);
      expect(text.softWrap, isFalse);
      expect(text.textScaler, const TextScaler.linear(1.5));
    });

    testWidgets('有显式字体信息时生成 strutStyle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WText(
              text: 'strut',
              style: TextStyle(fontSize: 40, height: 1.2),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('strut'));
      expect(text.strutStyle?.fontSize, 40);
      expect(text.strutStyle?.height, 1.2);
      expect(text.strutStyle?.forceStrutHeight, isTrue);
    });

    testWidgets('默认不设置 strutStyle（避免裁切继承字号）', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WText(text: 'no-strut')),
        ),
      );
      final text = tester.widget<Text>(find.text('no-strut'));
      expect(text.strutStyle, isNull);
    });
  });

  group('WClipRRect Widget', () {
    testWidgets('渲染并应用 borderRadius', (tester) async {
      const radius = BorderRadius.all(Radius.circular(12));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WClipRRect(
              borderRadius: radius,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, radius);
      expect(clip.clipBehavior, Clip.antiAlias);
    });

    testWidgets('支持 clipBehavior', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WClipRRect(
              borderRadius: BorderRadius.zero,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).clipBehavior, Clip.hardEdge);
    });
  });

  group('WBadge Widget', () {
    testWidgets('渲染 badgeContent 与 child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WBadge(
              badgeContent: Text('3'),
              child: Icon(Icons.email),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('默认样式跟随 ColorScheme.error / onError', (tester) async {
      final theme = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: WBadge(badgeContent: Text('9'), child: Icon(Icons.email)),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(WBadge), matching: find.byType(DecoratedBox)).last,
      );
      expect((box.decoration as BoxDecoration).color, theme.colorScheme.error);
    });

    testWidgets('自定义 position / style / showBadge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WBadge(
              position: WBadgePosition.topEnd(top: 1, end: 2),
              style: WBadgeStyle(backgroundColor: Colors.red),
              showBadge: false,
              badgeContent: Text('9'),
              child: Icon(Icons.email),
            ),
          ),
        ),
      );
      expect(find.text('9'), findsNothing);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('badgeContent 为空时不渲染徽章', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WBadge(child: Icon(Icons.notifications))),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('position.center 覆盖在 child 上', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WBadge(
              position: WBadgePosition.center(),
              badgeContent: Text('NEW'),
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      expect(find.text('NEW'), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets);
    });
  });

  group('WKeepAliveWrapper', () {
    testWidgets('keepAlive 由 true 变为 false 后，滚出屏幕的子树被回收（回归）', (tester) async {
      int initCount = 0;
      int disposeCount = 0;

      Widget buildTree({required bool keepAlive}) => MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemExtent: 100,
            itemCount: 30,
            itemBuilder: (context, index) {
              if (index != 0) {
                return Text('item $index');
              }
              return WKeepAliveWrapper(
                keepAlive: keepAlive,
                child: _KeepAliveProbe(
                  onInit: () => initCount++,
                  onDispose: () => disposeCount++,
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(buildTree(keepAlive: true));
      expect(initCount, 1);

      // 滚离屏幕（超出默认 cacheExtent）：保活生效，子树未被销毁
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(disposeCount, 0);
      expect(find.byType(_KeepAliveProbe, skipOffstage: false), findsOneWidget);

      // 关闭保活 → didUpdateWidget → updateKeepAlive() → 释放保活，子树被回收
      await tester.pumpWidget(buildTree(keepAlive: false));
      await tester.pumpAndSettle();
      expect(disposeCount, 1);
      expect(find.byType(_KeepAliveProbe, skipOffstage: false), findsNothing);
    });
  });

  test('WBadgePosition / WBadgeStyle 值相等', () {
    expect(
      const WBadgePosition.topEnd(top: 1, end: 2),
      const WBadgePosition.topEnd(top: 1, end: 2),
    );
    expect(const WBadgePosition.center(), const WBadgePosition.center());
    expect(
      const WBadgeStyle(backgroundColor: Colors.red),
      const WBadgeStyle(backgroundColor: Colors.red),
    );
  });

  testWidgets('GlobalKey.rect() 对未布局的 RenderBox 返回 null', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _NoLayoutBox(
          child: SizedBox(key: key, width: 10, height: 10),
        ),
      ),
    );

    expect(key.rect(), isNull);
    expect(tester.takeException(), isNull);
  });
}

/// 保活探针：记录 initState / dispose 次数，用于断言子树是否被保活
class _KeepAliveProbe extends StatefulWidget {
  const _KeepAliveProbe({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_KeepAliveProbe> createState() => _KeepAliveProbeState();
}

class _KeepAliveProbeState extends State<_KeepAliveProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 100);
}

class _NoLayoutBox extends SingleChildRenderObjectWidget {
  const _NoLayoutBox({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoLayout();
}

class _RenderNoLayout extends RenderProxyBox {
  @override
  void performLayout() {
    size = constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}
