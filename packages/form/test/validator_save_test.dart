import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'internal/_helpers/form_test_scaffold.dart';

void main() {
  testWidgets('validate() 会先 save()：savedValue 在校验时同步当前值', (tester) async {
    final form = WFormController();
    await pumpForm(
      tester,
      formData: form,
      child: WFormTextField(name: 'a', validator: (value) => '必填'),
    );

    form.formKey.currentState!.fields['a']!.didChange('x');
    await tester.pump();

    // instantValue 已经更新，但 value（savedValue）要等 save() 才同步。
    expect(form.value['a'], 'x');
    expect(form.savedValue['a'], isNull);

    expect(form.validate(), isFalse);
    expect(form.savedValue['a'], 'x');
  });
}
