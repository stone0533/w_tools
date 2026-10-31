import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form_example/main.dart';

void main() {
  testWidgets('示例首页可以渲染登录表单', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    expect(find.text('登录表单'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
  });

  testWidgets('登录空表单会触发校验错误', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    await tester.ensureVisible(find.widgetWithText(FilledButton, '登录'));
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('请输入邮箱'), findsWidgets);
  });

  testWidgets('会员资料页可切换只读预览', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    await tester.tap(find.text('会员资料'));
    await tester.pumpAndSettle();

    expect(find.text('编辑资料'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前是只读预览'), findsOneWidget);
  });

  testWidgets('可以打开锚定弹层并回传选择', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    await tester.tap(find.text('弹层'));
    await tester.pumpAndSettle();

    expect(find.text('选择优惠券'), findsOneWidget);
    await tester.tap(find.text('请选择优惠券'));
    await tester.pumpAndSettle();
    expect(find.text('新客券'), findsOneWidget);

    await tester.tap(find.text('新客券'));
    await tester.pumpAndSettle();
    expect(find.text('当前优惠券：new_user'), findsOneWidget);
  });

  testWidgets('高级字段页可读取 controller 状态', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    await tester.tap(find.text('高级'));
    await tester.pumpAndSettle();

    expect(find.text('字段配置'), findsOneWidget);
    await tester.ensureVisible(find.text('读取 controller 状态'));
    await tester.tap(find.text('读取 controller 状态'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('values:'), findsOneWidget);
  });
}
