import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WFormTheme 覆盖复选框未选中图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            checkboxUnselectedIcon: const Icon(Icons.star),
            child: WFormScope(
              formData: WFormController(),
              child: WFormCheckbox(
                name: 'agree',
                title: const Text('同意'),
                config: WFormCheckboxConfig(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('WFormTheme 未配置时回退 WFormDefaults', (tester) async {
    final original = WFormDefaults.checkboxUnselectedIcon;
    addTearDown(() {
      WFormDefaults.checkboxUnselectedIcon = original;
    });
    WFormDefaults.checkboxUnselectedIcon = const Icon(Icons.favorite);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            child: WFormScope(
              formData: WFormController(),
              child: WFormCheckbox(
                name: 'agree',
                title: const Text('同意'),
                config: WFormCheckboxConfig(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
