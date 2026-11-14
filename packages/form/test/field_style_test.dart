import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

const _red = Color(0xFFFF0000);

void main() {
  group('WFormFieldStyle 值语义', _styleEqualityTests);

  testWidgets('WForm.fieldStyle.textStyle 作用于复选框标题', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(textStyle: TextStyle(color: _red)),
            child: const WFormCheckbox(name: 'agree', title: Text('同意')),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('同意'));
    expect(paragraph.text.style?.color, _red);
  });

  testWidgets('WForm.fieldStyle.placeholderStyle 作用于日期字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(placeholderStyle: TextStyle(color: _red)),
            child: const WFormDatePicker(name: 'birthday', hintText: '生日'),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('生日'));
    expect(paragraph.text.style?.color, _red);
  });

  testWidgets('WForm.fieldStyle.placeholderStyle 作用于多选字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(placeholderStyle: TextStyle(color: _red)),
            child: const WFormMultiDropdown(
              name: 'tags',
              hintText: '标签',
              items: {'a': 'A'},
            ),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('标签'));
    expect(paragraph.text.style?.color, _red);
  });
}

/// 用运行期参数构造，避免 const canonicalize 成同一实例：
/// 那样断言 == 即使没有 operator== 也会过，测不到值语义。
WFormFieldStyle _makeStyle(double height) => WFormFieldStyle(
  height: height,
  containerPadding: const EdgeInsets.symmetric(horizontal: 16),
  textStyle: const TextStyle(color: _red),
  placeholderStyle: const TextStyle(color: _red),
);

void _styleEqualityTests() {
  test('WFormFieldStyle 按值相等（与 WFormBorderStyle / WFormValidatorSettings 一致）', () {
    final a = _makeStyle(52);
    final b = _makeStyle(52);

    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == _makeStyle(53), isFalse);
  });
}
