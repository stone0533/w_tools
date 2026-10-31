import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app_example/main.dart';
import 'package:w_tools_app_example/pages/detail_page.dart';

Future<void> _start(WidgetTester tester) async {
  final starting = createApp().start();
  await tester.pump(const Duration(milliseconds: 100));
  await starting;
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    startupEvents.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets('WApp 启动后展示插件初始化结果', (tester) async {
    await _start(tester);

    expect(find.text('w_tools_app 示例'), findsOneWidget);
    expect(find.text('env: loaded'), findsOneWidget);
    expect(find.text('feature: ready'), findsOneWidget);
  });

  testWidgets('可以打开详情路由并返回', (tester) async {
    await _start(tester);

    await tester.tap(find.text('打开详情路由'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailPage), findsOneWidget);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.text('w_tools_app 示例'), findsOneWidget);
  });

  testWidgets('可以打开底部弹窗', (tester) async {
    await _start(tester);

    expect(find.text('切换语言'), findsOneWidget);
    await tester.tap(find.text('底部弹窗'));
    await tester.pumpAndSettle();
    expect(find.text('WBottomSheet'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('WBottomSheet'), findsNothing);
  });
}
