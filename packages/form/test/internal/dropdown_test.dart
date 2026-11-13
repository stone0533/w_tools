import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import 'package:w_tools_form/src/components/field_assembly.dart';

import '_helpers/form_test_scaffold.dart';
import 'package:w_tools_form/src/components/fields/dropdown.dart';
import 'package:w_tools_form/src/components/fields/multi_dropdown.dart';

void main() {
  group('WFormDropdownCore<T> — Widget', () {
    Widget buildDropdown({
      required String name,
      required Map<String, String> items,
      String? hintText,
      String? initialValue,
      bool enabled = true,
      Widget? icon,
      TextStyle? style,
      TextStyle? hintStyle,
      EdgeInsetsGeometry? contentPadding,
      Color? dropdownColor,
      double? height,
      double? yOffset,
      Widget? leading,
      List<Widget>? actions,
      double? width,
    }) {
      final formData = WFormController();
      return MaterialApp(
        home: Scaffold(
          body: themedScope(
            formData: formData,
            child: WFormDropdownCore<String>(
              name: name,
              items: items,
              hintText: hintText,
              initialValue: initialValue,
              enabled: enabled,
              icon: icon,
              style: style,
              hintStyle: hintStyle,
              contentPadding: contentPadding,
              dropdownColor: dropdownColor,
              height: height,
              yOffset: yOffset,
              leading: leading,
              actions: actions,
              width: width,
            ),
          ),
        ),
      );
    }

    testWidgets('基本渲染 — items 显示 + hint', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果', 'b': '香蕉', 'c': '樱桃'},
          hintText: '请选择水果',
        ),
      );

      expect(find.text('请选择水果'), findsOneWidget);
      expect(find.byType(WFormDropdownCore<String>), findsOneWidget);
    });

    testWidgets('无 WFormScope → 抛 Exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WFormDropdownCore<String>(
              name: 'fruit',
              items: {'a': '苹果'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('initialValue 非空 → 显示选中值', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果', 'b': '香蕉'},
          initialValue: 'b',
        ),
      );

      expect(find.text('香蕉'), findsOneWidget);
    });

    testWidgets('enabled=false → DropdownButton disabled', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果'},
          enabled: false,
        ),
      );

      final dBtn = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dBtn.onChanged, isNull); // disabled → onChanged=null
    });

    testWidgets('点击 dropdown → 弹出 menu', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果', 'b': '香蕉', 'c': '樱桃'},
          hintText: '选水果',
        ),
      );

      // tap DropdownButton
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // DropdownMenu 弹出
      expect(find.text('苹果'), findsOneWidget);
      expect(find.text('香蕉'), findsOneWidget);
      expect(find.text('樱桃'), findsOneWidget);
    });

    testWidgets('选择项 → FormData 更新 + onChanged 回调', (tester) async {
      String? changedValue;
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              child: WFormDropdownCore<String>(
                name: 'fruit',
                items: const {'a': '苹果', 'b': '香蕉'},
                hintText: '选水果',
                onChanged: (v) => changedValue = v,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('香蕉').last);
      await tester.pumpAndSettle();

      // onChanged 被触发
      expect(changedValue, 'b');
      // FormData 里更新
      formData.formKey.currentState?.save();
      expect(formData.value['fruit'], 'b');
    });

    testWidgets('custom leading/icon 渲染', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果'},
          hintText: '选',
          leading: const Icon(Icons.pin),
          icon: const Icon(Icons.expand_more),
        ),
      );

      expect(find.byIcon(Icons.pin), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('外层 height / width 生效', (tester) async {
      await tester.pumpWidget(
        buildDropdown(
          name: 'fruit',
          items: const {'a': '苹果'},
          hintText: '选',
          height: 60,
          width: 200,
        ),
      );

      // 外层 Container 使用 config.height / width
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(WFormDropdownCore<String>),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxHeight, 60);
      expect(container.constraints?.maxWidth, 200);
    });

    testWidgets('build(bordered: true) → 返回带 WFormFieldShell', (tester) async {
      final formBorderCfg = TestFormBorderBuilder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: formBorderCfg.buildStyle(),
              child: assembleFormField(
                name: 'fruit',
                bordered: true,
                child: const WFormDropdownCore<String>(
                  name: 'fruit',
                  items: {'a': '苹果'},
                  hintText: '选',
                ),
              ),
            ),
          ),
        ),
      );

      // WFormFieldShell 包含 WFormDropdownCore
      expect(find.byType(WFormFieldShell), findsOneWidget);
      expect(find.byType(WFormDropdownCore<String>), findsOneWidget);
    });

    testWidgets('build(bordered: true) readOnly → 外层只读 + 内层禁用', (tester) async {
      final formBorderCfg = TestFormBorderBuilder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: WFormController(),
              formBorderStyle: formBorderCfg.buildStyle(),
              child: assembleFormField(
                name: 'fruit',
                bordered: true,
                readOnly: true,
                child: const WFormDropdownCore<String>(
                  name: 'fruit',
                  items: {'a': '苹果'},
                ),
              ),
            ),
          ),
        ),
      );

      final border = tester.widget<WFormFieldShell>(find.byType(WFormFieldShell));
      expect(border.readOnly, isTrue);
      final button = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(button.onChanged, isNull);
    });
  });

  Widget buildMulti({
    required String name,
    required Map<String, String> items,
    Set<String>? initialValue,
    Set<String>? disabledKeys,
    ValueChanged<Set<String>>? onChanged,
    String? hintText,
    double? width,
    bool? enabled,
    Widget? icon,
    double? iconSize,
    Widget? checkboxUnselectedIcon,
    Widget? checkboxSelectedIcon,
    Widget? checkboxDisabledIcon,
    TextStyle? style,
    TextStyle? hintStyle,
    EdgeInsets? popUpLayerPadding,
    EdgeInsetsGeometry? itemPadding,
    TextStyle? itemStyle,
    TextStyle? itemCheckedStyle,
    TextStyle? itemDisabledStyle,
    EdgeInsets? itemTitlePadding,
    double? height,
    double? yOffset,
    Widget? leading,
    List<Widget>? actions,
    Decoration? containerDecoration,
    EdgeInsetsGeometry? containerMargin,
    EdgeInsetsGeometry? containerPadding,
  }) {
    final formData = WFormController();
    return MaterialApp(
      home: Scaffold(
        body: themedScope(
          formData: formData,
          child: WFormMultiDropdownCore(
            name: name,
            items: items,
            initialValue: initialValue,
            onChanged: onChanged,
            hintText: hintText,
            icon: icon,
            iconSize: iconSize,
            checkboxUnselectedIcon: checkboxUnselectedIcon,
            checkboxSelectedIcon: checkboxSelectedIcon,
            checkboxDisabledIcon: checkboxDisabledIcon,
            style: style,
            hintStyle: hintStyle,
            popUpLayerPadding: popUpLayerPadding,
            itemPadding: itemPadding,
            itemStyle: itemStyle,
            itemCheckedStyle: itemCheckedStyle,
            itemDisabledStyle: itemDisabledStyle,
            itemTitlePadding: itemTitlePadding,
            height: height,
            yOffset: yOffset,
            leading: leading,
            actions: actions,
            containerDecoration: containerDecoration,
            containerMargin: containerMargin,
            containerPadding: containerPadding,
            disabledKeys: disabledKeys ?? const <String>{},
            width: width,
            enabled: enabled ?? true,
          ),
        ),
      ),
    );
  }

  testWidgets('基本渲染 — 未配置 hintText 不显示占位', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': '美食', 'b': '旅游', 'c': '购物'},
      ),
    );

    expect(find.text('ALL'), findsNothing);
  });

  testWidgets('initialValue → 显示逗号分隔文本', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': '美食', 'b': '旅游', 'c': '购物'},
        initialValue: {'a', 'c'},
      ),
    );

    expect(find.text('美食, 购物'), findsOneWidget);
  });

  testWidgets('键可包含逗号（值不再使用逗号编码）', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a,b': 'A,B', 'c': 'C'},
        initialValue: const {'a,b'},
      ),
    );

    expect(find.text('A,B'), findsOneWidget);
  });

  testWidgets('未选择时显示 hintText 占位', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': 'A'},
        hintText: '请选择',
      ),
    );

    expect(find.text('请选择'), findsOneWidget);
  });

  testWidgets('点击选项 → onChanged 收到 Set', (tester) async {
    Set<String>? changed;
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': 'A', 'b': 'B'},
        onChanged: (v) => changed = v,
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pump();

    expect(changed, {'a'});
  });

  testWidgets('弹层选项具备 checked / enabled 语义', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': 'A', 'b': 'B'},
        initialValue: const {'a'},
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    final checked = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.checked == true);
    expect(checked, isNotEmpty);
  });

  testWidgets('点击 → WFormPopup.show 弹出选项', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': '美食', 'b': '旅游', 'c': '购物'},
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    // 弹出层显示所有 item
    expect(find.text('美食'), findsOneWidget);
    expect(find.text('旅游'), findsOneWidget);
    expect(find.text('购物'), findsOneWidget);
  });

  testWidgets('enabled 参数为 false 时覆盖配置', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': 'A'},
        enabled: false,
      ),
    );

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
  });

  testWidgets('具备按钮语义', (tester) async {
    await tester.pumpWidget(
      buildMulti(
        name: 'tags',
        items: const {'a': 'A'},
      ),
    );

    expect(
      find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true),
      findsWidgets,
    );
  });

  group('WFormMultiDropdown 参数生效', () {
    testWidgets('height / width 渲染到外层容器', (tester) async {
      await tester.pumpWidget(
        buildMulti(name: 'tags', items: const {'a': 'A'}, height: 60, width: 240),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(WFormMultiDropdownCore<String>),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxHeight, 60);
      expect(container.constraints?.maxWidth, 240);
    });

    testWidgets('custom icon 渲染', (tester) async {
      await tester.pumpWidget(
        buildMulti(
          name: 'tags',
          items: const {'a': 'A'},
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      );
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('enabled=false → 点击不弹出', (tester) async {
      await tester.pumpWidget(
        buildMulti(name: 'tags', items: const {'a': 'A', 'b': 'B'}, enabled: false),
      );
      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('containerDecoration 渲染在外框', (tester) async {
      const color = Color(0xFF333333);
      await tester.pumpWidget(
        buildMulti(
          name: 'tags',
          items: const {'a': 'A'},
          containerDecoration: const BoxDecoration(color: color),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Container && (w.decoration as BoxDecoration?)?.color == color,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hintText 在无选择时显示', (tester) async {
      await tester.pumpWidget(
        buildMulti(name: 'tags', items: const {'a': 'A'}, hintText: '请选择兴趣'),
      );
      expect(find.text('请选择兴趣'), findsOneWidget);
    });
  });
}
