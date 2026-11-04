import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
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
    testWidgets('ClipRRect 正确包裹 child', (tester) async {
      final config = WClipRRectConfig.all(12);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WClipRRect(
              config: config,
              child: const Text('rounded'),
            ),
          ),
        ),
      );
      expect(find.text('rounded'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('WClipRRect 支持 clipBehavior', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WClipRRect(
              config: WClipRRectConfig(),
              clipBehavior: Clip.hardEdge,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.clipBehavior, Clip.hardEdge);
    });

    testWidgets('WClipRRect 默认 clipBehavior 为 antiAlias', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WClipRRect(
              config: WClipRRectConfig(),
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.clipBehavior, Clip.antiAlias);
    });

    test('WClipRRectConfig.all / copyWith 设置圆角', () {
      final config = WClipRRectConfig.all(8);
      expect(config.borderRadius, BorderRadius.circular(8));
      expect(
        config.copyWith(borderRadius: BorderRadius.circular(4)).borderRadius,
        BorderRadius.circular(4),
      );
    });

    testWidgets('config 默认 borderRadius 为 BorderRadius.zero', (tester) async {
      const config = WClipRRectConfig();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WClipRRect(config: config, child: SizedBox.shrink()),
          ),
        ),
      );
      // ClipRRect 存在说明 build 正常
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });

  group('WBadge Widget', () {
    testWidgets('渲染 badgeContent', (tester) async {
      const config = WBadgeConfig();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WBadge(
              config: config,
              badgeContent: const Text('3'),
              child: const Icon(Icons.email),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('显示徽章时 badgeContent 不能为空', (tester) async {
      expect(
        () => WBadge(
          config: const WBadgeConfig(),
          child: const Icon(Icons.notifications),
        ),
        throwsAssertionError,
      );
      expect(
        () => WBadge(
          config: const WBadgeConfig(showBadge: false),
          child: const Icon(Icons.notifications),
        ),
        returnsNormally,
      );
    });

    test('copyWith 可恢复显示', () {
      const config = WBadgeConfig(showBadge: false);
      expect(config.isShown, isFalse);
      expect(config.copyWith(showBadge: true).isShown, isTrue);
    });

    testWidgets('badgeStyle 可配置', (tester) async {
      const config = WBadgeConfig(
        badgeStyle: badges.BadgeStyle(
          badgeColor: Colors.red,
          padding: EdgeInsets.all(4),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WBadge(
              config: config,
              badgeContent: const Text('3'),
              child: const Icon(Icons.notifications),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hideBadge() 隐藏徽章', (tester) async {
      const config = WBadgeConfig(showBadge: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WBadge(
              config: config,
              badgeContent: const Text('hidden'),
              child: const Icon(Icons.notifications),
            ),
          ),
        ),
      );

      // badges 包在 showBadge=false 时并非移除内容，而是把它渲染为完全透明
      // （FadeTransition/Opacity 为 0，widget 仍留在树中），
      // 因此断言「内容处于不可见状态」，而非 findsNothing。
      bool hidden = false;
      tester.element(find.text('hidden')).visitAncestorElements((element) {
        final widget = element.widget;
        if (widget is FadeTransition && widget.opacity.value == 0) {
          hidden = true;
        } else if (widget is Opacity && widget.opacity == 0) {
          hidden = true;
        }
        return !hidden; // 命中即停止继续向上遍历
      });
      expect(hidden, isTrue);

      // child 仍在
      expect(find.byIcon(Icons.notifications), findsOneWidget);
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
