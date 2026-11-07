import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form_example/pages/advanced_fields_page.dart';
import 'package:w_tools_form_example/pages/border_page.dart';
import 'package:w_tools_form_example/pages/profile_page.dart';

void main() {
  testWidgets('边框示例页点校验后展示 itemValidationCallback 结果', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BorderExamplePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('触发校验'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nickname：'), findsOneWidget);
  });

  testWidgets('多行字段使用 72 高外框，避免第三行被裁', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdvancedFieldsPage()));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(TextField).first).height, 72);
  });

  testWidgets('高级页演示泛型字段按钮与 onChanged', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdvancedFieldsPage()));
    await tester.pumpAndSettle();

    expect(find.text('字段变化次数：0'), findsOneWidget);

    await tester.tap(find.text('选择优先级'));
    await tester.pumpAndSettle();
    expect(find.text('优先级 1'), findsOneWidget);
    expect(find.text('字段变化次数：1'), findsOneWidget);
  });

  testWidgets('会员资料页可选择多选与日期', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileExamplePage()));
    await tester.pumpAndSettle();

    // 多选：滚动到字段，打开弹层，勾选「运动」，点弹层外关闭。
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('旅行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('运动'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('运动'), findsWidgets);

    // 日期：滚动到字段，打开系统日期选择器并取消。
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1998-06-18'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });
}
