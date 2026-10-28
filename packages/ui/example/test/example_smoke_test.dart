import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui_example/main.dart';

void main() {
  testWidgets('示例 App 能构建并显示导航', (tester) async {
    await tester.pumpWidget(const WImageExampleApp());
    expect(find.text('WImage 示例'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('状态矩阵'), findsOneWidget);
  });
}
