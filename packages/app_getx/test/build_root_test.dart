import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  testWidgets('buildRoot 不要求 init，复用 appWrapper / builder / scope', (tester) async {
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const Text('home'),
        appWrapper: (child) => KeyedSubtree(
          key: const Key('wrapper'),
          child: child,
        ),
        builder: (context, child) => KeyedSubtree(
          key: const Key('builder'),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(find.text('home'), findsOneWidget);
    expect(find.byKey(const Key('wrapper')), findsOneWidget);
    expect(find.byKey(const Key('builder')), findsOneWidget);
    expect(find.byType(WAppScope), findsOneWidget);
    expect(app.isInitialized, isFalse);
  });

  testWidgets('测试宿主用 copyWith 覆盖 home，运行时配置保持不变', (tester) async {
    final options = WAppOptions(
      title: 'test',
      home: const Text('runtime-home'),
    );
    final app = WApp.options(options.copyWith(home: const Text('test-home')));

    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(find.text('test-home'), findsOneWidget);
    expect(find.text('runtime-home'), findsNothing);
  });

  testWidgets('systemUiOverlayStyle 作为根级 AnnotatedRegion 兜底', (tester) async {
    const style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );
    final app = WApp.options(
      WAppOptions(
        title: 'test',
        home: const Scaffold(body: Text('home')),
        theme: const WAppTheme(systemUiOverlayStyle: style),
      ),
    );

    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(region.value, style);
  });
}
