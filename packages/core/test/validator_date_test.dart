import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  test('isValidIdCard 拒绝不存在的出生日期', () {
    expect(WValidator.isValidIdCard('110101199002301234'), isFalse);
    expect(WValidator.isValidIdCard('110101199001011234'), isTrue);
  });
}
