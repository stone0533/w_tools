import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

void main() {
  testWidgets('WFormDatePicker 默认区间允许选未来日期', (tester) async {
    await pumpForm(
      tester,
      child: const WFormDatePicker(name: 'birthday', label: '生日'),
    );

    await tester.tap(find.byType(WFormDatePicker));
    await tester.pumpAndSettle();

    final dialog = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(dialog.firstDate.year, 1900);
    // FORM-014：默认 lastDate 不能是「今天」，否则预约 / 到期日这类场景默认不可选。
    expect(dialog.lastDate.year, 2100);
  });
}
