import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  test('phone() 作为弃用别名仍等价于 hkPhone()', () {
    // ignore: deprecated_member_use_from_same_package
    final legacy = WFormInputFormatters.phone();
    expect(legacy.length, WFormInputFormatters.hkPhone().length);
  });
}
