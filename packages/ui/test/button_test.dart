import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('WButton 变体与 Material 集成', () {
    testWidgets('四种变体分别渲染 Material 按钮', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WButton(label: 'filled', onTap: () {}),
              WButton(
                variant: WButtonVariant.outlined,
                label: 'outlined',
                onTap: () {},
              ),
              WButton(variant: WButtonVariant.text, label: 'text', onTap: () {}),
              WButton(variant: WButtonVariant.danger, label: 'danger', onTap: () {}),
            ],
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('点击触发 onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(WButton(label: '保存', onTap: () => taps++)));
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('长按触发 onLongPress', (tester) async {
      var longs = 0;
      await tester.pumpWidget(
        _wrap(WButton(label: '长按', onLongPress: () => longs++)),
      );
      await tester.longPress(find.text('长按'));
      await tester.pumpAndSettle();
      expect(longs, 1);
    });

    testWidgets('键盘 Enter 触发 onTap', (tester) async {
      var taps = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(WButton(label: '键盘', focusNode: focusNode, onTap: () => taps++)),
      );
      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('未传 style 时使用 ColorScheme.primary', (tester) async {
      await tester.pumpWidget(_wrap(WButton(label: '主按钮', onTap: () {})));
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      final scheme = Theme.of(tester.element(find.byType(FilledButton))).colorScheme;
      expect(style.backgroundColor?.resolve({}), scheme.primary);
      expect(style.foregroundColor?.resolve({}), scheme.onPrimary);
    });

    testWidgets('danger 使用 ColorScheme.error', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(variant: WButtonVariant.danger, label: '删除', onTap: () {})),
      );
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      final scheme = Theme.of(tester.element(find.byType(FilledButton))).colorScheme;
      expect(style.backgroundColor?.resolve({}), scheme.error);
    });
  });

  group('WButton 内容', () {
    testWidgets('label + icon 使用 WIconText', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(icon: Icons.add, label: '新增', onTap: () {})),
      );
      expect(find.byType(WIconText), findsOneWidget);
    });

    testWidgets('content 支持静态复杂内容', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.star), SizedBox(width: 4), Text('复杂内容')],
            ),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('复杂内容'), findsOneWidget);
    });

    testWidgets('content 与 label/icon 互斥', (tester) async {
      expect(
        () => WButton(content: const Text('x'), label: 'y', onTap: () {}),
        throwsAssertionError,
      );
      expect(
        () => WButton(onTap: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('纯图标按钮要求 semanticLabel', (tester) async {
      expect(
        () => WButton(icon: Icons.close, onTap: () {}),
        throwsAssertionError,
      );
      await tester.pumpWidget(
        _wrap(
          WButton(icon: Icons.close, semanticLabel: '关闭', onTap: () {}),
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('WButton 状态', () {
    testWidgets('loading 阻止点击、显示 spinner 并保持尺寸', (tester) async {
      var taps = 0;
      Widget build({required bool loading}) => _wrap(
        WButton(label: '提交', loading: loading, onTap: () => taps++),
      );
      await tester.pumpWidget(build(loading: false));
      final normalSize = tester.getSize(find.byType(FilledButton));

      await tester.pumpWidget(build(loading: true));
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)), normalSize);
      expect(find.text('提交'), findsOneWidget);
    });

    testWidgets('loading 语义是 liveRegion，默认英文文案', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(label: '提交', loading: true, onTap: () {})),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              widget.properties.label == 'Loading',
        ),
        findsOneWidget,
      );
    });

    testWidgets('loadingLabel 覆盖默认文案', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '提交',
            loading: true,
            loadingLabel: '正在提交',
            onTap: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('正在提交'), findsOneWidget);
    });

    testWidgets('禁用时不触发点击', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(WButton(label: '禁用', enabled: false, onTap: () => taps++)),
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });

    testWidgets('禁用按钮可以不提供回调', (tester) async {
      await tester.pumpWidget(_wrap(const WButton(label: '禁用', enabled: false)));
      expect(find.text('禁用'), findsOneWidget);
    });

    testWidgets('isSelected 进入 Semantics', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(label: '标签', isSelected: true, onTap: () {})),
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.selected == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('semanticLabel / hint 覆盖内容朗读', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '❤',
            semanticLabel: '收藏',
            semanticHint: '双击收藏',
            onTap: () {},
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.label == '收藏' &&
              widget.properties.hint == '双击收藏',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tooltip 包一层 Tooltip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            icon: Icons.favorite,
            semanticLabel: '收藏',
            tooltip: '收藏',
            onTap: () {},
          ),
        ),
      );
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, '收藏');
    });
  });

  group('WButton 尺寸与主题', () {
    testWidgets('WButtonSize 映射到最小尺寸与内边距', (tester) async {
      await tester.pumpWidget(
        _wrap(WButton(size: WButtonSize.small, label: '小', onTap: () {})),
      );
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.minimumSize?.resolve({}), const Size(48, 32));
      expect(
        style.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );
      expect(style.tapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('单按钮 style 的 padding 覆盖 WButtonSize', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '自定义',
            style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
            onTap: () {},
          ),
        ),
      );
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.padding?.resolve({}), EdgeInsets.zero);
    });

    testWidgets('WButtonTheme 覆盖默认样式', (tester) async {
      final theme = ThemeData(
        useMaterial3: true,
        extensions: const [
          WButtonTheme(
            filled: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFFFF0000)),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          WButton(label: '主题', onTap: () {}),
          theme: theme,
        ),
      );
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.backgroundColor?.resolve({}), const Color(0xFFFF0000));
    });

    testWidgets('单按钮 style 覆盖主题', (tester) async {
      final theme = ThemeData(
        useMaterial3: true,
        extensions: const [
          WButtonTheme(
            filled: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFFFF0000)),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          WButton(
            label: '覆盖',
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFF00FF00)),
            ),
            onTap: () {},
          ),
          theme: theme,
        ),
      );
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.backgroundColor?.resolve({}), const Color(0xFF00FF00));
    });

    testWidgets('暗色主题 / RTL / 大字号下可构建', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WButton(icon: Icons.add, label: '构建', onTap: () {}),
          theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        ),
      );
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: WButton(icon: Icons.add, label: '构建', onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
