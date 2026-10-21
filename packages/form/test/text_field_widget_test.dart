import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

/// 选择 WFormTextField 内部真正的 TextField（FormBuilderTextField 包装的）
Finder findTextField() => find.byType(TextField);

void main() {
  testWidgets('WFormTextField — hintText 正确渲染', (tester) async {
    await pumpForm(
      tester,
      child: WFormTextFieldConfig().build(
        name: 'email',
        hintText: '请输入邮箱',
      ),
    );
    expect(find.text('请输入邮箱'), findsOneWidget);
  });

  testWidgets('WFormTextField — initialValue 正确显示', (tester) async {
    await pumpForm(
      tester,
      child: WFormTextFieldConfig().build(
        name: 'email',
        initialValue: 'user@test.com',
      ),
    );
    expect(find.text('user@test.com'), findsOneWidget);
  });

  testWidgets('WFormTextField — onChanged 回调被调用', (tester) async {
    String? lastValue;
    await pumpForm(
      tester,
      child: WFormTextFieldConfig().build(
        name: 'email',
        hintText: 'hint',
        onChanged: (v) => lastValue = v,
      ),
    );
    await tester.enterText(findTextField(), 'hello');
    await tester.pump();
    expect(lastValue, 'hello');
  });

  testWidgets('WFormTextField — readOnly=true 仍渲染 TextField', (tester) async {
    await pumpForm(
      tester,
      child: WFormTextFieldConfig().build(
        name: 'readonly',
        initialValue: 'fixed',
        readOnly: true,
      ),
    );
    expect(findTextField(), findsOneWidget);
  });

  testWidgets('WFormTextField — config.width 渲染到外层容器', (tester) async {
    final config = WFormTextFieldConfig()..width = 200;

    await pumpForm(tester, child: config.build(name: 'sized'));

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(WFormTextField), matching: find.byType(Container)).first,
    );
    expect(container.constraints?.maxWidth, 200);
  });

  testWidgets('WFormTextField — 密码模式显示/隐藏图标', (tester) async {
    await pumpForm(
      tester,
      child:
          (WFormTextFieldConfig()
                ..obscureText = true
                ..actions = const [WFormTextFieldPasswordToggle()])
              .build(
                name: 'password',
                initialValue: 'secret',
              ),
    );
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('WFormTextField — 非密码模式下不显示密码切换按钮', (tester) async {
    await pumpForm(
      tester,
      child: (WFormTextFieldConfig()..actions = const [WFormTextFieldPasswordToggle()]).build(
        name: 'plain',
        initialValue: 'text',
      ),
    );
    expect(find.byIcon(Icons.visibility_off), findsNothing);
    expect(find.byIcon(Icons.visibility), findsNothing);
  });

  testWidgets('WFormTextField — 点击密码图标切换显示状态', (tester) async {
    await pumpForm(
      tester,
      child:
          (WFormTextFieldConfig()
                ..obscureText = true
                ..actions = const [WFormTextFieldPasswordToggle()])
              .build(
                name: 'password',
                initialValue: 'secret',
              ),
    );
    // 初始: visibility_off
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    // 点击切换为可见
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    // 再点击切回不可见
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('WFormTextField — 渲染后有 Row', (tester) async {
    await pumpForm(
      tester,
      child: WFormTextFieldConfig().build(
        name: 'row_test',
        hintText: 'row hint',
      ),
    );
    // WFormTextField 的 build 方法用 Row 承载 leading + Expanded + actions
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('WFormTextField — 无 WFormBuilder 时 build 抛异常', (tester) async {
    // 没有 WFormBuilder 祖先时抛出 StateError('WFormBuilder 未找到')，
    // Flutter framework 会捕获并通过 tester.takeException 返回
    await tester.pumpWidget(
      MaterialApp(
        home: WFormTextFieldConfig().build(
          name: 'orphan',
          hintText: 'no builder',
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isA<StateError>());
  });

  group('WFormTextFieldScope 插件化管道', () {
    /// 用户自定义密码切换按钮（跟预置 PasswordToggle 做同样的事，
    /// 但通过公开接口 [WFormTextFieldData] 而非私有 scope.state）
    testWidgets('自定义 PasswordToggle — 通过公开接口读 isPasswordVisible', (tester) async {
      const customToggle = _CustomPwdToggle();
      await pumpForm(
        tester,
        child:
            (WFormTextFieldConfig()
                  ..obscureText = true
                  ..actions = const [customToggle])
                .build(
                  name: 'pwd',
                  initialValue: 'secret',
                ),
      );

      // 初始不可见 → 显示 visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // 点击自定义 toggle → 切为可见
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    /// 用户自定义清空按钮（订阅 valueListenable + 触发 clear）
    testWidgets('自定义 ClearButton — 通过公开接口订阅值变化 + clear', (tester) async {
      const customClear = _CustomClearAction();
      await pumpForm(
        tester,
        child: (WFormTextFieldConfig()..actions = const [customClear]).build(
          name: 'field',
          initialValue: 'hello',
        ),
      );

      // 初始有值 → 清空按钮可见
      expect(find.byIcon(Icons.backspace), findsOneWidget);

      // 点击清空
      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pump();

      // 清空按钮消失（hasText = false）
      expect(find.byIcon(Icons.backspace), findsNothing);
    });
  });

  group('WFormTextFieldAction（通用 action 构建器）', () {
    testWidgets('按状态动态渲染图标，点击回调拿到当前值', (tester) async {
      final values = <String?>[];

      await pumpForm(
        tester,
        child:
            (WFormTextFieldConfig()
                  ..actions = [
                    WFormTextFieldAction(
                      visibleWhen: (data) => data.hasText,
                      iconBuilder: (data) => Icon(data.hasText ? Icons.send : Icons.send_outlined),
                      onPressed: (data) => values.add(data.value),
                    ),
                  ])
                .build(name: 'q', initialValue: 'abc'),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.tap(find.byIcon(Icons.send));
      expect(values, ['abc']);
    });

    testWidgets('visibleWhen 为 false 时不渲染', (tester) async {
      await pumpForm(
        tester,
        child:
            (WFormTextFieldConfig()
                  ..actions = [
                    WFormTextFieldAction(
                      visibleWhen: (data) => data.hasText,
                      iconBuilder: (_) => const Icon(Icons.send),
                    ),
                  ])
                .build(name: 'q'),
      );

      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('data.obscureText 反映密码模式', (tester) async {
      bool? captured;

      await pumpForm(
        tester,
        child:
            (WFormTextFieldConfig()
                  ..obscureText = true
                  ..actions = [
                    WFormTextFieldAction(
                      iconBuilder: (data) {
                        captured = data.obscureText;
                        return const SizedBox.shrink();
                      },
                    ),
                  ])
                .build(name: 'pwd', initialValue: 'x'),
      );

      expect(captured, isTrue);
    });
  });

  group('WFormTextFieldClearButton（预置 action）', () {
    testWidgets('有内容时显示，点击清空并触发 onCleared', (tester) async {
      final formData = WFormData();
      var cleared = 0;

      await pumpForm(
        tester,
        formData: formData,
        child:
            (WFormTextFieldConfig()
                  ..actions = [
                    WFormTextFieldClearButton(onCleared: () => cleared++),
                  ])
                .build(name: 'field', initialValue: 'hello'),
      );

      // 默认图标可见
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(cleared, 1);
      // 清空后按钮隐藏，且字段值被置空
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(formData.getFieldsValue<String>('field'), isNull);
    });

    testWidgets('自定义 icon 覆盖默认图标', (tester) async {
      await pumpForm(
        tester,
        child:
            (WFormTextFieldConfig()
                  ..actions = const [
                    WFormTextFieldClearButton(icon: Icon(Icons.close)),
                  ])
                .build(name: 'field', initialValue: 'hello'),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('只读时隐藏', (tester) async {
      await pumpForm(
        tester,
        child: (WFormTextFieldConfig()..actions = const [WFormTextFieldClearButton()]).build(
          name: 'field',
          initialValue: 'hello',
          readOnly: true,
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('外层只读作用域下隐藏（且随作用域切换更新）', (tester) async {
      final formData = WFormData();
      final config = WFormTextFieldConfig()..actions = const [WFormTextFieldClearButton()];

      Widget build(bool readOnly) => MaterialApp(
        home: Scaffold(
          body: WFormBuilder(
            formData: formData,
            child: WFormReadOnlyScope(
              readOnly: readOnly,
              child: config.build(name: 'field', initialValue: 'hello'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(build(false));
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsNothing);
    });
  });
}

// ---------------------------------------------------------------------------
// 自定义 action Widget（模拟用户侧代码）
// ---------------------------------------------------------------------------

/// 用户自己写的密码切换 action，走公开接口 [WFormTextFieldData]。
class _CustomPwdToggle extends StatelessWidget {
  const _CustomPwdToggle();

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldScope.of(context);
    if (data == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: data.togglePasswordVisibility,
      child: Icon(data.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
    );
  }
}

/// 用户自己写的清空 action，走公开接口 + 订阅 valueListenable。
class _CustomClearAction extends StatelessWidget {
  const _CustomClearAction();

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldScope.of(context);
    if (data == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: data.valueListenable,
      builder: (_, __) {
        if (!data.hasText || data.readOnly) return const SizedBox.shrink();
        return GestureDetector(
          onTap: data.clear,
          child: const Icon(Icons.backspace),
        );
      },
    );
  }
}
