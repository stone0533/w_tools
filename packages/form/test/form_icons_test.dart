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
    testWidgets('icons 覆盖默认值，未配置项回退 WFormIcons.defaults', (tester) async {
      const star = Icon(Icons.star);
      const theme = WFormThemeData(icons: WFormIcons(dropdown: star));

      expect(theme.effectiveDropdownIcon, star);
      expect(theme.effectiveRadioSelectedIcon, WFormIcons.defaults.radioSelected);
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
                hintText: '国家',
                items: {'CN': '中国'},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  testWidgets('effective* 覆盖密码 / 清空图标', (tester) async {
    const theme = WFormThemeData(
      icons: WFormIcons(
        obscureText: Icon(Icons.visibility_off_outlined),
        obscureTextVisible: Icon(Icons.visibility_outlined),
        clear: Icon(Icons.clear_all),
      ),
    );

    expect(theme.effectiveObscureTextIcon, isA<Icon>());
    expect((theme.effectiveObscureTextIcon as Icon).icon, Icons.visibility_off_outlined);
    expect((theme.effectiveObscureTextVisibleIcon as Icon).icon, Icons.visibility_outlined);
    expect((theme.effectiveClearButtonIcon as Icon).icon, Icons.clear_all);
  });

  testWidgets('外层 WFormTheme 图标变更会驱动字段重建', (tester) async {
    Widget build(IconData icon) => MaterialApp(
      home: Scaffold(
        body: WFormTheme(
          icons: WFormIcons(dropdown: Icon(icon)),
          child: WForm(
            controller: WFormController(),
            child: const WFormDropdown<String>(name: 'c', hintText: 'C', items: {'a': 'A'}),
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(Icons.star));
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.pumpWidget(build(Icons.home));
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });
}
