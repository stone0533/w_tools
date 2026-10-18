import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 创建带默认 hintBuilder/errorBuilder 的 WFormBorderConfig
WFormBorderConfig makeCfg({
  WFormBorderDecoration? defaultDecoration,
  WFormBorderDecoration? readOnlyDecoration,
  WFormBorderDecoration? errorDecoration,
  WFormBorderDecoration? focusedDecoration,
}) {
  final cfg = WFormBorderConfig();
  cfg.hintBuilder = (_) => const SizedBox.shrink();
  cfg.errorBuilder = (_) => const SizedBox.shrink();
  if (defaultDecoration != null) cfg.defaultDecoration = defaultDecoration;
  if (readOnlyDecoration != null) cfg.readOnlyDecoration = readOnlyDecoration;
  if (errorDecoration != null) cfg.errorDecoration = errorDecoration;
  if (focusedDecoration != null) cfg.focusedDecoration = focusedDecoration;
  return cfg;
}

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
              config: makeCfg(),
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
              config: cfg,
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
      final key = GlobalKey<WFormBorderState>();
      final cfg = WFormBorderConfig();
      cfg.hintBuilder = (list) => Column(
        children: [for (final e in list ?? const <String>[]) Text('hint-$e')],
      );

      Widget buildWith(List<String> hints) => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            key: key,
            config: cfg,
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
      final key = GlobalKey<WFormBorderState>();
      final cfg = WFormBorderConfig()
        ..defaultDecoration = const WFormBorderDecoration(color: Color(0xFF111111));

      Widget buildWith(List<String> hints) => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            key: key,
            config: cfg,
            hintTextList: hints,
            child: const Text('field'),
          ),
        ),
      );

      await tester.pumpWidget(buildWith(const ['a']));
      expect(findBorderFillColor(const Color(0xFF111111)), findsOneWidget);

      // 原地替换装饰：重建后应生效（此前按实例身份比较，永远不生效）
      cfg.defaultDecoration = const WFormBorderDecoration(color: Color(0xFF222222));
      await tester.pumpWidget(buildWith(const ['b']));
      expect(findBorderFillColor(const Color(0xFF222222)), findsOneWidget);

      // copyWith 的 null 表示「保持不变」；清空请使用 setter 传 null
      cfg.defaultDecoration = null;
      await tester.pumpWidget(buildWith(const ['c']));
      expect(findBorderFillColor(const Color(0xFF222222)), findsNothing);
    });

    testWidgets('自定义 layout — 消息可放到子组件右侧', (tester) async {
      const childKey = Key('layout-child');
      final cfg = WFormBorderConfig()
        ..hintBuilder = ((list) => Text(list!.first))
        ..layout = WFormBorderLayout.builder(
          (context, data) => Row(
            children: [
              Expanded(child: data.child),
              data.message,
            ],
          ),
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              config: cfg,
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
      final cfg = WFormBorderConfig()..hintBuilder = (list) => Text(list!.first);

      Widget build() => MaterialApp(
        home: Scaffold(
          body: WFormBorder(
            config: cfg,
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

      cfg.layout = WFormBorderLayout.builder(
        (context, data) => Row(
          children: [
            Expanded(child: data.child),
            data.message,
          ],
        ),
      );
      await tester.pumpWidget(build());

      // 替换后：消息移到右侧
      expect(
        tester.getCenter(find.text('提示')).dx,
        greaterThan(tester.getCenter(find.byKey(childKey)).dx),
      );
    });

    testWidgets('setError(true) → 显示 errorBuilder', (tester) async {
      final key = GlobalKey<WFormBorderState>();
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
              config: cfg,
              hintTextList: const ['请填写'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      expect(find.text('hint-placeholder'), findsOneWidget);
      key.currentState?.setError(true, errorTextList: const ['必填', '格式错误']);
      await tester.pump();

      expect(find.text('err-必填'), findsOneWidget);
      expect(find.text('err-格式错误'), findsOneWidget);
      expect(key.currentState?.isError, true);
      expect(key.currentState?.messageList, ['必填', '格式错误']);
    });

    testWidgets('setError(false) → 恢复 hintTextList', (tester) async {
      final key = GlobalKey<WFormBorderState>();
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
              config: cfg,
              hintTextList: const ['字段提示'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      key.currentState?.setError(true, errorTextList: const ['出错了']);
      await tester.pump();
      expect(find.text('err-出错了'), findsOneWidget);

      key.currentState?.setError(false);
      await tester.pump();
      expect(find.text('hint-字段提示'), findsOneWidget);
      expect(key.currentState?.isError, false);
      expect(key.currentState?.messageList, ['字段提示']);
    });

    testWidgets('对已无错误的字段 setError(false) → 不触发重建（无意义重建优化）', (tester) async {
      final key = GlobalKey<WFormBorderState>();
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
              config: cfg,
              hintTextList: const ['提示'],
              child: const Text('field'),
            ),
          ),
        ),
      );

      final initial = buildCount;

      // 本来就无错误：清错应是 no-op，不触发重建
      key.currentState?.setError(false);
      await tester.pump();
      expect(buildCount, initial);

      // 对照：从错误态清错会触发重建（hintBuilder 再次执行）
      key.currentState?.setError(true, errorTextList: const ['err']);
      await tester.pump();
      expect(find.text('err'), findsOneWidget);

      key.currentState?.setError(false);
      await tester.pump();
      expect(buildCount, initial + 1);
    });

    testWidgets('isTransparentBackground → 不渲染装饰', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              config: makeCfg(
                defaultDecoration: const WFormBorderDecoration(color: Colors.red),
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
              config: makeCfg(
                defaultDecoration: const WFormBorderDecoration(color: Colors.white),
                readOnlyDecoration: const WFormBorderDecoration(color: Colors.grey),
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
              config: makeCfg(
                defaultDecoration: const WFormBorderDecoration(color: Colors.white),
                focusedDecoration: const WFormBorderDecoration(color: Colors.blue),
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
      final key = GlobalKey<WFormBorderState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              config: makeCfg(
                defaultDecoration: const WFormBorderDecoration(color: Colors.white),
                readOnlyDecoration: const WFormBorderDecoration(color: Colors.grey),
                focusedDecoration: const WFormBorderDecoration(color: Colors.blue),
                errorDecoration: const WFormBorderDecoration(color: Colors.red),
              ),
              isReadOnly: true,
              isFocused: true,
              child: const Text('field'),
            ),
          ),
        ),
      );

      key.currentState?.setError(true, errorTextList: const ['err']);
      await tester.pump();

      expect(borderBoxDecoration(tester)?.color, Colors.red);
    });
  });

  group('WFormBorderConfig — copyWith / copy / build', () {
    test('copyWith 默认 builder 缺失时仍可用（新 cfg 也未初始化 → 但 setter 之后 OK）', () {
      final base = makeCfg(); // 已初始化 builder
      final custom = base.copyWith(
        defaultDecoration: const WFormBorderDecoration(color: Colors.red),
      );
      expect(custom, isA<WFormBorderConfig>());
      // copyWith 返回新实例，hintBuilder/errorBuilder 从 base 继承
      expect(identical(base, custom), false);
    });

    test('copy() 等同于 copyWith()', () {
      final base = makeCfg();
      final cloned = base.copy();
      expect(cloned, isA<WFormBorderConfig>());
    });

    test('build() 返回 WFormBorder', () {
      final cfg = makeCfg();
      final border = cfg.build(child: const Text('child'));
      expect(border, isA<WFormBorder>());
    });

    testWidgets('copy() / copyWith() 保留自定义 layout', (tester) async {
      final base = makeCfg()
        ..layout = WFormBorderLayout.builder(
          (context, data) => const Text('custom-layout'),
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: base.copy().build(child: const Text('child')),
          ),
        ),
      );

      expect(find.text('custom-layout'), findsOneWidget);
    });
  });

  group('WFormBorderDecoration', () {
    test('const 构造默认值', () {
      const d = WFormBorderDecoration();
      expect(d.border, isNull);
      expect(d.color, isNull);
      expect(d.borderRadius, isNull);
      expect(d.boxShadow, isNull);
      expect(d.gradient, isNull);
    });

    test('toBoxDecoration 转换', () {
      const d = WFormBorderDecoration(color: Colors.white);
      final bd = d.toBoxDecoration();
      expect(bd, isA<BoxDecoration>());
      expect(bd.color, Colors.white);
    });

    test('copyWith 部分覆盖', () {
      const d = WFormBorderDecoration(color: Colors.white);
      final d2 = d.copyWith(color: Colors.red);
      expect(d2.color, Colors.red);
      expect(d2.borderRadius, isNull);
    });
  });

  group('WFormBorderDecorationExtension — 链式方法', () {
    test('withColor', () {
      const d = WFormBorderDecoration();
      expect(d.withColor(Colors.red).color, Colors.red);
    });

    test('withUniformBorder + withUniformBorderRadius', () {
      const d = WFormBorderDecoration();
      final r = d.withUniformBorder(1.5, Colors.black).withUniformBorderRadius(20);
      expect(r.border, isNotNull);
      expect(r.borderRadius, BorderRadius.circular(20));
    });

    test('withBoxShadow + withGradient', () {
      const d = WFormBorderDecoration();
      final shadows = [const BoxShadow(color: Colors.black, blurRadius: 8)];
      expect(d.withBoxShadow(shadows).boxShadow, shadows);

      const grad = LinearGradient(colors: [Colors.red, Colors.blue]);
      expect(d.withGradient(grad).gradient, grad);
    });
  });

  group('WFormBorderWithData', () {
    testWidgets('无 WFormBuilder → 抛 Exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WFormBorderWithData(
              name: 'test',
              readOnly: false,
              child: Text('c'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNotNull);
    });

    testWidgets('有 WFormBuilder → 正常渲染 + 自动注册 key', (tester) async {
      final formData = WFormData();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: const WFormBorderWithData(
                name: 'email',
                readOnly: false,
                child: Text('input'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('input'), findsOneWidget);
      expect(formData.formBorderKeys.containsKey('email'), true);
    });

    testWidgets('hintTextList 从 WFormBorderWithData 传递', (tester) async {
      final cfg = makeCfg();
      cfg.hintBuilder = (list) => Column(
        children: list!.map((e) => Text(e)).toList(),
      );
      final formData = WFormData();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: cfg,
              child: const WFormBorderWithData(
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
      final key = GlobalKey<WFormBorderState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBorder(
              key: key,
              config: makeCfg(
                errorDecoration: const WFormBorderDecoration(
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

      key.currentState?.setError(true, errorTextList: const ['必填']);
      await tester.pump();

      // 错误态优先于透明背景 → 红框回归
      expect(findBorderWithSideColor(const Color(0xFFC0061A)), findsOneWidget);
    });

    testWidgets('enableFocusBorder 由 true 改 false → 聚焦装饰不再残留', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final formData = WFormData();

      Widget buildWith({required bool enableFocusBorder}) => MaterialApp(
        home: Scaffold(
          body: WFormBuilder(
            formData: formData,
            formBorderConfig: makeCfg(
              defaultDecoration: const WFormBorderDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0xFFEAEAEA), width: 1),
                ),
              ),
              focusedDecoration: const WFormBorderDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.blue, width: 1),
                ),
              ),
            ),
            child: WFormBorderWithData(
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

  group('WFormBuilder.formBorderConfig', () {
    testWidgets('运行时变更 → 子树内边框装饰随之更新', (tester) async {
      final formData = WFormData();
      final cfgNotifier = ValueNotifier<WFormBorderConfig>(
        makeCfg(defaultDecoration: const WFormBorderDecoration(color: Color(0xFF111111))),
      );
      addTearDown(cfgNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<WFormBorderConfig>(
              valueListenable: cfgNotifier,
              builder: (context, cfg, _) => WFormBuilder(
                formData: formData,
                formBorderConfig: cfg,
                child: const WFormBorderWithData(
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
        defaultDecoration: const WFormBorderDecoration(color: Color(0xFF222222)),
      );
      await tester.pump();

      expect(findBorderFillColor(const Color(0xFF222222)), findsOneWidget);
      expect(findBorderFillColor(const Color(0xFF111111)), findsNothing);
    });

    testWidgets('直接使用 WFormBorder 时继承 WFormBuilder.formBorderConfig', (tester) async {
      final cfg = WFormBorderConfig();
      cfg.hintBuilder = (list) => Column(
        children: [for (final e in list ?? const <String>[]) Text('hint-$e')],
      );
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: cfg,
              child: const WFormBorder(
                hintTextList: ['继承成功'],
                child: Text('c'),
              ),
            ),
          ),
        ),
      );

      // 未显式传 config → 继承 builder 的配置，hintBuilder 生效
      expect(find.text('hint-继承成功'), findsOneWidget);
    });

    testWidgets('显式 config 优先于 WFormBuilder.formBorderConfig', (tester) async {
      final builderCfg = WFormBorderConfig();
      builderCfg.hintBuilder = (list) => Text('builder-${list!.first}');

      final borderCfg = WFormBorderConfig();
      borderCfg.hintBuilder = (list) => Text('border-${list!.first}');

      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: builderCfg,
              child: WFormBorder(
                config: borderCfg,
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

  group('Row.withFormBorder（WFormRowBorderExtension）', () {
    testWidgets('readOnly: true → 内部输入组件被置为只读 / 禁用', (tester) async {
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
                  ),
                  Expanded(
                    child: WFormDropdown<String>(
                      config: WFormDropdownConfig(),
                      name: 'b',
                      items: const {'x': 'X'},
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', readOnly: true, hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // WFormTextField 的只读由外层 WFormReadOnlyScope 在 build 时合成
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

      // 类型实参保留；内部 DropdownButton 因外层只读被禁用
      final dropdownFinder = find.byType(WFormDropdown<String>);
      expect(dropdownFinder, findsOneWidget);
      expect(
        tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).onChanged,
        isNull,
      );
    });

    testWidgets('readOnly: true 可穿透任意包装 widget（Padding）', (tester) async {
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
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
      final formData = WFormData();
      final container = Container(
        width: 120,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
        child: WFormTextField(config: WFormTextFieldConfig(), name: 'a'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
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
      expect(tester.getSize(find.byType(WFormTextField)), const Size(120, 48));
    });

    testWidgets('readOnly: true 也会禁用内部 WFormCheckbox', (tester) async {
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormCheckbox(
                      config: WFormCheckboxConfig(),
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

    testWidgets('readOnly: true → 非 String 泛型的 WFormDropdown 也被禁用', (tester) async {
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormDropdown<int>(
                      config: WFormDropdownConfig(),
                      name: 'b',
                      items: const {1: 'ONE'},
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', readOnly: true, hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      final dropdownFinder = find.byWidgetPredicate((w) => w is WFormDropdown);
      expect(dropdownFinder, findsOneWidget);
      // 运行时实参保留；内部 DropdownButton 因外层只读被禁用
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
        isNull,
      );
    });

    testWidgets('readOnly: false 时保留内部原有的 enabled: false（回归）', (tester) async {
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormDropdown<String>(
                      config: WFormDropdownConfig(),
                      name: 'b',
                      items: const {'x': 'X'},
                      enabled: false,
                    ),
                  ),
                ],
              ).withFormBorder(name: 'row', hintTextList: const ['提示']),
            ),
          ),
        ),
      );

      // 修复前会被 `enabled: !readOnly` 强制改回 true
      final dropdownFinder = find.byType(WFormDropdown<String>);
      expect(dropdownFinder, findsOneWidget);
      expect(tester.widget<WFormDropdown<String>>(dropdownFinder).enabled, isFalse);
    });

    testWidgets('内部子组件保留自身的 key（回归）', (tester) async {
      final formData = WFormData();
      final fieldKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
              child: Row(
                children: [
                  Expanded(
                    child: WFormTextField(
                      key: fieldKey,
                      config: WFormTextFieldConfig(),
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
      final formData = WFormData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WFormBuilder(
              formData: formData,
              formBorderConfig: makeCfg(),
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
}
