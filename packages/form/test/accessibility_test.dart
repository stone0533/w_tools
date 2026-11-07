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
}
