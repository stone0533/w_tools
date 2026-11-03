// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_form/src/components/fields/checkbox.dart';

void main() {
  testWidgets('WFormTheme 覆盖复选框未选中图标', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormTheme(
            checkboxUnselectedIcon: const Icon(Icons.star),
            child: WFormScope(
              formData: WFormController(),
              child: WFormCheckboxCore(
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

  test('WFormDefaults.reset 恢复默认图标', () {
    WFormDefaults.dropdownIcon = const Icon(Icons.star);
    addTearDown(WFormDefaults.reset);

    WFormDefaults.reset();

    expect(WFormDefaults.dropdownIcon, isA<Icon>());
  });

  test('WFormBorderConfig.standard 可创建', () {
    final config = WFormBorderConfig.standard();
    expect(config.build(child: const Text('x')), isA<WFormBorder>());
  });

  testWidgets('WFormScope.formBorderConfig 优先于 WFormTheme', (tester) async {
    final themeConfig = WFormBorderConfig.standard(backgroundColor: Colors.blue);
    final explicitConfig = WFormBorderConfig.standard(backgroundColor: Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: WFormTheme(
          borderConfig: themeConfig,
          child: WFormScope(
            formData: WFormController(),
            formBorderConfig: explicitConfig,
            child: const WFormBorder(child: Text('field')),
          ),
        ),
      ),
    );

    final state = tester.state<WFormBorderState>(find.byType(WFormBorder));
    expect(state.config, same(explicitConfig));
  });

  testWidgets('WFormTheme 位于 WFormScope 内时 WFormBorder 仍能读取', (tester) async {
    final borderConfig = WFormBorderConfig.standard();

    await tester.pumpWidget(
      MaterialApp(
        home: WFormScope(
          formData: WFormController(),
          child: WFormTheme(
            borderConfig: borderConfig,
            child: const WFormBorder(child: Text('field')),
          ),
        ),
      ),
    );

    final state = tester.state<WFormBorderState>(find.byType(WFormBorder));
    expect(state.config, same(borderConfig));
  });

  testWidgets('WFormScope 继承 WFormTheme.borderConfig', (tester) async {
    final borderConfig = WFormBorderConfig.standard();

    await tester.pumpWidget(
      MaterialApp(
        home: WFormTheme(
          borderConfig: borderConfig,
          child: WFormScope(
            formData: WFormController(),
            child: Builder(
              builder: (context) {
                expect(WFormScope.borderConfigOf(context), same(borderConfig));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
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
              child: WFormCheckboxCore(
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
