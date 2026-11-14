import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/field_frame.dart';
import 'package:w_tools_form/w_tools_form.dart';

const _red = Color(0xFFFF0000);
const _pad = EdgeInsets.symmetric(horizontal: 18);
const _style = WFormFieldStyle(
  height: 64,
  containerPadding: _pad,
  textStyle: TextStyle(color: _red),
  placeholderStyle: TextStyle(color: _red),
);

/// 直接字段的 fieldStyle 接线矩阵：单行字段接 height / containerPadding / textStyle，
/// 多行单选组只接 containerPadding / textStyle（height 固定会裁掉多个选项）。
///
/// 这类「漏接 / 错接一个参数」的 bug（见 FORM-001）只有逐字段断言才能拦住。
WFormFieldFrame _frameOf(WidgetTester tester) =>
    tester.widget<WFormFieldFrame>(find.byType(WFormFieldFrame));

Future<void> _pump(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: WFormController(),
          fieldStyle: _style,
          child: field,
        ),
      ),
    ),
  );
}

void main() {
  group('WForm.fieldStyle 对每个直接字段生效', () {
    testWidgets('WFormTextField：height / containerPadding / textStyle', (tester) async {
      await _pump(tester, const WFormTextField(name: 'a', hintText: '文本'));

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style?.color, _red);
    });

    testWidgets('WFormDropdown：height / containerPadding / textStyle', (tester) async {
      await _pump(
        tester,
        const WFormDropdown<String>(
          name: 'd',
          items: {'a': 'A'},
          initialValue: 'a',
        ),
      );

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);

      final paragraph = tester.renderObject<RenderParagraph>(find.text('A'));
      expect(paragraph.text.style?.color, _red);
    });

    testWidgets('WFormMultiDropdown：height / containerPadding / textStyle', (tester) async {
      await _pump(
        tester,
        const WFormMultiDropdown(
          name: 'm',
          items: {'a': 'A'},
          initialValue: {'a'},
          hintText: '多选',
        ),
      );

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);

      final paragraph = tester.renderObject<RenderParagraph>(find.text('A'));
      expect(paragraph.text.style?.color, _red);
    });

    testWidgets('WFormDatePicker：height / containerPadding / textStyle', (tester) async {
      await _pump(
        tester,
        const WFormDatePicker(
          name: 'date',
          initialValue: '2024-03-05',
          displayFormat: 'yyyy-MM-dd',
        ),
      );

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);

      final paragraph = tester.renderObject<RenderParagraph>(find.text('2024-03-05'));
      expect(paragraph.text.style?.color, _red);
    });

    testWidgets('WFormCheckbox：height / containerPadding / textStyle', (tester) async {
      await _pump(tester, const WFormCheckbox(name: 'c', title: Text('同意')));

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);

      final paragraph = tester.renderObject<RenderParagraph>(find.text('同意'));
      expect(paragraph.text.style?.color, _red);
    });

    testWidgets('WFormRadioGroup：containerPadding / textStyle，不接 height', (tester) async {
      await _pump(
        tester,
        const WFormRadioGroup<String>(name: 'r', items: {'a': 'A'}),
      );

      final frame = _frameOf(tester);
      // 单选组是多行布局：页面级 height 会把它压成固定高度，3 个选项就溢出。
      expect(frame.height, isNull);
      // 单选把 containerPadding 作用在内层选项列上（外框不再重复施加），
      // 这里断言内层 Padding 真的拿到了页面级值。
      expect(
        find.descendant(
          of: find.byType(WFormFieldFrame),
          matching: find.byWidgetPredicate(
            (widget) => widget is Padding && widget.padding == _pad,
          ),
        ),
        findsWidgets,
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.text('A'));
      expect(paragraph.text.style?.color, _red);
    });

    testWidgets('WFormRadioGroup：3 个选项 + 页面 height 不溢出', (tester) async {
      await _pump(
        tester,
        const WFormRadioGroup<String>(
          name: 'r',
          items: {'a': 'A', 'b': 'B', 'c': 'C'},
          initialValue: 'a',
        ),
      );

      expect(_frameOf(tester).height, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WFormFieldButton：height / containerPadding', (tester) async {
      await _pump(
        tester,
        WFormFieldButton<int>(
          name: 'b',
          label: '选择',
          onTap: (_, _) {},
        ),
      );

      final frame = _frameOf(tester);
      expect(frame.height, 64);
      expect(frame.padding, _pad);
    });
  });

  group('WForm.fieldStyle.placeholderStyle 到达各字段占位符', () {
    Future<void> expectHintColor(WidgetTester tester, String hint) async {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(hint));
      expect(paragraph.text.style?.color, _red);
    }

    testWidgets('WFormTextField', (tester) async {
      await _pump(tester, const WFormTextField(name: 'a', hintText: '文本占位'));
      await expectHintColor(tester, '文本占位');
    });

    testWidgets('WFormDropdown', (tester) async {
      await _pump(
        tester,
        const WFormDropdown<String>(name: 'd', items: {'a': 'A'}, hintText: '下拉占位'),
      );
      await expectHintColor(tester, '下拉占位');
    });

    testWidgets('WFormMultiDropdown', (tester) async {
      await _pump(
        tester,
        const WFormMultiDropdown(name: 'm', items: {'a': 'A'}, hintText: '多选占位'),
      );
      await expectHintColor(tester, '多选占位');
    });

    testWidgets('WFormDatePicker', (tester) async {
      await _pump(tester, const WFormDatePicker(name: 'date', hintText: '日期占位'));
      await expectHintColor(tester, '日期占位');
    });
  });
}
