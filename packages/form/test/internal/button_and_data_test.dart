import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';
import 'package:w_tools_form/src/components/field_button.dart';
import 'package:w_tools_form/src/components/fields/text_field.dart';

void main() {
  group('WFormFieldButtonCore Widget', () {
    testWidgets('渲染 hintWidget', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('请选择'),
          name: 'choice',
          onTap: (value, didChange) {},
        ),
      );

      expect(find.text('请选择'), findsOneWidget);
    });

    testWidgets('initialValue 显示 selectedWidget 内容', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('请选择'),
          name: 'choice',
          initialValue: '选项A',
          onTap: (value, didChange) {},
          selectedWidgetBuilder: (v) => Text('已选: $v'),
        ),
      );

      expect(find.text('已选: 选项A'), findsOneWidget);
    });

    testWidgets('点击按钮触发 onTap', (tester) async {
      bool tapped = false;

      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('点我'),
          name: 'tap_test',
          selectedWidgetBuilder: (v) => Text('值: $v'),
          onTap: (value, didChange) {
            tapped = true;
            didChange('new_value');
          },
        ),
      );

      await tester.tap(find.text('点我'));
      await tester.pumpAndSettle();

      expect(tapped, true);
      // 点击后 selectedWidgetBuilder 渲染 '值: new_value'
      expect(find.text('值: new_value'), findsOneWidget);
    });

    testWidgets('enabled=false 时点击不触发 onTap', (tester) async {
      bool tapped = false;
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('禁用'),
          enabled: false,
          name: 'disabled',
          onTap: (value, didChange) {
            tapped = true;
          },
        ),
      );

      // 禁用态视觉半透明
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(WFormFieldButtonCore<String>),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);

      await tester.tap(find.text('禁用'));
      await tester.pump();
      expect(tapped, false);
    });

    testWidgets('build(enabled: false) 覆盖配置', (tester) async {
      bool tapped = false;
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('覆盖禁用'),
          name: 'override_btn',
          enabled: false,
          onTap: (_, __) {
            tapped = true;
          },
        ),
      );

      await tester.tap(find.text('覆盖禁用'));
      await tester.pump();

      expect(tapped, false);
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(WFormFieldButtonCore<String>),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('点击 didChange 同步 formEntered', (tester) async {
      final formData = WFormController();
      await pumpForm(
        tester,
        formData: formData,
        child: buttonCore(
          hintWidget: const Text('选择'),
          name: 'entered_btn',
          onTap: (value, didChange) => didChange('a'),
        ),
      );

      await tester.tap(find.text('选择'));
      await tester.pump();

      expect(formData.formEntered['entered_btn'], isTrue);
    });

    testWidgets('form reset 后 formEntered 同步复位', (tester) async {
      final formData = WFormController();
      await pumpForm(
        tester,
        formData: formData,
        child: buttonCore(
          hintWidget: const Text('重置按钮'),
          name: 'reset_btn',
          onTap: (_, didChange) => didChange('a'),
        ),
      );

      await tester.tap(find.text('重置按钮'));
      await tester.pump();
      expect(formData.formEntered['reset_btn'], isTrue);

      formData.formKey.currentState!.reset();
      await tester.pump();
      expect(formData.formEntered['reset_btn'], isFalse);
    });

    testWidgets('具备 button 语义与启用状态', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(hintWidget: const Text('语义'), name: 'semantic_btn', onTap: (_, __) {}),
      );

      final buttonSemantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WFormFieldButtonCore<String>),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);

      expect(buttonSemantics.properties.enabled, isTrue);
    });

    testWidgets('禁用态语义 enabled=false', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('禁用语义'),
          enabled: false,
          name: 'semantic_disabled_btn',
          onTap: (_, __) {},
        ),
      );

      final buttonSemantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WFormFieldButtonCore<String>),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);

      expect(buttonSemantics.properties.enabled, isFalse);
    });

    testWidgets('leading / actions 渲染在按钮两侧', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('带附加内容'),
          leading: const Icon(Icons.star),
          actions: [const Icon(Icons.add), const Icon(Icons.remove)],
          name: 'decorated_btn',
          onTap: (_, __) {},
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.text('带附加内容'), findsOneWidget);
    });

    testWidgets('yOffset 平移按钮内容', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('偏移'),
          yOffset: 6,
          name: 'offset_btn',
          onTap: (_, __) {},
        ),
      );

      final transformed = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(WFormFieldButtonCore<String>),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((container) => container.transform != null);

      expect(transformed.transform!.getTranslation().y, 6);
    });

    testWidgets('外层只读作用域下不可点击', (tester) async {
      bool tapped = false;
      await pumpForm(
        tester,
        child: WFormReadOnlyScope(
          readOnly: true,
          child: buttonCore(
            hintWidget: const Text('只读'),
            name: 'readonly_btn',
            onTap: (value, didChange) {
              tapped = true;
              didChange('x');
            },
          ),
        ),
      );

      await tester.tap(find.text('只读'));
      await tester.pump();

      expect(tapped, false);
    });

    testWidgets('height / width 渲染到外层容器', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('尺寸'),
          height: 48,
          width: 200,
          name: 'size_btn',
          onTap: (_, __) {},
        ),
      );

      final size = tester.getSize(find.byType(WFormFieldButtonCore<String>));
      expect(size.width, 200);
      expect(size.height, 48);
    });

    testWidgets('validator / focusNode 透传到内部字段', (tester) async {
      final formData = WFormController();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpForm(
        tester,
        formData: formData,
        child: buttonCore(
          hintWidget: const Text('校验'),
          bordered: true,
          name: 'validated_btn',
          validator: (value) => value == null || value.isEmpty ? '必填' : null,
          focusNode: focusNode,
          onTap: (_, __) {},
        ),
      );

      final button = tester.widget<WFormFieldButtonCore<String>>(
        find.byType(WFormFieldButtonCore<String>),
      );
      expect(button.validator, isNotNull);
      expect(button.focusNode, same(focusNode));
      expect(formData.formKey.currentState!.validate(), isFalse);
    });

    testWidgets('build(bordered: true) → WFormFieldShell 包装', (tester) async {
      await pumpForm(
        tester,
        child: buttonCore(
          hintWidget: const Text('边框按钮'),
          bordered: true,
          name: 'btn_border',
          onTap: (_, __) {},
        ),
      );

      expect(find.byType(WFormFieldShell), findsOneWidget);
      expect(find.byType(WFormFieldButtonCore<String>), findsOneWidget);
      expect(find.text('边框按钮'), findsOneWidget);
    });
  });

  group('WFormController', () {
    testWidgets('isAllEntered — 初始时 false', (tester) async {
      final data = WFormController();
      expect(data.isAllEntered(const ['a']), false);
    });

    testWidgets('formEntered 按字段值实时派生（string / bool / 集合）', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const Column(
          children: [
            WFormTextField(name: 'name'),
            WFormCheckbox(name: 'agree', title: Text('同意')),
            WFormMultiDropdown(name: 'tags', items: {'a': 'A'}),
          ],
        ),
      );

      expect(data.formEntered['name'], isFalse); // 空字符串
      data.updateValue('name', 'x');
      await tester.pump();
      expect(data.formEntered['name'], isTrue);

      expect(data.formEntered['agree'], isFalse); // 初始 false 视为未输入
      data.updateValue('agree', true);
      await tester.pump();
      expect(data.formEntered['agree'], isTrue);

      expect(data.formEntered['tags'], isFalse); // null
      data.updateValue('tags', {'a'});
      await tester.pump();
      expect(data.formEntered['tags'], isTrue);
    });

    testWidgets('isAllEntered 按字段值判断', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const Column(
          children: [
            WFormTextField(name: 'a'),
            WFormTextField(name: 'b'),
          ],
        ),
      );

      expect(data.isAllEntered(const ['a']), isFalse);
      data.updateValue('a', 'x');
      await tester.pump();
      expect(data.isAllEntered(const ['a']), isTrue);
      expect(data.isAllEntered(const ['a', 'b']), isFalse);
      expect(data.isAllEntered(const ['a', 'missing']), isFalse);
      expect(data.isAllEntered(const []), isFalse);
    });

    testWidgets('formEntered 只包含当前已挂载字段', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextField(name: 'a'),
      );

      expect(data.formEntered.keys, ['a']);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(data.formEntered, isEmpty);
    });
  });

  group('WFormController — 辅助 API', () {
    testWidgets('didChange / getFieldsValue 按字段名读写', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextFieldCore(name: 'a'),
      );

      expect(data.getFieldsValue('a'), isNull);

      data.setValue('a', 'hello');
      await tester.pump();

      expect(data.getFieldsValue('a'), 'hello');
    });

    testWidgets('updateValue 同时写值和输入状态', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextFieldCore(name: 'a'),
      );

      data.updateValue<String>('a', 'hello');
      await tester.pump();

      expect(data.getFieldsValue<String>('a'), 'hello');
      expect(data.formEntered['a'], isTrue);
    });

    testWidgets('裸字段卸载时清理 formEntered', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextFieldCore(name: 'raw'),
      );

      data.updateValue('raw', 'x');
      await tester.pump();
      expect(data.formEntered['raw'], isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(data.formEntered.containsKey('raw'), isFalse);
    });

    testWidgets('未挂载时 validate 返回 false', (tester) async {
      expect(WFormController().validate(), isFalse);
    });

    testWidgets('clearValue 清空值并复位输入状态', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextFieldCore(name: 'a'),
      );

      data.updateValue<String>('a', 'hello');
      data.clearValue('a');
      await tester.pump();

      expect(data.getFieldsValue<String>('a'), isNull);
      expect(data.formEntered['a'], isFalse);
    });

    testWidgets('validate 自动使用字段 validator', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: WFormTextFieldCore(
          name: 'email',
          validator: (value) => (value == null || value.isEmpty) ? '必填' : null,
        ),
      );

      expect(data.validate(), isFalse);
      data.updateValue<String>('email', 'a@b.com');
      await tester.pump();
      expect(data.validate(), isTrue);
    });

    testWidgets('validators() 工厂可创建并执行校验器', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const WFormTextFieldCore(name: 'a'),
      );

      final validators = data.validators(
        items: [
          WFormValidatorItem(
            fieldName: 'a',
            validatorBuilder: () =>
                (v) => (v == null || v.toString().isEmpty) ? '必填' : null,
          ),
        ],
      );

      expect(validators.validate(), isFalse);

      data.setValue('a', 'x');
      await tester.pump();
      expect(validators.validate(), isTrue);
    });
  });

  group('WFormController — 清空 / 重置语义', () {
    testWidgets('clearValue 对 bool / Set 字段不是类型安全的清空', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const Column(
          children: [
            WFormCheckbox(name: 'agree', title: Text('同意'), initialValue: true),
            WFormMultiDropdown(name: 'tags', items: {'a': 'A'}, initialValue: {'a'}),
          ],
        ),
      );

      data.clearValue('agree');
      data.clearValue('tags');
      await tester.pump();

      // 现状：clearValue 一律写 null —— 对非可空类型来说语义不明确。
      expect(data.value['agree'], isNull);
      expect(data.value['tags'], isNull);
    });

    testWidgets('resetValue 把字段回到自身 initialValue', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: const Column(
          children: [
            WFormCheckbox(name: 'agree', title: Text('同意'), initialValue: true),
            WFormMultiDropdown(name: 'tags', items: {'a': 'A'}, initialValue: {'a'}),
          ],
        ),
      );

      data.clearValue('agree');
      data.clearValue('tags');
      await tester.pump();
      data.resetValue('agree');
      data.resetValue('tags');
      await tester.pump();

      expect(data.value['agree'], isTrue);
      expect(data.value['tags'], {'a'});
    });
  });
}
