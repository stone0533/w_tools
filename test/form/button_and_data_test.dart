import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

void main() {
  group('WFormButton Widget', () {
    testWidgets('渲染 hintWidget', (tester) async {
      final config = WFormButtonConfig()..hintWidget = const Text('请选择');

      await pumpForm(
        tester,
        child: config.build(
          name: 'choice',
          onTap: (value, didChange) {},
        ),
      );

      expect(find.text('请选择'), findsOneWidget);
    });

    testWidgets('initialValue 显示 selectedWidget 内容', (tester) async {
      final config = WFormButtonConfig()..hintWidget = const Text('请选择');

      await pumpForm(
        tester,
        child: config.build(
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

      final config = WFormButtonConfig()..hintWidget = const Text('点我');

      await pumpForm(
        tester,
        child: config.build(
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
      final config = WFormButtonConfig()
        ..hintWidget = const Text('禁用')
        ..enabled = false;

      await pumpForm(
        tester,
        child: config.build(
          name: 'disabled',
          onTap: (value, didChange) {
            tapped = true;
          },
        ),
      );

      // 禁用态视觉半透明
      final opacity = tester.widget<Opacity>(
        find.descendant(of: find.byType(WFormButton), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0.5);

      await tester.tap(find.text('禁用'));
      await tester.pump();
      expect(tapped, false);
    });

    testWidgets('build(enabled: false) 覆盖配置', (tester) async {
      bool tapped = false;
      final config = WFormButtonConfig()..hintWidget = const Text('覆盖禁用');

      await pumpForm(
        tester,
        child: config.build(
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
        find.descendant(of: find.byType(WFormButton), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('点击 didChange 同步 formEntered', (tester) async {
      final formData = WFormData();
      final config = WFormButtonConfig()..hintWidget = const Text('选择');

      await pumpForm(
        tester,
        formData: formData,
        child: config.build(
          name: 'entered_btn',
          onTap: (value, didChange) => didChange('a'),
        ),
      );

      await tester.tap(find.text('选择'));
      await tester.pump();

      expect(formData.formEntered['entered_btn'], isTrue);
    });

    testWidgets('form reset 后 formEntered 同步复位', (tester) async {
      final formData = WFormData();
      final config = WFormButtonConfig()..hintWidget = const Text('重置按钮');

      await pumpForm(
        tester,
        formData: formData,
        child: config.build(
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
      final config = WFormButtonConfig()..hintWidget = const Text('语义');

      await pumpForm(
        tester,
        child: config.build(name: 'semantic_btn', onTap: (_, __) {}),
      );

      final buttonSemantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WFormButton),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);

      expect(buttonSemantics.properties.enabled, isTrue);
    });

    testWidgets('禁用态语义 enabled=false', (tester) async {
      final config = WFormButtonConfig()
        ..hintWidget = const Text('禁用语义')
        ..enabled = false;

      await pumpForm(
        tester,
        child: config.build(name: 'semantic_disabled_btn', onTap: (_, __) {}),
      );

      final buttonSemantics = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(WFormButton),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((s) => s.properties.button == true);

      expect(buttonSemantics.properties.enabled, isFalse);
    });

    testWidgets('leading / actions 渲染在按钮两侧', (tester) async {
      final config = WFormButtonConfig()
        ..hintWidget = const Text('带附加内容')
        ..leading = const Icon(Icons.star)
        ..actions = const [Icon(Icons.add), Icon(Icons.remove)];

      await pumpForm(
        tester,
        child: config.build(name: 'decorated_btn', onTap: (_, __) {}),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.text('带附加内容'), findsOneWidget);
    });

    testWidgets('yOffset 平移按钮内容', (tester) async {
      final config = WFormButtonConfig()
        ..hintWidget = const Text('偏移')
        ..yOffset = 6;

      await pumpForm(
        tester,
        child: config.build(name: 'offset_btn', onTap: (_, __) {}),
      );

      final transformed = tester
          .widgetList<Container>(
            find.descendant(of: find.byType(WFormButton), matching: find.byType(Container)),
          )
          .firstWhere((container) => container.transform != null);

      expect(transformed.transform!.getTranslation().y, 6);
    });

    testWidgets('外层只读作用域下不可点击', (tester) async {
      bool tapped = false;
      final config = WFormButtonConfig()..hintWidget = const Text('只读');

      await pumpForm(
        tester,
        child: WFormReadOnlyScope(
          readOnly: true,
          child: config.build(
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

    testWidgets('WFormButtonConfig.build 返回 WFormButton', (tester) async {
      final config = WFormButtonConfig();
      final btn = config.build(
        name: 'x',
        onTap: (_, __) {},
      );
      expect(btn, isA<WFormButton>());
      expect(btn.name, 'x');
    });

    testWidgets('height / width 渲染到外层容器', (tester) async {
      final config = WFormButtonConfig()
        ..hintWidget = const Text('尺寸')
        ..height = 48
        ..width = 200;

      await pumpForm(
        tester,
        child: config.build(name: 'size_btn', onTap: (_, __) {}),
      );

      final size = tester.getSize(find.byType(WFormButton));
      expect(size.width, 200);
      expect(size.height, 48);
    });

    testWidgets('setter 传 null 可清空配置', (tester) async {
      final config = WFormButtonConfig()
        ..hintWidget = const Text('可清空')
        ..height = 40
        ..width = 100
        ..containerPadding = const EdgeInsets.all(8);

      config
        ..hintWidget = null
        ..height = null
        ..width = null
        ..containerPadding = null;

      await pumpForm(
        tester,
        child: config.build(name: 'cleared_btn', onTap: (_, __) {}),
      );

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(WFormButton), matching: find.byType(Container)).first,
      );
      expect(container.constraints, isNull);
      expect(container.padding, isNull);
      expect(find.text('可清空'), findsNothing);
    });

    testWidgets('validator / focusNode 透传到内部字段', (tester) async {
      final formData = WFormData();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      final config = WFormButtonConfig()..hintWidget = const Text('校验');

      await pumpForm(
        tester,
        formData: formData,
        child: config.buildBordered(
          name: 'validated_btn',
          validator: (value) => value == null || value.isEmpty ? '必填' : null,
          focusNode: focusNode,
          onTap: (_, __) {},
        ),
      );

      final button = tester.widget<WFormButton>(find.byType(WFormButton));
      expect(button.validator, isNotNull);
      expect(button.focusNode, same(focusNode));
      expect(formData.formKey.currentState!.validate(), isFalse);
    });

    testWidgets('buildBordered → WFormBorderWithData 包装', (tester) async {
      final config = WFormButtonConfig()..hintWidget = const Text('边框按钮');

      await pumpForm(
        tester,
        child: config.buildBordered(
          name: 'btn_border',
          onTap: (_, __) {},
        ),
      );

      expect(find.byType(WFormBorderWithData), findsOneWidget);
      expect(find.byType(WFormButton), findsOneWidget);
      expect(find.text('边框按钮'), findsOneWidget);
    });
  });

  group('WFormData', () {
    testWidgets('isAllEntered — 初始时 false', (tester) async {
      final data = WFormData();
      expect(data.isAllEntered(1), false);
    });

    testWidgets('onChange — 非 String 值也维护 formEntered', (tester) async {
      final data = WFormData();
      // 数字：按 value != null 判定
      data.onChange('count', 1);
      expect(data.formEntered['count'], true);
      data.onChange<int>('count', null);
      expect(data.formEntered['count'], false);
      // 集合：按 isNotEmpty 判定
      data.onChange('tags', <String>['a']);
      expect(data.formEntered['tags'], true);
      data.onChange('tags', <String>[]);
      expect(data.formEntered['tags'], false);
      // 字符串：按 isNotEmpty 判定
      data.onChange('name', '');
      expect(data.formEntered['name'], false);
      data.onChange('name', 'x');
      expect(data.formEntered['name'], true);
      // 布尔：false 视为未输入（与表单 reset 语义一致）
      data.onChange('agree', true);
      expect(data.formEntered['agree'], true);
      data.onChange('agree', false);
      expect(data.formEntered['agree'], false);
    });

    testWidgets('ensureBorderKey — 返回同一个 key（单例模式）', (tester) async {
      final data = WFormData();
      final k1 = data.ensureBorderKey('field');
      final k2 = data.ensureBorderKey('field');
      expect(k1, same(k2));
    });

    testWidgets('formKey — 不同 WFormData 实例有不同 formKey', (tester) async {
      final data1 = WFormData();
      final data2 = WFormData();
      expect(data1.formKey, isNot(same(data2.formKey)));
    });

    testWidgets('closeKeyboard — 不抛异常', (tester) async {
      await pumpForm(tester, child: const SizedBox.shrink());
      final data = WFormData();
      data.closeKeyboard();
      // 不抛异常 = 通过
    });

    testWidgets('isAllEntered — 全部为 true 时返回 true', (tester) async {
      final data = WFormData();
      data.formEntered['a'] = true;
      data.formEntered['b'] = true;
      expect(data.isAllEntered(2), true);
    });

    testWidgets('isAllEntered — 有一个为 false 时返回 false', (tester) async {
      final data = WFormData();
      data.formEntered['a'] = true;
      data.formEntered['b'] = false;
      expect(data.isAllEntered(2), false);
    });

    testWidgets('isAllEntered — 忽略已卸载字段的陈旧记录', (tester) async {
      final data = WFormData();
      await pumpForm(
        tester,
        formData: data,
        child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
      );

      data.onChange('a', 'x');
      data.onChange('unmounted', 'y');

      expect(data.isAllEntered(1), isTrue);
    });
  });

  group('WFormData — 辅助 API', () {
    testWidgets('didChange / getFieldsValue 按字段名读写', (tester) async {
      final data = WFormData();
      await pumpForm(
        tester,
        formData: data,
        child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
      );

      expect(data.getFieldsValue('a'), isNull);

      data.didChange('a', 'hello');
      await tester.pump();

      expect(data.getFieldsValue('a'), 'hello');
    });

    testWidgets('validators() 工厂可创建并执行校验器', (tester) async {
      final data = WFormData();
      await pumpForm(
        tester,
        formData: data,
        child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
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

      data.didChange('a', 'x');
      await tester.pump();
      expect(validators.validate(), isTrue);
    });
  });
}
