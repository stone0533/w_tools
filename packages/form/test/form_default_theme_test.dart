import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 默认值必须能用：不传 borderConfig 时也要有主题边框、message 与校验错误可见。
void main() {
  testWidgets('不传 borderConfig：默认边框来自主题，message 可见', (tester) async {
    final theme = ThemeData(useMaterial3: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(name: 'email', label: '邮箱', message: '请输入邮箱'),
          ),
        ),
      ),
    );

    expect(find.text('请输入邮箱'), findsOneWidget);

    // 边框装饰来自主题（surface 底 + outlineVariant 边）
    final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    final outer = decorated.firstWhere(
      (w) => (w.decoration as BoxDecoration?)?.border != null,
      orElse: () => const DecoratedBox(decoration: BoxDecoration()),
    );
    final decoration = outer.decoration as BoxDecoration;
    expect(decoration.color, theme.colorScheme.surface);
    expect((decoration.border! as Border).top.color, theme.colorScheme.outlineVariant);
  });

  testWidgets('不传 borderConfig 且未传 settings：validate 失败错误可见', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('请输入邮箱'), findsWidgets);
  });

  testWidgets('显式 const WFormBorderConfig() 表示不要外观与文案', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: const WFormBorderConfig(),
            child: WFormTextField(
              name: 'email',
              label: '邮箱',
              message: '请输入邮箱',
              validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('请输入邮箱'), findsNothing);
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('请输入邮箱'), findsNothing);
  });

  testWidgets('祖先 WFormTheme 的 borderConfig 在 WForm 未显式传时生效', (tester) async {
    final ancestor = WFormBorderConfig.fromTheme(
      ThemeData(useMaterial3: true),
      hintStyle: const TextStyle(color: Color(0xFF00AA00)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            borderConfig: ancestor,
            child: WForm(
              controller: WFormController(),
              child: const WFormTextField(name: 'email', label: '邮箱', message: '提示'),
            ),
          ),
        ),
      ),
    );

    final hint = tester.widget<Text>(find.text('提示'));
    expect(hint.style?.color, const Color(0xFF00AA00));
  });

  testWidgets('WForm 显式 borderConfig 优先于祖先 WFormTheme（嵌套场景）', (tester) async {
    final ancestor = WFormBorderConfig.fromTheme(
      ThemeData(useMaterial3: true),
      hintStyle: const TextStyle(color: Color(0xFF00AA00)),
    );
    final inner = WFormBorderConfig.fromTheme(
      ThemeData(useMaterial3: true),
      hintStyle: const TextStyle(color: Color(0xFF0000AA)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            borderConfig: ancestor,
            child: WForm(
              controller: WFormController(),
              borderConfig: inner,
              child: const WFormTextField(name: 'email', label: '邮箱', message: '提示'),
            ),
          ),
        ),
      ),
    );

    final hint = tester.widget<Text>(find.text('提示'));
    expect(hint.style?.color, const Color(0xFF0000AA));
  });

  testWidgets('深色主题下默认边框来自暗色 scheme', (tester) async {
    final theme = ThemeData(useMaterial3: true, brightness: Brightness.dark);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    final outer = decorated.firstWhere(
      (w) => (w.decoration as BoxDecoration?)?.border != null,
      orElse: () => const DecoratedBox(decoration: BoxDecoration()),
    );
    expect((outer.decoration as BoxDecoration).color, theme.colorScheme.surface);
  });
}
