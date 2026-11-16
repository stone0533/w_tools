import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async_ui_example/main.dart';

void main() {
  testWidgets('example 能渲染单区块和分页列表', (tester) async {
    await tester.pumpWidget(const AsyncUiExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Hello async_ui'), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
  });
}
