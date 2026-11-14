import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('外层 WFormTheme 的 icons 被 WForm 继承', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            icons: const WFormIcons(dropdown: Icon(Icons.star)),
            child: WForm(
              controller: WFormController(),
              child: const WFormDropdown<String>(
                name: 'country',
                hintText: '国家',
                items: {'CN': '中国'},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('外层 WFormTheme 的 icons 覆盖字段默认图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            icons: const WFormIcons(checkboxSelected: Icon(Icons.check_circle)),
            child: WForm(
              controller: WFormController(),
              child: const WFormCheckbox(
                name: 'agree',
                title: Text('同意'),
                initialValue: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('WForm.icons 仍优先于外层 WFormTheme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            icons: const WFormIcons(dropdown: Icon(Icons.star)),
            child: WForm(
              controller: WFormController(),
              icons: const WFormIcons(dropdown: Icon(Icons.favorite)),
              child: const WFormDropdown<String>(
                name: 'country',
                hintText: '国家',
                items: {'CN': '中国'},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });
}
