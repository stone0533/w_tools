import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

/// `WFormBorderConfig` → `WFormBorderStyle` 的改名回归。
///
/// 断言三件事：值语义不变、内置预设仍可用、`WForm(borderStyle:)` 仍能下发到字段边框。
void main() {
  test('WFormBorderStyle 保持不可变值语义与内置预设', () {
    expect(WFormBorderStyle.fromTheme(ThemeData()), WFormBorderStyle.fromTheme(ThemeData()));
    expect(const WFormBorderStyle(), const WFormBorderStyle());
    expect(WFormBorderStyle.standard().errorDecoration, isNotNull);
    expect(WFormBorderStyle.standard().helperStyle, isNotNull);
  });

  test('弃用 hintStyle 仍兼容，且新名优先', () {
    const oldFieldStyle = WFormFieldStyle(
      // ignore: deprecated_member_use_from_same_package
      hintStyle: TextStyle(color: Colors.red),
    );
    expect(oldFieldStyle.effectiveHintStyle?.color, Colors.red);

    const bothFieldStyle = WFormFieldStyle(
      placeholderStyle: TextStyle(color: Colors.blue),
      // ignore: deprecated_member_use_from_same_package
      hintStyle: TextStyle(color: Colors.red),
    );
    expect(bothFieldStyle.effectiveHintStyle?.color, Colors.blue);

    const oldBorderStyle = WFormBorderStyle(
      // ignore: deprecated_member_use_from_same_package
      hintStyle: TextStyle(color: Colors.green),
    );
    expect(oldBorderStyle.effectiveHelperStyle?.color, Colors.green);

    const bothBorderStyle = WFormBorderStyle(
      helperStyle: TextStyle(color: Colors.blue),
      // ignore: deprecated_member_use_from_same_package
      hintStyle: TextStyle(color: Colors.green),
    );
    expect(bothBorderStyle.effectiveHelperStyle?.color, Colors.blue);
  });

  test('弃用 hintStyle 在工厂 / copyWith 仍兼容', () {
    final fromTheme = WFormBorderStyle.fromTheme(
      ThemeData(),
      // ignore: deprecated_member_use_from_same_package
      hintStyle: const TextStyle(color: Colors.orange),
    );
    expect(fromTheme.effectiveHelperStyle?.color, Colors.orange);

    final standard = WFormBorderStyle.standard(
      // ignore: deprecated_member_use_from_same_package
      hintStyle: const TextStyle(color: Colors.purple),
    );
    expect(standard.effectiveHelperStyle?.color, Colors.purple);

    final copied = const WFormBorderStyle().copyWith(
      // ignore: deprecated_member_use_from_same_package
      hintStyle: const TextStyle(color: Colors.teal),
    );
    expect(copied.effectiveHelperStyle?.color, Colors.teal);
  });

  testWidgets('WForm(borderStyle:) 下发给字段边框并渲染 message', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: terseBorderStyle(),
            child: const WFormTextField(name: 'a', hintText: 'A', message: '提示文案'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('提示文案'), findsOneWidget);
  });

  testWidgets('WFormTheme(borderStyle:) 被子树继承', (tester) async {
    final form = WFormController();
    final style = terseBorderStyle();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            borderStyle: style,
            child: WForm(
              controller: form,
              child: const WFormTextField(name: 'b', hintText: 'B', message: '继承来的'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('继承来的'), findsOneWidget);
    expect(WFormThemeData.of(tester.element(find.byType(WFormTextField)))?.borderStyle, style);
  });
}
