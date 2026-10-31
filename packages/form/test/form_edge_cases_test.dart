import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

void main() {
  group('字段卸载清理 formEntered', () {
    Future<void> expectCleanup(
      WidgetTester tester,
      Widget child,
      String name,
    ) async {
      final data = WFormController();
      await pumpForm(tester, formData: data, child: child);

      data.handleChange(name, 'x');
      expect(data.formEntered[name], isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(data.formEntered.containsKey(name), isFalse);
    }

    testWidgets('WFormCheckboxCore', (tester) async {
      await expectCleanup(
        tester,
        WFormCheckboxConfig().build(
          name: 'checkbox',
          title: const Text('同意'),
        ),
        'checkbox',
      );
    });

    testWidgets('WFormDatePickerCore', (tester) async {
      await expectCleanup(
        tester,
        WFormDatePickerConfig().build(
          name: 'date',
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        ),
        'date',
      );
    });

    testWidgets('WFormRadioGroupCore', (tester) async {
      await expectCleanup(
        tester,
        WFormRadioGroupConfig().build<String>(
          name: 'radio',
          items: const {'a': 'A'},
        ),
        'radio',
      );
    });

    testWidgets('WFormFieldButtonCore', (tester) async {
      final config = WFormFieldButtonConfig(hintWidget: const Text('选择'));
      await expectCleanup(
        tester,
        config.build(name: 'button', onTap: (_, __) {}),
        'button',
      );
    });
  });

  group('裸字段 readOnly 生效', () {
    testWidgets('WFormCheckboxCore', (tester) async {
      var changed = false;
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
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

    testWidgets('WFormDatePickerCore', (tester) async {
      await pumpForm(
        tester,
        child: WFormDatePickerConfig().build(
          name: 'date',
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          readOnly: true,
        ),
      );

      await tester.tap(find.byType(WFormDatePickerCore));
      await tester.pump();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('WFormRadioGroupCore', (tester) async {
      String? changed;
      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
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

    testWidgets('WFormFieldButtonCore', (tester) async {
      var tapped = false;
      final config = WFormFieldButtonConfig(hintWidget: const Text('选择'));
      await pumpForm(
        tester,
        child: config.build(
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
