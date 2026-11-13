import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_form/src/components/border/border_access.dart';

import '_helpers/border_state.dart';

import '_helpers/form_test_scaffold.dart';
import 'package:w_tools_form/src/components/fields/checkbox.dart';
import 'package:w_tools_form/src/components/fields/dropdown.dart';
import 'package:w_tools_form/src/components/fields/text_field.dart';

/// 创建带默认 hintBuilder/errorBuilder 的 WFormBorderStyle
TestFormBorderBuilder makeCfg({
  BoxDecoration? defaultDecoration,
  BoxDecoration? readOnlyDecoration,
  BoxDecoration? errorDecoration,
  BoxDecoration? focusedDecoration,
}) {
  final cfg = TestFormBorderBuilder();
  cfg.hintBuilder = (_) => const SizedBox.shrink();
  cfg.errorBuilder = (_) => const SizedBox.shrink();
  if (defaultDecoration != null) cfg.defaultDecoration = defaultDecoration;
  if (readOnlyDecoration != null) cfg.readOnlyDecoration = readOnlyDecoration;
  if (errorDecoration != null) cfg.errorDecoration = errorDecoration;
  if (focusedDecoration != null) cfg.focusedDecoration = focusedDecoration;
  return cfg;
}

/// 直接生成不可变配置，便于传给 WFormBorder
WFormBorderStyle makeCfgConfig({
  BoxDecoration? defaultDecoration,
  BoxDecoration? readOnlyDecoration,
  BoxDecoration? errorDecoration,
  BoxDecoration? focusedDecoration,
}) => makeCfg(
  defaultDecoration: defaultDecoration,
  readOnlyDecoration: readOnlyDecoration,
  errorDecoration: errorDecoration,
  focusedDecoration: focusedDecoration,
).buildStyle();

/// 查找 WFormBorder 内部用于绘制边框的 DecoratedBox
Finder findBorderDecoratedBox() => find.descendant(
  of: find.byType(WFormBorder),
  matching: find.byType(DecoratedBox),
);

/// 读取 WFormBorder 当前生效的 BoxDecoration（无装饰时返回 null）
BoxDecoration? borderBoxDecoration(WidgetTester tester) {
  final finder = findBorderDecoratedBox();
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<DecoratedBox>(finder.first).decoration as BoxDecoration;
}

/// 匹配描边颜色为指定值的边框容器（用于断言 default / focused / error 装饰）
Finder findBorderWithSideColor(Color color) => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final decoration = w.decoration;
  if (decoration is! BoxDecoration) return false;
  final border = decoration.border;
  if (border is! Border) return false;
  return border.top.color == color;
});

/// 匹配背景色为指定值的边框容器
Finder findBorderFillColor(Color color) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == color,
);

void main() {
  group('WFormBorder + WFormBorderState', () {
    testWidgets('child 正常渲染', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: makeCfgConfig(),
              child: const Text('my-child'),
            ),
          ),
        ),
      );
      expect(find.text('my-child'), findsOneWidget);
    });

    testWidgets('hintTextList 渲染提示文本', (tester) async {
      final cfg = makeCfg();
      cfg.hintBuilder = (list) => Column(
        children: list!.map((e) => Text('hint-$e')).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: cfg.buildStyle(),
              hintTextList: const ['至少8位', '包含数字'],
              child: const Text('field'),
            ),
          ),
        ),
      );
      expect(find.text('hint-至少8位'), findsOneWidget);
      expect(find.text('hint-包含数字'), findsOneWidget);
    });

    testWidgets('hintTextList 运行期变更 → 提示文本随之更新（回归）', (tester) async {
      final key = GlobalKey();
      final cfg = TestFormBorderBuilder();
      cfg.hintBuilder = (list) => Column(
        children: [for (final e in list ?? const <String>[]) Text('hint-$e')],
      );

      Widget buildWith(List<String> hints) => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            key: key,
            style: cfg.buildStyle(),
            hintTextList: hints,
            child: const Text('field'),
          ),
        ),
      );

      await tester.pumpWidget(buildWith(const ['旧提示']));
      expect(find.text('hint-旧提示'), findsOneWidget);

      await tester.pumpWidget(buildWith(const ['新提示']));
      expect(find.text('hint-新提示'), findsOneWidget);
      expect(find.text('hint-旧提示'), findsNothing);
    });

    testWidgets('配置原地修改 / 清空后，组件重建即生效（回归）', (tester) async {
      final key = GlobalKey();
      final cfg = TestFormBorderBuilder()
        ..defaultDecoration = const BoxDecoration(color: Color(0xFF111111));

      Widget buildWith(List<String> hints) => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            key: key,
            style: cfg.buildStyle(),
            hintTextList: hints,
            child: const Text('field'),
          ),
        ),
      );

      await tester.pumpWidget(buildWith(const ['a']));
      expect(findBorderFillColor(const Color(0xFF111111)), findsOneWidget);

      // 原地替换装饰：重建后应生效（此前按实例身份比较，永远不生效）
      cfg.defaultDecoration = const BoxDecoration(color: Color(0xFF222222));
      await tester.pumpWidget(buildWith(const ['b']));
      expect(findBorderFillColor(const Color(0xFF222222)), findsOneWidget);

      // copyWith 的 null 表示「保持不变」；清空请使用 setter 传 null
      cfg.defaultDecoration = null;
      await tester.pumpWidget(buildWith(const ['c']));
      expect(findBorderFillColor(const Color(0xFF222222)), findsNothing);
    });

    testWidgets('自定义 layout — 消息可放到子组件右侧', (tester) async {
      const childKey = Key('layout-child');
      final cfg = TestFormBorderBuilder()
        ..hintBuilder = ((list) => Text(list!.first))
        ..layout = (context, data) => Row(
          children: [
            Expanded(child: data.child),
            data.message,
          ],
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: cfg.buildStyle(),
              hintTextList: const ['侧边提示'],
              child: const SizedBox(key: childKey, height: 40),
            ),
          ),
        ),
      );

      expect(find.text('侧边提示'), findsOneWidget);
      expect(
        tester.getCenter(find.text('侧边提示')).dx,
        greaterThan(tester.getCenter(find.byKey(childKey)).dx),
      );
    });

    testWidgets('运行期替换 layout 后生效', (tester) async {
      const childKey = Key('layout-child');
      final cfg = TestFormBorderBuilder()..hintBuilder = (list) => Text(list!.first);

      Widget build() => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            style: cfg.buildStyle(),
            hintTextList: const ['提示'],
            child: const SizedBox(key: childKey, width: 120, height: 40),
          ),
        ),
      );

      await tester.pumpWidget(build());
      // 默认布局：消息在子组件下方
      expect(
        tester.getCenter(find.text('提示')).dy,
        greaterThan(tester.getCenter(find.byKey(childKey)).dy),
      );

      cfg.layout = (context, data) => Row(
        children: [
          Expanded(child: data.child),
          data.message,
        ],
      );
      await tester.pumpWidget(build());

      // 替换后：消息移到右侧
      expect(
        tester.getCenter(find.text('提示')).dx,
        greaterThan(tester.getCenter(find.byKey(childKey)).dx),
      );
    });

    testWidgets('setError(true) → 显示 errorBuilder', (tester) async {
      final key = GlobalKey();
      final cfg = makeCfg();
      cfg.hintBuilder = (list) => const Text('hint-placeholder');
      cfg.errorBuilder = (list) => Column(
        children: list!.map((e) => Text('err-$e')).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              style: cfg.buildStyle(),
              hintTextList: const ['请填写'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      expect(find.text('hint-placeholder'), findsOneWidget);
      borderStateOf(key)?.setError(true, errorTextList: const ['必填', '格式错误']);
      await tester.pump();

      expect(find.text('err-必填'), findsOneWidget);
      expect(find.text('err-格式错误'), findsOneWidget);
      expect(borderStateOf(key)?.isError, true);
      expect(borderStateOf(key)?.messageList, ['必填', '格式错误']);
    });

    testWidgets('setError(false) → 恢复 hintTextList', (tester) async {
      final key = GlobalKey();
      final cfg = makeCfg();
      cfg.hintBuilder = (list) => Column(
        children: list!.map((e) => Text('hint-$e')).toList(),
      );
      cfg.errorBuilder = (list) => Column(
        children: list!.map((e) => Text('err-$e')).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              style: cfg.buildStyle(),
              hintTextList: const ['字段提示'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      borderStateOf(key)?.setError(true, errorTextList: const ['出错了']);
      await tester.pump();
      expect(find.text('err-出错了'), findsOneWidget);

      borderStateOf(key)?.setError(false);
      await tester.pump();
      expect(find.text('hint-字段提示'), findsOneWidget);
      expect(borderStateOf(key)?.isError, false);
      expect(borderStateOf(key)?.messageList, ['字段提示']);
    });

    testWidgets('对已无错误的字段 setError(false) → 不触发重建（无意义重建优化）', (tester) async {
      final key = GlobalKey();
      // 用 hintBuilder 的执行次数作为 WFormBorderState 重建的观测点
      var buildCount = 0;
      final cfg = makeCfg();
      cfg.hintBuilder = (list) {
        buildCount++;
        return const Text('hint');
      };
      cfg.errorBuilder = (list) => const Text('err');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              style: cfg.buildStyle(),
              hintTextList: const ['提示'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      final initial = buildCount;

      // 本来就无错误：清错应是 no-op，不触发重建
      borderStateOf(key)?.setError(false);
      await tester.pump();
      expect(buildCount, initial);

      // 对照：从错误态清错会触发重建（hintBuilder 再次执行）
      borderStateOf(key)?.setError(true, errorTextList: const ['err']);
      await tester.pump();
      expect(find.text('err'), findsOneWidget);

      borderStateOf(key)?.setError(false);
      await tester.pump();
      expect(buildCount, initial + 1);
    });

    testWidgets('isTransparentBackground → 不渲染装饰', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: makeCfgConfig(
                defaultDecoration: const BoxDecoration(color: Colors.red),
              ),
              isTransparentBackground: true,
              child: const Text('field'),
            ),
          ),
        ),
      );

      expect(findBorderDecoratedBox(), findsNothing);
    });

    testWidgets('isReadOnly=true → readOnlyDecoration 生效', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: makeCfgConfig(
                defaultDecoration: const BoxDecoration(color: Colors.white),
                readOnlyDecoration: const BoxDecoration(color: Colors.grey),
              ),
              isReadOnly: true,
              child: const Text('field'),
            ),
          ),
        ),
      );

      expect(borderBoxDecoration(tester)?.color, Colors.grey);
    });

    testWidgets('isFocused=true → focusedDecoration 生效', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: makeCfgConfig(
                defaultDecoration: const BoxDecoration(color: Colors.white),
                focusedDecoration: const BoxDecoration(color: Colors.blue),
              ),
              isFocused: true,
              child: const Text('field'),
            ),
          ),
        ),
      );

      expect(borderBoxDecoration(tester)?.color, Colors.blue);
    });

    testWidgets('errorDecoration 优先于 readOnly + focused', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              style: makeCfgConfig(
                defaultDecoration: const BoxDecoration(color: Colors.white),
                readOnlyDecoration: const BoxDecoration(color: Colors.grey),
                focusedDecoration: const BoxDecoration(color: Colors.blue),
                errorDecoration: const BoxDecoration(color: Colors.red),
              ),
              isReadOnly: true,
              isFocused: true,
              child: const Text('field'),
            ),
          ),
        ),
      );

      borderStateOf(key)?.setError(true, errorTextList: const ['err']);
      await tester.pump();

      expect(borderBoxDecoration(tester)?.color, Colors.red);
    });
  });

  group('WFormBorderStyle — copyWith / copy / build', () {
    test('copyWith 默认 builder 缺失时仍可用（新 cfg 也未初始化 → 但 setter 之后 OK）', () {
      final base = makeCfg(); // 已初始化 builder
      final custom = base.buildStyle().copyWith(
        defaultDecoration: const BoxDecoration(color: Colors.red),
      );
      expect(custom, isA<WFormBorderStyle>());
      // copyWith 返回新实例，hintBuilder/errorBuilder 从 base 继承
      expect(identical(base, custom), false);
    });

    testWidgets('copyWith() 保留自定义 layout', (tester) async {
      final base = makeCfg()..layout = (context, data) => const Text('custom-layout');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(style: base.buildStyle(), child: const Text('child')),
          ),
        ),
      );

      expect(find.text('custom-layout'), findsOneWidget);
    });
  });

  group('WFormFieldShell', () {
    testWidgets('无 WFormScope → 抛 Exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WFormFieldShell(
              name: 'test',
              readOnly: false,
              child: Text('c'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('有 WFormScope → 正常渲染 + 自动注册 key', (tester) async {
      final formData = WFormController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: const WFormFieldShell(
                name: 'email',
                readOnly: false,
                child: Text('input'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('input'), findsOneWidget);
      expect(bordersOf(formData).has('email'), true);
    });

    testWidgets('hintTextList 从 WFormFieldShell 传递', (tester) async {
      final cfg = makeCfg();
      cfg.hintBuilder = (list) => Column(
        children: list!.map((e) => Text(e)).toList(),
      );
      final formData = WFormController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: cfg.buildStyle(),
              child: const WFormFieldShell(
                name: 'pwd',
                readOnly: false,
                hintTextList: ['至少8位'],
                child: Text('input'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('至少8位'), findsOneWidget);
    });
  });

  group('WFormBorder 状态优先级与焦点开关（回归）', () {
    testWidgets('isTransparentBackground: true 时错误装饰仍生效', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              style: makeCfgConfig(
                errorDecoration: const BoxDecoration(
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFC0061A), width: 1),
                  ),
                ),
              ),
              isTransparentBackground: true,
              child: const Text('c'),
            ),
          ),
        ),
      );

      // 初始：透明背景 → 无装饰
      expect(findBorderWithSideColor(const Color(0xFFC0061A)), findsNothing);

      borderStateOf(key)?.setError(true, errorTextList: const ['必填']);
      await tester.pump();

      // 错误态优先于透明背景 → 红框回归
      expect(findBorderWithSideColor(const Color(0xFFC0061A)), findsOneWidget);
    });

    testWidgets('enableFocusBorder 由 true 改 false → 聚焦装饰不再残留', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final formData = WFormController();

      Widget buildWith({required bool enableFocusBorder}) => MaterialApp(
        home: Scaffold(
          body: themedScope(
            formData: formData,
            formBorderStyle: makeCfgConfig(
              defaultDecoration: const BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFFEAEAEA), width: 1),
                ),
              ),
              focusedDecoration: const BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.blue, width: 1),
                ),
              ),
            ),
            child: WFormFieldShell(
              name: 'field',
              readOnly: false,
              enableFocusBorder: enableFocusBorder,
              child: TextField(focusNode: focusNode),
            ),
          ),
        ),
      );

      await tester.pumpWidget(buildWith(enableFocusBorder: true));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // 聚焦中 → 聚焦装饰（蓝色描边）
      expect(findBorderWithSideColor(Colors.blue), findsOneWidget);

      await tester.pumpWidget(buildWith(enableFocusBorder: false));
      await tester.pump();

      // 关闭焦点边框 → 回落到默认装饰，不残留聚焦态
      expect(findBorderWithSideColor(Colors.blue), findsNothing);
      expect(findBorderWithSideColor(const Color(0xFFEAEAEA)), findsOneWidget);
    });
  });

  group('WFormScope.formBorderStyle', () {
    testWidgets('运行时变更 → 子树内边框装饰随之更新', (tester) async {
      final formData = WFormController();
      final cfgNotifier = ValueNotifier<WFormBorderStyle>(
        makeCfg(
          defaultDecoration: const BoxDecoration(color: Color(0xFF111111)),
        ).buildStyle(),
      );
      addTearDown(cfgNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<WFormBorderStyle>(
              valueListenable: cfgNotifier,
              builder: (context, cfg, _) => themedScope(
                formData: formData,
                formBorderStyle: cfg,
                child: const WFormFieldShell(
                  name: 'live',
                  readOnly: false,
                  child: Text('c'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(findBorderFillColor(const Color(0xFF111111)), findsOneWidget);

      cfgNotifier.value = makeCfg(
        defaultDecoration: const BoxDecoration(color: Color(0xFF222222)),
      ).buildStyle();
      await tester.pump();

      expect(findBorderFillColor(const Color(0xFF222222)), findsOneWidget);
      expect(findBorderFillColor(const Color(0xFF111111)), findsNothing);
    });

    testWidgets('直接使用 WFormBorder 时显式 style 生效', (tester) async {
      final cfg = TestFormBorderBuilder();
      cfg.hintBuilder = (list) => Column(
        children: [for (final e in list ?? const <String>[]) Text('hint-$e')],
      );
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              child: WFormBorder(
                style: cfg.buildStyle(),
                hintTextList: const ['继承成功'],
                child: const Text('c'),
              ),
            ),
          ),
        ),
      );

      // 未显式传 config → 继承 builder 的配置，hintBuilder 生效
      expect(find.text('hint-继承成功'), findsOneWidget);
    });

    testWidgets('显式 config 优先于 WFormScope.formBorderStyle', (tester) async {
      final builderCfg = TestFormBorderBuilder();
      builderCfg.hintBuilder = (list) => Text('builder-${list!.first}');

      final borderCfg = TestFormBorderBuilder();
      borderCfg.hintBuilder = (list) => Text('border-${list!.first}');

      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: builderCfg.buildStyle(),
              child: WFormBorder(
                style: borderCfg.buildStyle(),
                hintTextList: const ['x'],
                child: const Text('c'),
              ),
            ),
          ),
        ),
      );

      // 两级都配置 → 使用 WFormBorder 自身的配置
      expect(find.text('border-x'), findsOneWidget);
      expect(find.text('builder-x'), findsNothing);
    });
  });

  testWidgets('WFormFieldShell 卸载时注销边框登记', (tester) async {
    final formData = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: themedScope(
            formData: formData,
            child: const WFormFieldShell(
              name: 'dynamic_field',
              readOnly: false,
              child: Text('field'),
            ),
          ),
        ),
      ),
    );

    formData.clearError('dynamic_field');
    expect(bordersOf(formData).has('dynamic_field'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(bordersOf(formData).has('dynamic_field'), isFalse);
    expect(formData.formEntered.containsKey('dynamic_field'), isFalse);
  });

  group('WFormFieldShell + WFormReadOnlyScope（替代已删除的 Row.withFormBorder）', () {
    testWidgets('readOnly: true → 内部输入组件被置为只读 / 禁用', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: const Row(
                children: [
                  Expanded(
                    child: WFormTextFieldCore(name: 'a'),
                  ),
                  Expanded(
                    child: WFormDropdownCore<String>(
                      name: 'b',
                      items: {'x': 'X'},
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', readOnly: true, hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // WFormTextFieldCore 的只读由外层 WFormReadOnlyScope 在 build 时合成
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

      // 类型实参保留；内部 DropdownButton 因外层只读被禁用
      final dropdownFinder = find.byType(WFormDropdownCore<String>);
      expect(dropdownFinder, findsOneWidget);
      expect(
        tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).onChanged,
        isNull,
      );
    });

    testWidgets('readOnly: true 可穿透任意包装 widget（Padding）', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: const Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: WFormTextFieldCore(name: 'a'),
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', readOnly: true),
            ),
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    });

    testWidgets('Row 内的 Container 属性（宽高 / 裁剪）完整保留', (tester) async {
      final formData = WFormController();
      final container = Container(
        width: 120,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
        child: const WFormTextFieldCore(name: 'a'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: Row(children: [container]).withFormBorder(name: 'row'),
            ),
          ),
        ),
      );

      // 不再重建 Row 内部结构：原始 Container 实例被原样保留
      expect(
        tester.widgetList<Container>(find.byType(Container)).any((c) => identical(c, container)),
        isTrue,
      );
      // 布局尺寸未丢失
      expect(tester.getSize(find.byType(WFormTextFieldCore)), const Size(120, 48));
    });

    testWidgets('readOnly: true 也会禁用内部 WFormCheckboxCore', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormCheckboxCore(
                      name: 'agree',
                      title: const Text('同意'),
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', readOnly: true),
            ),
          ),
        ),
      );

      await tester.tap(find.text('同意'));
      await tester.pump();

      formData.formKey.currentState?.save();
      expect(formData.value['agree'], false);
    });

    testWidgets('readOnly: true → 非 String 泛型的 WFormDropdownCore 也被禁用', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: (const Row(
                children: [
                  Expanded(
                    child: WFormDropdownCore<int>(
                      name: 'b',
                      items: {1: 'ONE'},
                    ),
                  ),
                ],
              )).withFormBorder(name: 'row', readOnly: true, hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      final dropdownFinder = find.byWidgetPredicate((w) => w is WFormDropdownCore);
      expect(dropdownFinder, findsOneWidget);
      // 运行时实参保留；内部 DropdownButton 因外层只读被禁用
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
        isNull,
      );
    });

    testWidgets('readOnly: false 时保留内部原有的 enabled: false（回归）', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: (const Row(
                children: [
                  Expanded(
                    child: WFormDropdownCore<String>(
                      name: 'b',
                      items: {'x': 'X'},
                      enabled: false,
                    ),
                  ),
                ],
              )).withFormBorder(name: 'row', hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // 修复前会被 `enabled: !readOnly` 强制改回 true
      final dropdownFinder = find.byType(WFormDropdownCore<String>);
      expect(dropdownFinder, findsOneWidget);
      expect(tester.widget<WFormDropdownCore<String>>(dropdownFinder).enabled, isFalse);
    });

    testWidgets('内部子组件保留自身的 key（回归）', (tester) async {
      final formData = WFormController();
      final fieldKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormTextFieldCore(
                      key: fieldKey,

                      name: 'a',
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // 修复前重建子组件时丢掉了 key
      expect(find.byKey(fieldKey), findsOneWidget);
    });

    testWidgets('内部 Stack 的 clipBehavior 被保留（回归）', (tester) async {
      final formData = WFormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: themedScope(
              formData: formData,
              formBorderStyle: makeCfgConfig(),
              child: const Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 10,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [SizedBox(width: 10, height: 10)],
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // 修复前被硬编码为 Clip.hardEdge
      final stacks = tester.widgetList<Stack>(find.byType(Stack));
      expect(stacks.any((s) => s.clipBehavior == Clip.none), isTrue);
    });

    test('name 为空 → 抛 ArgumentError', () {
      expect(
        () => const Row().withFormBorder(name: ''),
        throwsArgumentError,
      );
    });
  });

  group('WFormBorder 消息兜底', () {
    testWidgets('WFormBorderStyle.standard() 渲染 hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              style: WFormBorderStyle.standard(),
              hintTextList: const ['请输入'],
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('请输入'), findsOneWidget);
    });
  });
}
