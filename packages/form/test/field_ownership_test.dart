import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('同名字段 → 报可读的「字段 name 重复」而不是 GlobalKey 冲突', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;

    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WForm(
              controller: WFormController(),
              child: const Column(
                children: [
                  WFormTextField(name: 'email', label: '邮箱 A'),
                  WFormTextField(name: 'email', label: '邮箱 B'),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      FlutterError.onError = original;
    }

    // 第一条错误必须是可读的「字段 name 重复」，而不是框架的 GlobalKey 冲突
    expect(errors, isNotEmpty);
    expect(errors.first.exception.toString(), contains('字段 name 重复'));
  });

  testWidgets('WFormButton 的 didChange 在字段卸载后调用不崩', (tester) async {
    ValueChanged<String>? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: WFormButton(
              name: 'coupon',
              label: '选择优惠券',
              onTap: (value, didChange) => captured = didChange,
            ),
          ),
        ),
      ),
    );

    // 打开"选择器"（拿到 didChange），此时页面被销毁
    await tester.tap(find.byType(WFormButton));
    expect(captured, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    captured!.call('new-value');

    expect(tester.takeException(), isNull);
  });
}
