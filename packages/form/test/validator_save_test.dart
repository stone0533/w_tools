import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

void main() {
  testWidgets('validate() 不会隐式 save；显式 save 才同步 savedValue', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: WFormTextField(name: 'a', validator: (value) => '必填'),
    );

    form.formKey.currentState!.fields['a']!.didChange('x');
    await tester.pump();

    expect(form.value['a'], 'x');
    expect(form.savedValue['a'], isNull);

    expect(form.validate(), isFalse);
    // 校验失败 / 成功都不写 savedValue，也不触发字段 onSaved。
    expect(form.savedValue['a'], isNull);

    form.save();
    expect(form.savedValue['a'], 'x');
  });
}
