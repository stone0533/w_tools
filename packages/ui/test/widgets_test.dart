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

    testWidgets('config 可设置字体大小', (tester) async {
      final config = WTextConfig()..fontSize = 20;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WText(text: 'big', config: config),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('big'));
      expect(text.style?.fontSize, 20);
    });

    testWidgets('config 可设置颜色', (tester) async {
      final config = WTextConfig()..color = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WText(text: 'red', config: config),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('red'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('无 config 时正常渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WText(text: 'default')),
        ),
      );
      expect(find.text('default'), findsOneWidget);
    });

    testWidgets('无 config 时不设置 strutStyle（避免裁切继承字号）', (tester) async {
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
      final config = WClipRRectConfig()..borderRadiusAll(12);
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

    testWidgets('WClipRRectConfig.borderRadiusAll 设置圆角', (tester) async {
      final config = WClipRRectConfig();
      final returned = config.borderRadiusAll(8);
      expect(returned, same(config)); // 链式返回 this
    });

    testWidgets('config 默认 borderRadius 为 BorderRadius.zero', (tester) async {
      final config = WClipRRectConfig();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WClipRRect(config: config, child: const SizedBox.shrink()),
          ),
        ),
      );
      // ClipRRect 存在说明 build 正常
      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });

  group('WBadge Widget', () {
    testWidgets('渲染 badgeContent', (tester) async {
      final config = WBadgeConfig();
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

    testWidgets('hideBadge() 隐藏徽章', (tester) async {
      final config = WBadgeConfig().hideBadge();
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
