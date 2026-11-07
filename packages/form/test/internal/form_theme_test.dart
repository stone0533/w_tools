import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/src/components/border/border.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_form/src/components/fields/checkbox.dart';

void main() {
  testWidgets('WFormTheme 覆盖复选框未选中图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            icons: const WFormIcons(checkboxUnselected: Icon(Icons.star)),
            child: WFormScope(
              formData: WFormController(),
              child: WFormCheckboxCore(
                name: 'agree',
                title: const Text('同意'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  test('WFormBorderStyle.standard 可创建', () {
    final config = WFormBorderStyle.standard();
    expect(WFormBorder(style: config, child: const Text('x')), isA<WFormBorder>());
  });

  testWidgets('WFormScope.formBorderStyle 优先于 WFormTheme', (tester) async {
    final themeConfig = WFormBorderStyle.standard(backgroundColor: Colors.blue);
    final explicitConfig = WFormBorderStyle.standard(backgroundColor: Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: WFormTheme(
          borderStyle: themeConfig,
          child: WFormScope(
            formData: WFormController(),
            formBorderStyle: explicitConfig,
            child: const WFormBorder(child: Text('field')),
          ),
        ),
      ),
    );

    final state = tester.state<WFormBorderState>(find.byType(WFormBorder));
    expect(state.style, same(explicitConfig));
  });

  testWidgets('WFormTheme 位于 WFormScope 内时 WFormBorder 仍能读取', (tester) async {
    final borderStyle = WFormBorderStyle.standard();

    await tester.pumpWidget(
      MaterialApp(
        home: WFormScope(
          formData: WFormController(),
          child: WFormTheme(
            borderStyle: borderStyle,
            child: const WFormBorder(child: Text('field')),
          ),
        ),
      ),
    );

    final state = tester.state<WFormBorderState>(find.byType(WFormBorder));
    expect(state.style, same(borderStyle));
  });

  testWidgets('WFormScope 继承 WFormTheme.borderStyle', (tester) async {
    final borderStyle = WFormBorderStyle.standard();

    await tester.pumpWidget(
      MaterialApp(
        home: WFormTheme(
          borderStyle: borderStyle,
          child: WFormScope(
            formData: WFormController(),
            child: Builder(
              builder: (context) {
                expect(WFormScope.borderStyleOf(context), same(borderStyle));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('WFormTheme 未配置时回退 WFormIcons.defaults', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            child: WFormScope(
              formData: WFormController(),
              child: WFormCheckboxCore(
                name: 'agree',
                title: const Text('同意'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });
}
