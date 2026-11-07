import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('zh locale（未初始化 intl 日期符号）下日期字段不抛异常', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('zh', 'CN'),
            child: Scaffold(
              body: WForm(
                controller: WFormController(),
                child: const WFormDatePicker(
                  name: 'birthday',
                  initialValue: '2024-03-05',
                  displayFormat: 'yyyy年M月d日',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // 没装 flutter_localizations 的 app 不会初始化 intl 的 zh 日期符号；
    // 字段不能因此在 build 期抛 LocaleDataException。
    expect(tester.takeException(), isNull);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .where((data) => data.isNotEmpty)
        .toList();
    expect(texts, isNotEmpty, reason: '日期字段仍应渲染出文本（回退到默认 locale）');
  });
}
