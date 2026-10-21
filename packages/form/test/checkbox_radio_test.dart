import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

void main() {
  group('WFormCheckbox Widget', () {
    testWidgets('默认未选中时显示 checkboxUnselectedIcon', (tester) async {
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'agree',
          title: const Text('我同意'),
          initialValue: false,
        ),
      );
      expect(find.text('我同意'), findsOneWidget);
      // 默认未选中图标是 Icons.check_box_outline_blank
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('initialValue=true 显示选中图标', (tester) async {
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'agree',
          title: const Text('同意'),
          initialValue: true,
        ),
      );
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('点击切换选中/未选中', (tester) async {
      bool? lastValue;
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'toggle',
          title: const Text('点我'),
          initialValue: false,
          onChanged: (v) => lastValue = v,
        ),
      );

      // 初始未选中
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      // 点击切换为选中
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pump();
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(lastValue, true);

      // 再点击切换回未选中
      await tester.tap(find.byIcon(Icons.check_box));
      await tester.pump();
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(lastValue, false);
    });

    testWidgets('点击 title 区域也能切换', (tester) async {
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'title_tap',
          title: const Text('标题可点击'),
          initialValue: false,
        ),
      );

      await tester.tap(find.text('标题可点击'));
      await tester.pump();
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('值为 null 时点击可切换为选中', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormCheckboxConfig().build(
          name: 'null_value',
          title: const Text('空值'),
          initialValue: false,
        ),
      );

      formData.didChange<bool?>('null_value', null);
      await tester.pump();
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pump();
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('点击后同步 formEntered', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormCheckboxConfig().build(
          name: 'entered',
          title: const Text('记录输入'),
          initialValue: false,
        ),
      );

      await tester.tap(find.text('记录输入'));
      await tester.pump();
      expect(formData.formEntered['entered'], isTrue);
    });

    testWidgets('form reset 后 formEntered 同步复位', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormCheckboxConfig().build(
          name: 'reset_checkbox',
          title: const Text('重置复选框'),
          initialValue: false,
        ),
      );

      await tester.tap(find.text('重置复选框'));
      await tester.pump();
      expect(formData.formEntered['reset_checkbox'], isTrue);

      formData.formKey.currentState!.reset();
      await tester.pump();
      expect(formData.formEntered['reset_checkbox'], isFalse);
    });

    testWidgets('validator 暴露：formKey.validate() 执行并写入 errorText', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormCheckboxConfig().build(
          name: 'validated_checkbox',
          title: const Text('同意协议'),
          validator: (value) => value == true ? null : '请勾选',
        ),
      );

      expect(formData.formKey.currentState!.validate(), isFalse);
      expect(formData.formKey.currentState!.fields['validated_checkbox']!.errorText, '请勾选');
    });

    testWidgets('build(enabled: false) 覆盖配置', (tester) async {
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'override_disabled',
          title: const Text('覆盖禁用'),
          initialValue: false,
          enabled: false,
        ),
      );

      await tester.tap(find.text('覆盖禁用'));
      await tester.pump();
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('enabled=false 时点击不切换', (tester) async {
      await pumpForm(
        tester,
        child: (WFormCheckboxConfig()..enabled = false).build(
          name: 'disabled',
          title: const Text('禁用'),
          initialValue: false,
        ),
      );

      await tester.tap(find.text('禁用'));
      await tester.pump();
      // 图标不变
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    });

    testWidgets('自定义 selectedIcon / unselectedIcon', (tester) async {
      final config = WFormCheckboxConfig()
        ..selectedIcon = const Icon(Icons.star)
        ..unselectedIcon = const Icon(Icons.star_border);

      await pumpForm(
        tester,
        child: config.build(
          name: 'custom',
          title: const Text('自定义图标'),
          initialValue: false,
        ),
      );
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('build 返回 WFormCheckbox', (tester) async {
      final config = WFormCheckboxConfig();
      final cb = config.build(name: 'x', title: const Text('t')) as WFormCheckbox;
      expect(cb, isA<WFormCheckbox>());
      expect(cb.name, 'x');
    });

    testWidgets('build(bordered: true) → WFormBorderWithData 包装', (tester) async {
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          bordered: true,
          name: 'cb_border',
          title: const Text('边框复选框'),
        ),
      );

      expect(find.byType(WFormBorderWithData), findsOneWidget);
      expect(find.byType(WFormCheckbox), findsOneWidget);
    });

    testWidgets('选项具备 checkbox 语义', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpForm(
        tester,
        child: WFormCheckboxConfig().build(
          name: 'cb_semantic',
          title: const Text('语义'),
          initialValue: true,
        ),
      );

      final checkedFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.checked == true,
      );
      expect(checkedFinder, findsOneWidget);

      final data = tester.getSemantics(checkedFinder).getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);

      handle.dispose();
    });
  });

  group('WFormRadioGroup Widget', () {
    testWidgets('渲染所有选项', (tester) async {
      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
          name: 'fruit',
          items: const {'a': '苹果', 'b': '香蕉', 'c': '樱桃'},
        ),
      );
      expect(find.text('苹果'), findsOneWidget);
      expect(find.text('香蕉'), findsOneWidget);
      expect(find.text('樱桃'), findsOneWidget);
    });

    testWidgets('initialValue 指定选中项', (tester) async {
      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
          name: 'color',
          items: const {'r': '红', 'g': '绿', 'b': '蓝'},
          initialValue: 'g',
        ),
      );
      // '绿' 对应的图标应该是 radioSelectedIcon
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('点击选项切换选中', (tester) async {
      String? lastValue;
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormRadioGroupConfig().build<String>(
          name: 'pick',
          items: const {'x': 'X', 'y': 'Y'},
          initialValue: 'x',
          onChanged: (v) => lastValue = v,
        ),
      );

      // 点击 'Y'
      await tester.tap(find.text('Y'));
      await tester.pump();
      expect(lastValue, 'y');
      expect(formData.formEntered['pick'], isTrue);
    });

    testWidgets('form reset 后 formEntered 同步复位', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormRadioGroupConfig().build<String>(
          name: 'reset_radio',
          items: const {'x': 'X', 'y': 'Y'},
        ),
      );

      await tester.tap(find.text('Y'));
      await tester.pump();
      expect(formData.formEntered['reset_radio'], isTrue);

      formData.formKey.currentState!.reset();
      await tester.pump();
      expect(formData.formEntered['reset_radio'], isFalse);
    });

    testWidgets('validator 暴露：formKey.validate() 执行并写入 errorText', (tester) async {
      final formData = WFormData();
      await pumpForm(
        tester,
        formData: formData,
        child: WFormRadioGroupConfig().build<String>(
          name: 'validated_radio',
          items: const {'x': 'X', 'y': 'Y'},
          validator: (value) => value == null ? '请选择' : null,
        ),
      );

      expect(formData.formKey.currentState!.validate(), isFalse);
      expect(formData.formKey.currentState!.fields['validated_radio']!.errorText, '请选择');
    });

    testWidgets('build(enabled: false) 覆盖配置', (tester) async {
      String? lastValue;
      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
          name: 'override_disabled',
          items: const {'a': 'A', 'b': 'B'},
          initialValue: 'a',
          enabled: false,
          onChanged: (v) => lastValue = v,
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastValue, isNull);
    });

    testWidgets('enabled=false 时点击不生效', (tester) async {
      String? lastValue;
      await pumpForm(
        tester,
        child: (WFormRadioGroupConfig()..enabled = false).build<String>(
          name: 'disabled_pick',
          items: const {'a': 'A', 'b': 'B'},
          initialValue: 'a',
          onChanged: (v) => lastValue = v,
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastValue, isNull);
    });

    testWidgets('选项具备 radio 语义（checked + 互斥组）', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
          name: 'semantic',
          items: const {'x': 'X', 'y': 'Y'},
          initialValue: 'x',
        ),
      );

      final radioFinder = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.inMutuallyExclusiveGroup ?? false),
      );
      expect(radioFinder, findsNWidgets(2));

      final data = tester.getSemantics(radioFinder.first).getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);

      handle.dispose();
    });

    testWidgets('build 返回 WFormRadioGroup', (tester) async {
      final config = WFormRadioGroupConfig();
      final radio =
          config.build<String>(
                name: 'x',
                items: const {'k': 'v'},
              )
              as WFormRadioGroup<String>;
      expect(radio, isA<WFormRadioGroup<String>>());
      expect(radio.name, 'x');
    });

    testWidgets('build(bordered: true) → WFormBorderWithData 包装', (tester) async {
      await pumpForm(
        tester,
        child: WFormRadioGroupConfig().build<String>(
          bordered: true,
          name: 'radio_border',
          items: const {'a': 'A'},
        ),
      );

      expect(find.byType(WFormBorderWithData), findsOneWidget);
      expect(find.byType(WFormRadioGroup<String>), findsOneWidget);
    });
  });
}
