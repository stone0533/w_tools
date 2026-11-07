import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/border/border_registry.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  test('ensureBorderKey 对同一 controller / name 返回同一个 key', () {
    final controller = WFormController();
    final k1 = ensureBorderKey(controller, 'field');
    final k2 = ensureBorderKey(controller, 'field');

    expect(k1, same(k2));
    expect(hasBorder(controller, 'field'), isTrue);
    expect(borderKeyOf(controller, 'field'), same(k1));
  });

  test('removeBorderKey 只清理自己的登记', () {
    final controller = WFormController();
    ensureBorderKey(controller, 'field', owner: 'a');

    removeBorderKey(controller, 'field', owner: 'b');
    expect(hasBorder(controller, 'field'), isTrue);

    removeBorderKey(controller, 'field', owner: 'a');
    expect(hasBorder(controller, 'field'), isFalse);
  });
}
