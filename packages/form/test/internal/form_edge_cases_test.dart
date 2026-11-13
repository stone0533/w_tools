import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'package:w_tools_form/src/components/field_assembly.dart';

import '_helpers/form_test_scaffold.dart';
import 'package:w_tools_form/src/components/fields/date_picker.dart';

void main() {
  group('字段卸载清理 formEntered', () {
    Future<void> expectCleanup(
      WidgetTester tester,
      Widget child,
      String name, {
      Object? value = 'x',
    }) async {
      final data = WFormController();
      await pumpForm(tester, formData: data, child: child);

      data.setValue<Object?>(name, value);
      await tester.pump();
      expect(data.formEntered[name], isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(data.formEntered.containsKey(name), isFalse);
    }

    testWidgets('WFormCheckbox 卸载后清理输入状态', (tester) async {
      await expectCleanup(
        tester,
        checkboxCore(
          name: 'checkbox',
          title: const Text('同意'),
        ),
        'checkbox',
        value: true,
      );
    });

    testWidgets('WFormDatePicker 卸载后清理输入状态', (tester) async {
      await expectCleanup(
        tester,
        WFormDatePickerCore(
          name: 'date',
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        ),
        'date',
      );
    });

    testWidgets('WFormRadioGroup 卸载后清理输入状态', (tester) async {
      await expectCleanup(
        tester,
        radioCore<String>(
          name: 'radio',
          items: const {'a': 'A'},
        ),
        'radio',
      );
    });

    testWidgets('WFormButton 卸载后清理输入状态', (tester) async {
      await expectCleanup(
        tester,
        buttonCore(hintWidget: const Text('选择'), name: 'button', onTap: (_, __) {}),
        'button',
      );
    });
  });

  group('裸字段 readOnly 生效', () {
    testWidgets('WFormCheckbox 裸字段只读', (tester) async {
      var changed = false;
      await pumpForm(
        tester,
        child: checkboxCore(
          name: 'checkbox',
          title: const Text('同意'),
          readOnly: true,
          onChanged: (_) => changed = true,
        ),
      );

      await tester.tap(find.text('同意'));
      await tester.pump();
      expect(changed, isFalse);
    });

    testWidgets('WFormDatePicker 裸字段只读', (tester) async {
      await pumpForm(
        tester,
        child: assembleFormField(
          name: 'date',
          bordered: false,
          readOnly: true,
          child: WFormDatePickerCore(
            name: 'date',
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      await tester.tap(find.byType(WFormDatePickerCore));
      await tester.pump();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('WFormRadioGroup 裸字段只读', (tester) async {
      String? changed;
      await pumpForm(
        tester,
        child: radioCore<String>(
          name: 'radio',
          items: const {'a': 'A'},
          readOnly: true,
          onChanged: (value) => changed = value,
        ),
      );

      await tester.tap(find.text('A'));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('WFormButton 裸字段只读', (tester) async {
      var tapped = false;
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('选择'),
          name: 'button',
          readOnly: true,
          onTap: (_, __) => tapped = true,
        ),
      );

      await tester.tap(find.text('选择'));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });
}
