import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_ui_example/app_buttons.dart';

void main() {
  testWidgets('AppButtons 与 WButton 构造器配对，且前景 / 背景不同色', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WButton.filled(
                    style: AppButtons.primary(context),
                    label: 'primary',
                    onTap: () {},
                  ),
                  WButton.outlined(
                    style: AppButtons.secondary(context),
                    label: 'secondary',
                    onTap: () {},
                  ),
                  WButton.text(
                    style: AppButtons.text(context),
                    label: 'text',
                    onTap: () {},
                  ),
                  WButton.filled(
                    style: AppButtons.danger(context),
                    label: 'danger',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 类型配对：primary / danger 是 FilledButton，secondary 是 OutlinedButton，
    // text 是 TextButton。
    expect(find.byType(FilledButton), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    for (final label in ['primary', 'secondary', 'text', 'danger']) {
      final element = tester.element(find.text(label));
      final foreground = DefaultTextStyle.of(element).style.color;
      final material = tester.widget<Material>(
        find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
      );
      final background = material.color ?? Colors.transparent;
      expect(foreground, isNotNull, reason: '$label 缺少前景色');
      expect(
        foreground,
        isNot(background),
        reason: '$label 的前景与背景同色，按钮内容不可见',
      );
    }
  });
}
