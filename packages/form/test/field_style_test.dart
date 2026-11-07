import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

const _red = Color(0xFFFF0000);

void main() {
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

  testWidgets('WForm.fieldStyle.hintStyle 作用于日期字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(hintStyle: TextStyle(color: _red)),
            child: const WFormDatePicker(name: 'birthday', hintText: '生日'),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('生日'));
    expect(paragraph.text.style?.color, _red);
  });

  testWidgets('WForm.fieldStyle.hintStyle 作用于多选字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(hintStyle: TextStyle(color: _red)),
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
