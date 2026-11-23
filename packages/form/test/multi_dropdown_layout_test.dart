import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

Future<WFormController> _pumpAndOpen(
  WidgetTester tester, {
  WFormMultiDropdown<String>? field,
}) async {
  final form = WFormController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          // 与普通表单一致：给页面一个固定字段高度，行高不能被它挤小。
          fieldStyle: const WFormFieldStyle(height: 48),
          child:
              field ??
              const WFormMultiDropdown<String>(
                name: 'tags',
                hintText: '标签',
                items: {'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D'},
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('标签'));
  await tester.pumpAndSettle();
  return form;
}

Future<void> _closePopup(WidgetTester tester) async {
  await tester.tapAt(const Offset(8, 8));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('多选弹层选项行高默认 >= 48（最小点击区域）', (tester) async {
    final form = await _pumpAndOpen(tester);

    final a = tester.getRect(find.text('A'));
    final b = tester.getRect(find.text('B'));
    final c = tester.getRect(find.text('C'));

    expect(b.top - a.top, greaterThanOrEqualTo(48));
    expect(c.top - b.top, greaterThanOrEqualTo(48));

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(form.value['tags'], {'a'});

    await _closePopup(tester);
  });

  testWidgets('itemPadding 可以覆盖默认行高（显式传 zero 回到紧凑）', (tester) async {
    await _pumpAndOpen(
      tester,
      field: const WFormMultiDropdown<String>(
        name: 'tags',
        hintText: '标签',
        items: {'a': 'A', 'b': 'B'},
        itemPadding: EdgeInsets.zero,
      ),
    );

    final a = tester.getRect(find.text('A'));
    final b = tester.getRect(find.text('B'));
    expect(b.top - a.top, lessThan(48));

    await _closePopup(tester);
  });

  testWidgets('itemTitlePadding / 弹层外观参数透传到直接字段', (tester) async {
    const decoration = InputDecoration(border: InputBorder.none);
    await _pumpAndOpen(
      tester,
      field: const WFormMultiDropdown<String>(
        name: 'tags',
        hintText: '标签',
        items: {'a': 'A', 'b': 'B'},
        itemTitlePadding: EdgeInsets.only(left: 24),
        popUpLayerPadding: EdgeInsets.all(8),
        popUpLayerElevation: 2,
        popUpLayerShadowColor: Color(0x11000000),
        decoration: decoration,
      ),
    );

    // 标题内边距：复选框图标 + 24 的左侧间距。
    final a = tester.getRect(find.text('A'));
    final icon = tester.getRect(find.byIcon(Icons.check_box_outline_blank).first);
    expect(a.left - icon.right, 24);

    await _closePopup(tester);
  });
}
