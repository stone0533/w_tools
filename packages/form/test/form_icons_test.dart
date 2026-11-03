// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  group('WFormIcons', () {
    test('copyWith 替换单个图标，其余保留', () {
      const star = Icon(Icons.star);
      final icons = WFormIcons.defaults.copyWith(dropdown: star);

      expect(icons.dropdown, star);
      expect(icons.checkboxSelected, WFormIcons.defaults.checkboxSelected);
    });

    test('值相等', () {
      expect(const WFormIcons(), const WFormIcons());
      expect(const WFormIcons().hashCode, const WFormIcons().hashCode);
    });
  });

  group('WFormTheme.effective*', () {
    testWidgets('icons 优先于 WFormDefaults，单个 xxxIcon 又优先于 icons', (tester) async {
      const star = Icon(Icons.star);
      const home = Icon(Icons.home);
      const theme = WFormTheme(
        icons: WFormIcons(dropdown: star),
        dropdownIcon: home,
        child: SizedBox.shrink(),
      );

      // 单字段显式图标优先
      expect(theme.effectiveDropdownIcon, home);
      // 未显式传的走 icons
      expect(theme.effectiveRadioSelectedIcon, isNotNull);
      expect(theme.effectiveCheckboxSelectedIcon, WFormIcons.defaults.checkboxSelected);
    });

    testWidgets('WForm(icons:) 传给字段', (tester) async {
      const star = Icon(Icons.star);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WForm(
              controller: WFormController(),
              icons: const WFormIcons(dropdown: star),
              child: const WFormDropdown<String>(
                name: 'country',
                label: '国家',
                items: {'CN': '中国'},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
