import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form_example/main.dart';

void main() {
  testWidgets('示例首页可以渲染登录表单', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    expect(find.text('登录表单'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
  });

  testWidgets('可以切换到会员资料示例', (tester) async {
    await tester.pumpWidget(const FormExampleApp());
    await tester.tap(find.text('会员资料'));
    await tester.pumpAndSettle();
    expect(find.text('编辑资料'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);

    await tester.tap(find.text('弹层'));
    await tester.pumpAndSettle();
    expect(find.text('选择优惠券'), findsOneWidget);
  });
}
