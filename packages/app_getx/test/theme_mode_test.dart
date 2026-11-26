import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app_getx/w_tools_app_getx.dart';

WApp _app({ThemeMode mode = ThemeMode.system}) => WApp.options(
  WAppOptions(
    title: 'test',
    home: const SizedBox.shrink(),
    theme: WAppTheme(
      light: ThemeData(useMaterial3: true),
      dark: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      mode: mode,
    ),
    startupLog: false,
  ),
);

ThemeMode _materialThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  test('themeMode 初值来自 WAppTheme.mode', () {
    expect(_app(mode: ThemeMode.dark).themeMode.value, ThemeMode.dark);
    expect(_app().themeMode.value, ThemeMode.system);
  });

  testWidgets('setThemeMode 运行时切主题，路由栈不受影响', (tester) async {
    final app = _app();
    await app.init();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    expect(_materialThemeMode(tester), ThemeMode.system);
    final routesBefore = app.routeStack.routes.length;

    app.setThemeMode(ThemeMode.dark);
    await tester.pump();

    expect(app.themeMode.value, ThemeMode.dark);
    expect(_materialThemeMode(tester), ThemeMode.dark);
    expect(
      app.routeStack.routes.length,
      routesBefore,
      reason: '切主题不应重置路由栈',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose 幂等；之后 setThemeMode / buildRoot / 切语言都抛 StateError', (
    tester,
  ) async {
    final app = _app();
    await tester.pumpWidget(app.buildRoot());
    await tester.pump();

    app.dispose();
    app.dispose();

    expect(() => app.setThemeMode(ThemeMode.dark), throwsStateError);
    expect(() => app.buildRoot(), throwsStateError);
    expect(() => app.language.changeLanguage('zh_CN'), throwsStateError);
  });
}
