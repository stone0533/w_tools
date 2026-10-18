import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  final firstDate = DateTime(1900);
  final lastDate = DateTime(2100);
  final testDate = DateTime(2024, 1, 15);
  // WFormDatePicker 内部以 ISO yyyy-MM-dd 存储
  const initialValue = '2024-01-15';
  // 内部按 displayFormat（默认 yMMMMd）+ 当前 locale 显示
  final displayedText = DateFormat.yMMMMd().format(testDate);

  Widget buildWrapped({
    required WFormData formData,
    required Widget child,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: WFormBuilder(
        formData: formData,
        child: child,
      ),
    );
  }

  /// 在 DatePickerDialog 内部找 widget
  Finder inDialog(Finder f) => find.descendant(
    of: find.byType(DatePickerDialog),
    matching: f,
  );

  group('WFormDatePicker — 渲染', () {
    testWidgets('初始空值 → title 为空 + hintText 显示', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'birthday',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()..decoration = const InputDecoration(hintText: '选择日期'),
          ),
        ),
      );

      expect(find.text('选择日期'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('initialValue 非空 → 格式化显示', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'birthday',
            config: WFormDatePickerConfig(),
            initialValue: initialValue,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      expect(find.text(displayedText), findsOneWidget);
    });

    testWidgets('iconSize 默认 24 可自定义', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()..iconSize = 36,
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
      expect(icon.size, 36);
    });

    testWidgets('iconEnabledColor / iconDisabledColor 生效', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()
              ..iconEnabledColor = Colors.red
              ..iconDisabledColor = Colors.grey,
          ),
        ),
      );

      Icon icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
      expect(icon.color, Colors.red);

      // disabled
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            enabled: false,
            config: WFormDatePickerConfig()
              ..iconEnabledColor = Colors.red
              ..iconDisabledColor = Colors.grey,
          ),
        ),
      );
      icon = tester.widget<Icon>(find.byIcon(Icons.arrow_drop_down));
      expect(icon.color, Colors.grey);
    });

    testWidgets('自定义 icon 替换默认下拉图标', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()..icon = const Icon(Icons.calendar_today, size: 30),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('style 应用于显示文本', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            initialValue: initialValue,
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()
              ..style = const TextStyle(
                color: Colors.purple,
                fontSize: 18,
              ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(displayedText));
      final textStyle = textWidget.style;
      expect(textStyle?.color, Colors.purple);
      expect(textStyle?.fontSize, 18);
    });

    testWidgets('config 容器高度 / 装饰生效', (tester) async {
      const color = Color(0xFF123456);
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()
              ..height = 64
              ..containerDecoration = const BoxDecoration(color: color),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == color,
        ),
      );
      expect(container.constraints?.maxHeight, 64);
    });

    testWidgets('buildBordered → WFormBorderWithData 包装', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePickerConfig().buildBordered(
            name: 'd_border',
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      expect(find.byType(WFormBorderWithData), findsOneWidget);
      expect(find.byType(WFormDatePicker), findsOneWidget);
    });

    testWidgets('外层只读作用域 → 不可点击且语义为禁用', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormReadOnlyScope(
            readOnly: true,
            child: WFormDatePicker(
              name: 'd_readonly',
              firstDate: firstDate,
              lastDate: lastDate,
              config: WFormDatePickerConfig()..decoration = const InputDecoration(hintText: '只读日期'),
            ),
          ),
        ),
      );

      final buttonSemantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WFormDatePicker),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);
      expect(buttonSemantics.properties.enabled, isFalse);

      await tester.tap(find.text('只读日期'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('validator 暴露：formKey.validate() 执行并写入 errorText', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'validated_date',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig(),
            validator: (value) => value == null ? '请选择日期' : null,
          ),
        ),
      );

      expect(formData.formKey.currentState!.validate(), isFalse);
      expect(formData.formKey.currentState!.fields['validated_date']!.errorText, '请选择日期');
    });

    testWidgets('form reset 后 formEntered 同步复位', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'reset_date',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig(),
          ),
        ),
      );

      formData.didChange<String?>('reset_date', initialValue);
      await tester.pump();
      expect(formData.formEntered['reset_date'], isTrue);

      formData.formKey.currentState!.reset();
      await tester.pump();
      expect(formData.formEntered['reset_date'], isFalse);
    });
  });

  group('WFormDatePicker — DatePickerDialog 交互', () {
    testWidgets('点击 → 弹出 DatePickerDialog', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            firstDate: firstDate,
            lastDate: lastDate,
            config: WFormDatePickerConfig()..decoration = const InputDecoration(hintText: '点击选日期'),
          ),
        ),
      );

      await tester.tap(find.text('点击选日期'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('选日期 + OK → 更新 FormData', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // 关键：先 tap 日期 cell，再 tap OK（否则返回 null）
      await tester.tap(inDialog(find.text('1')));
      await tester.pump();
      await tester.tap(inDialog(find.text('OK')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      formData.formKey.currentState?.save();
      expect(formData.value['d1'], isNotNull);
      expect(formData.value['d1'], isA<String>());
      expect(formData.value['d1'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(formData.formEntered['d1'], isTrue);
    });

    testWidgets('Cancel → 不更新 FormData', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();

      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      formData.formKey.currentState?.save();
      expect(formData.value['d1'], isNull);
    });

    testWidgets('Cancel → 保留已有值', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd_keep',
            config: WFormDatePickerConfig(),
            firstDate: firstDate,
            lastDate: lastDate,
            initialValue: initialValue,
          ),
        ),
      );

      await tester.tap(find.text(displayedText));
      await tester.pumpAndSettle();

      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      formData.formKey.currentState?.save();
      expect(formData.value['d_keep'], initialValue);
    });
  });

  group('WFormDatePicker — 回归', () {
    testWidgets('选择日期后 onChanged 被触发（回归：曾用 setValue 导致永不回调）', (tester) async {
      final formData = WFormData();
      String? changed;
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            firstDate: firstDate,
            lastDate: lastDate,
            onChanged: (v) => changed = v,
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.text('1')));
      await tester.pump();
      await tester.tap(inDialog(find.text('OK')));
      await tester.pumpAndSettle();

      expect(changed, isNotNull);
      expect(changed, isA<String>());
    });

    testWidgets('enabled=false 时点击不弹出选择器（回归）', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            firstDate: firstDate,
            lastDate: lastDate,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('初始值早于 firstDate 时不崩溃（回归：曾触发框架 assert）', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            initialValue: '1800-01-01',
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('无法解析的初始值不崩溃（回归：曾抛 FormatException）', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        buildWrapped(
          formData: formData,
          child: WFormDatePicker(
            name: 'd1',
            config: WFormDatePickerConfig(),
            initialValue: 'not-a-date',
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });
}
