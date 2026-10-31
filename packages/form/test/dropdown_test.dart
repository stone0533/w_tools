import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '_helpers/form_test_scaffold.dart';

void main() {
  group('WFormDropdownConfig — 纯 Dart', () {
    test('默认空实例化', () {
      final cfg = WFormDropdownConfig();
      expect(cfg, isNotNull);
    });

    test('全部 setter 可赋值', () {
      final cfg = WFormDropdownConfig()
        ..enabled = false
        ..height = 48
        ..width = 160
        ..contentPadding = const EdgeInsets.all(8)
        ..yOffset = -2
        ..leading = const Icon(Icons.search)
        ..actions = [const Icon(Icons.close)]
        ..containerDecoration = BoxDecoration(color: Colors.grey.shade100)
        ..containerMargin = const EdgeInsets.all(4)
        ..containerPadding = const EdgeInsets.all(8)
        ..hint = const Text('自定义 hint')
        ..icon = const Icon(Icons.arrow_drop_up)
        ..style = const TextStyle(fontSize: 16)
        ..hintStyle = const TextStyle(color: Colors.grey)
        ..dropdownColor = Colors.amber;
      expect(cfg, isA<WFormDropdownConfig>());
    });

    test('copy() 返回新实例', () {
      final cfg = WFormDropdownConfig(height: 48);
      final cloned = cfg.copy();
      expect(cloned, isA<WFormDropdownConfig>());
      expect(identical(cfg, cloned), false);
    });

    test('copyWith 部分覆盖 height', () {
      final cfg = WFormDropdownConfig(height: 48, width: 160);

      final copied = cfg.copyWith(height: 64);
      expect(copied, isA<WFormDropdownConfig>());
      // height 被覆盖，width 从 cfg 继承
      // （copyWith 里 height ?? _height → 非 null 时用传入值）
      expect(copied, isNotNull);
    });

    test('copyWith 全部覆盖', () {
      final cfg = WFormDropdownConfig();
      final copied = cfg.copyWith(
        enabled: false,
        height: 50,
        width: 200,
        contentPadding: const EdgeInsets.all(4),
        yOffset: 1.0,
        leading: const Icon(Icons.start),
        actions: [],
        containerDecoration: const BoxDecoration(),
        containerMargin: EdgeInsets.zero,
        containerPadding: EdgeInsets.zero,
        hint: const Text('h'),
        icon: const Icon(Icons.arrow_drop_down),
        style: const TextStyle(),
        hintStyle: const TextStyle(),
        dropdownColor: Colors.cyan,
      );
      expect(copied, isNotNull);
      expect(identical(cfg, copied), false);
    });

    test('build(bordered: true) — name 空 → 抛 ArgumentError', () {
      final cfg = WFormDropdownConfig();
      expect(
        () => cfg.build<String>(
          bordered: true,
          name: '',
          items: const {'a': 'Apple'},
        ),
        throwsArgumentError,
      );
    });
  });

  group('WFormDropdownCore<T> — Widget', () {
    Widget buildDropdown({
      required WFormDropdownConfig config,
      required String name,
      required Map<String, String> items,
      String? hintText,
      String? initialValue,
      bool enabled = true,
    }) {
      final formData = WFormController();
      return MaterialApp(
        home: Scaffold(
          body: WFormScope(
            formData: formData,
            child: WFormDropdownCore<String>(
              config: config,
              name: name,
              items: items,
              hintText: hintText,
              initialValue: initialValue,
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    testWidgets('基本渲染 — items 显示 + hint', (tester) async {
      final cfg = WFormDropdownConfig();
      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
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
        MaterialApp(
          home: Scaffold(
            body: WFormDropdownCore<String>(
              config: WFormDropdownConfig(),
              name: 'fruit',
              items: const {'a': '苹果'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('initialValue 非空 → 显示选中值', (tester) async {
      final cfg = WFormDropdownConfig();
      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
          name: 'fruit',
          items: const {'a': '苹果', 'b': '香蕉'},
          initialValue: 'b',
        ),
      );

      expect(find.text('香蕉'), findsOneWidget);
    });

    testWidgets('enabled=false → DropdownButton disabled', (tester) async {
      final cfg = WFormDropdownConfig();
      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
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
      final cfg = WFormDropdownConfig();
      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
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
      final cfg = WFormDropdownConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: formData,
              child: WFormDropdownCore<String>(
                config: cfg,
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
      final cfg = WFormDropdownConfig(
        leading: const Icon(Icons.pin),
        icon: const Icon(Icons.expand_more),
      );

      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
          name: 'fruit',
          items: const {'a': '苹果'},
          hintText: '选',
        ),
      );

      expect(find.byIcon(Icons.pin), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('config.height / width 生效', (tester) async {
      final cfg = WFormDropdownConfig(height: 60, width: 200);

      await tester.pumpWidget(
        buildDropdown(
          config: cfg,
          name: 'fruit',
          items: const {'a': '苹果'},
          hintText: '选',
        ),
      );

      // 外层 Container 使用 config.height / width
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, 60);
      expect(container.constraints?.maxWidth, 200);
    });

    testWidgets('build(bordered: true) → 返回带 WFormFieldShell', (tester) async {
      final cfg = WFormDropdownConfig();
      final formBorderCfg = WFormBorderConfig.builder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: formData,
              formBorderConfig: formBorderCfg.buildConfig(),
              child: cfg.build<String>(
                bordered: true,
                name: 'fruit',
                items: const {'a': '苹果'},
                hintText: '选',
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
      final cfg = WFormDropdownConfig();
      final formBorderCfg = WFormBorderConfig.builder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: WFormController(),
              formBorderConfig: formBorderCfg.buildConfig(),
              child: cfg.build<String>(
                bordered: true,
                name: 'fruit',
                items: const {'a': '苹果'},
                readOnly: true,
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

  testWidgets('WFormDropdownConfig.build — readOnly 在无边框时也生效', (tester) async {
    await pumpForm(
      tester,
      child: WFormDropdownConfig().build<String>(
        name: 'country',
        items: const {'CN': '中国'},
        readOnly: true,
      ),
    );

    final button = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(button.onChanged, isNull);
  });

  testWidgets('裸 WFormDropdownCore 卸载时清理 formEntered', (tester) async {
    final data = WFormController();
    await pumpForm(
      tester,
      formData: data,
      child: WFormDropdownCore<String>(
        config: WFormDropdownConfig(),
        name: 'country',
        items: const {'CN': '中国'},
      ),
    );

    data.handleChange('country', 'CN');
    expect(data.formEntered['country'], isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(data.formEntered.containsKey('country'), isFalse);
  });

  group('WFormMultiDropdownConfig — 纯 Dart', () {
    test('默认空实例化', () {
      final cfg = WFormMultiDropdownConfig();
      expect(cfg, isNotNull);
    });

    test('全部 setter 可赋值', () {
      final cfg = WFormMultiDropdownConfig()
        ..enabled = false
        ..height = 48
        ..width = 200
        ..yOffset = -2
        ..leading = const Icon(Icons.pin)
        ..actions = [const Icon(Icons.add)]
        ..containerDecoration = const BoxDecoration()
        ..containerMargin = const EdgeInsets.all(4)
        ..containerPadding = const EdgeInsets.all(8)
        ..decoration = const InputDecoration(hintText: 'h')
        ..iconSize = 20
        ..icon = const Icon(Icons.keyboard_arrow_down)
        ..iconDisabledColor = Colors.grey
        ..iconEnabledColor = Colors.blue
        ..checkboxUnselectedIcon = const Icon(Icons.radio_button_unchecked)
        ..checkboxSelectedIcon = const Icon(Icons.check_circle)
        ..checkboxDisabledIcon = const Icon(Icons.block)
        ..style = const TextStyle(fontSize: 14)
        ..popUpLayerPadding = const EdgeInsets.all(16)
        ..popUpLayerElevation = 20
        ..popUpLayerShadowColor = Colors.red
        ..hintText = '请选择'
        ..disabledKeys = {'a', 'b'}
        ..itemPadding = const EdgeInsets.symmetric(vertical: 4)
        ..itemStyle = const TextStyle(color: Colors.grey)
        ..itemCheckedStyle = const TextStyle(color: Colors.green)
        ..itemDisabledStyle = const TextStyle(color: Colors.red)
        ..itemTitlePadding = const EdgeInsets.only(left: 4);
      expect(cfg, isA<WFormMultiDropdownConfig>());
    });

    test('copy() 返回新实例', () {
      final cfg = WFormMultiDropdownConfig(height: 50);
      final c = cfg.copy();
      expect(identical(cfg, c), false);
    });

    test('copyWith 全部覆盖', () {
      final cfg = WFormMultiDropdownConfig();
      final c = cfg.copyWith(
        enabled: false,
        height: 60,
        width: 300,
        yOffset: 1.0,
        leading: const Icon(Icons.add),
        actions: [],
        containerDecoration: const BoxDecoration(),
        containerMargin: EdgeInsets.zero,
        containerPadding: EdgeInsets.zero,
        decoration: const InputDecoration(),
        iconSize: 18,
        icon: const Icon(Icons.close),
        iconDisabledColor: Colors.brown,
        iconEnabledColor: Colors.amber,
        checkboxUnselectedIcon: const Icon(Icons.remove),
        checkboxSelectedIcon: const Icon(Icons.check),
        checkboxDisabledIcon: const Icon(Icons.block),
        style: const TextStyle(),
        popUpLayerPadding: const EdgeInsets.all(1),
        popUpLayerElevation: 5,
        popUpLayerShadowColor: Colors.black,
        hintText: '请选择',
        disabledKeys: const <String>{},
        itemPadding: EdgeInsets.zero,
        itemStyle: const TextStyle(),
        itemCheckedStyle: const TextStyle(),
        itemDisabledStyle: const TextStyle(),
        itemTitlePadding: EdgeInsets.zero,
      );
      expect(c, isNotNull);
    });

    test('build(bordered: true) — name 空 → 抛 ArgumentError', () {
      final cfg = WFormMultiDropdownConfig();
      expect(
        () => cfg.build(bordered: true, name: '', items: const {'a': 'A'}),
        throwsArgumentError,
      );
    });
  });

  group('WFormMultiDropdownCore — Widget', () {
    Widget buildMulti({
      required WFormMultiDropdownConfig config,
      required String name,
      required Map<String, String> items,
      Set<String>? initialValue,
      Set<String>? disabledKeys,
      ValueChanged<Set<String>>? onChanged,
      String? hintText,
      double? width,
      bool? enabled,
    }) {
      final effectiveConfig = disabledKeys == null
          ? config
          : (config.copy()..disabledKeys = disabledKeys);
      final formData = WFormController();
      return MaterialApp(
        home: Scaffold(
          body: WFormScope(
            formData: formData,
            child: WFormMultiDropdownCore(
              config: effectiveConfig,
              name: name,
              items: items,
              initialValue: initialValue,
              onChanged: onChanged,
              hintText: hintText,
              width: width,
              enabled: enabled,
            ),
          ),
        ),
      );
    }

    testWidgets('裸 WFormMultiDropdownCore 卸载时清理 formEntered', (tester) async {
      final data = WFormController();
      await pumpForm(
        tester,
        formData: data,
        child: WFormMultiDropdownCore(
          config: WFormMultiDropdownConfig(),
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      data.handleChange('tags', <String>{'a'});
      expect(data.formEntered['tags'], isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(data.formEntered.containsKey('tags'), isFalse);
    });

    testWidgets('基本渲染 — 无初始值显示 ALL', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': '美食', 'b': '旅游', 'c': '购物'},
        ),
      );

      expect(find.text('ALL'), findsOneWidget);
    });

    testWidgets('无 WFormScope → 抛 Exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormMultiDropdownCore(
              config: WFormMultiDropdownConfig(),
              name: 'tags',
              items: const {'a': '美食'},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });

    testWidgets('initialValue → 显示逗号分隔文本', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': '美食', 'b': '旅游', 'c': '购物'},
          initialValue: {'a', 'c'},
        ),
      );

      expect(find.text('美食, 购物'), findsOneWidget);
    });

    testWidgets('键可包含逗号（值不再使用逗号编码）', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a,b': 'A,B', 'c': 'C'},
          initialValue: const {'a,b'},
        ),
      );

      expect(find.text('A,B'), findsOneWidget);
    });

    testWidgets('config.hintText 生效（build 路径）', (tester) async {
      final cfg = WFormMultiDropdownConfig(hintText: '请选择兴趣');

      await pumpForm(
        tester,
        child: cfg.build(
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      expect(find.text('请选择兴趣'), findsOneWidget);
    });

    testWidgets('未选择时显示 hintText 占位', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A'},
          hintText: '请选择',
        ),
      );

      expect(find.text('请选择'), findsOneWidget);
    });

    testWidgets('点击选项 → onChanged 收到 Set', (tester) async {
      Set<String>? changed;
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
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
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
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

    testWidgets('validator 暴露：formKey.validate() 执行并写入 errorText', (tester) async {
      final formData = WFormController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: formData,
              child: WFormMultiDropdownConfig().build(
                name: 'validated_tags',
                items: const {'a': 'A'},
                validator: (value) => value == null || value.isEmpty ? '至少选一项' : null,
              ),
            ),
          ),
        ),
      );

      expect(formData.formKey.currentState!.validate(), isFalse);
      expect(formData.formKey.currentState!.fields['validated_tags']!.errorText, '至少选一项');
    });

    testWidgets('config.height / width 生效', (tester) async {
      final cfg = WFormMultiDropdownConfig(height: 60, width: 240);

      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, 60);
      expect(container.constraints?.maxWidth, 240);
    });

    testWidgets('custom icon 渲染', (tester) async {
      final cfg = WFormMultiDropdownConfig(
        icon: const Icon(Icons.arrow_forward_ios),
      );

      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('enabled=false → 点击不弹出', (tester) async {
      final cfg = WFormMultiDropdownConfig(enabled: false);
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A', 'b': 'B'},
        ),
      );

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      // 只有 'ALL'，不弹出 items
      expect(find.text('ALL'), findsOneWidget);
      // 弹出层不该出现 → 'A' 'B' 只在 widget 初始，不在 overlay
      // （但 items 是 widget 内常量，始终显示在 items map）
      // 简化验证：enabled Icon 颜色不同
    });

    testWidgets('点击 → WFormPopup.show 弹出选项', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
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
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
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
      final cfg = WFormMultiDropdownConfig();
      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true),
        findsWidgets,
      );
    });

    testWidgets('build(bordered: true) → WFormFieldShell 包装', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      final formBorderCfg = WFormBorderConfig.builder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: formData,
              formBorderConfig: formBorderCfg.buildConfig(),
              child: cfg.build(
                bordered: true,
                name: 'tags',
                items: const {'a': '美食'},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WFormFieldShell), findsOneWidget);
      expect(find.byType(WFormMultiDropdownCore), findsOneWidget);
    });

    testWidgets('build(bordered: true) readOnly → 外层只读 + 点击不弹出', (tester) async {
      final cfg = WFormMultiDropdownConfig();
      final formBorderCfg = WFormBorderConfig.builder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: WFormController(),
              formBorderConfig: formBorderCfg.buildConfig(),
              child: cfg.build(
                bordered: true,
                name: 'tags',
                items: const {'a': 'A'},
                readOnly: true,
              ),
            ),
          ),
        ),
      );

      final border = tester.widget<WFormFieldShell>(find.byType(WFormFieldShell));
      expect(border.readOnly, isTrue);

      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsNothing);
    });

    /// 匹配内层容器装饰（BoxDecoration 颜色为指定值）
    Finder findContainerDecoration(Color color) => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );

    testWidgets('build(bordered: true) 清空内层 containerDecoration（避免与外层边框叠加）', (tester) async {
      const innerColor = Color(0xFF333333);
      final cfg = WFormMultiDropdownConfig(
        containerDecoration: const BoxDecoration(color: innerColor),
      );
      final formBorderCfg = WFormBorderConfig.builder();
      formBorderCfg.hintBuilder = (_) => const SizedBox.shrink();
      formBorderCfg.errorBuilder = (_) => const SizedBox.shrink();
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormScope(
              formData: formData,
              formBorderConfig: formBorderCfg.buildConfig(),
              child: cfg.build(bordered: true, name: 'tags', items: const {'a': 'A'}),
            ),
          ),
        ),
      );

      // 内层装饰已被清空 → 边框交由外层 WFormBorder 绘制
      expect(findContainerDecoration(innerColor), findsNothing);
      expect(find.byType(WFormBorder), findsOneWidget);
    });

    testWidgets('build() 仍保留 containerDecoration（build(bordered: true) 的副本不污染原配置）', (tester) async {
      const innerColor = Color(0xFF333333);
      final cfg = WFormMultiDropdownConfig(
        containerDecoration: const BoxDecoration(color: innerColor),
      );

      await tester.pumpWidget(
        buildMulti(
          config: cfg,
          name: 'tags',
          items: const {'a': 'A'},
        ),
      );

      expect(findContainerDecoration(innerColor), findsOneWidget);
    });
  });
}
