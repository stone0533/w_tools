import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 复选框 / 单选项的语义节点必须同时带「选中态」和「可点击动作」。
///
/// 只断言 `checked` 不够：读屏用户需要能激活它。
bool _hasActionableCheckedSemantics(WidgetTester tester) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((widget) => widget.properties.checked != null && widget.properties.onTap != null);
}

/// 文本插槽 / 多选选项的语义节点必须同时带「按钮」和「可点击动作」。
bool _hasActionableButtonSemantics(WidgetTester tester) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((widget) => widget.properties.button == true && widget.properties.onTap != null);
}

bool _hasSemanticLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((widget) => widget.properties.label == label);
}

void main() {
  testWidgets('复选框具备可点击语义', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormCheckbox(name: 'agree', title: Text('同意')),
          ),
        ),
      ),
    );

    expect(_hasActionableCheckedSemantics(tester), isTrue);
    handle.dispose();
  });

  testWidgets('单选项具备可点击语义', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormRadioGroup<String>(
              name: 'gender',
              items: {'female': '女', 'male': '男'},
            ),
          ),
        ),
      ),
    );

    expect(_hasActionableCheckedSemantics(tester), isTrue);
    handle.dispose();
  });

  testWidgets('文本 action 具备可点击语义', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormTextField(
              name: 'search',
              actions: [
                WFormTextFieldAction(
                  semanticLabel: '发送',
                  iconBuilder: (_) => const Icon(Icons.send),
                  onPressed: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(_hasActionableButtonSemantics(tester), isTrue);
    expect(_hasSemanticLabel(tester, '发送'), isTrue);
    handle.dispose();
  });

  testWidgets('密码切换会更新读屏标签', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'password',
              obscureText: true,
              actions: [
                WFormTextFieldPasswordToggle(
                  showSemanticLabel: '显示密码',
                  hideSemanticLabel: '隐藏密码',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(_hasSemanticLabel(tester, '显示密码'), isTrue);
    await tester.tap(find.byType(WFormTextFieldPasswordToggle));
    await tester.pump();
    expect(_hasSemanticLabel(tester, '隐藏密码'), isTrue);
    handle.dispose();
  });

  testWidgets('清空按钮支持自定义读屏标签', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'query',
              initialValue: 'abc',
              actions: [WFormTextFieldClearButton(semanticLabel: '清空')],
            ),
          ),
        ),
      ),
    );

    expect(_hasSemanticLabel(tester, '清空'), isTrue);
    handle.dispose();
  });

  testWidgets('多选弹层选项具备可点击语义', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormMultiDropdown(
              name: 'tags',
              items: {'a': 'A', 'b': 'B'},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(WFormMultiDropdown<String>));
    await tester.pumpAndSettle();
    expect(_hasActionableButtonSemantics(tester), isTrue);
    handle.dispose();
  });
}
