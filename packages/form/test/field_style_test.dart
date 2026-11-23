import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

const _red = Color(0xFFFF0000);

void main() {
  group('WFormFieldStyle 值语义', _styleEqualityTests);

  testWidgets('WForm.fieldStyle.textStyle 作用于复选框标题', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(textStyle: TextStyle(color: _red)),
            child: const WFormCheckbox(name: 'agree', title: Text('同意')),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('同意'));
    expect(paragraph.text.style?.color, _red);
  });

  testWidgets('WForm.fieldStyle.placeholderStyle 作用于日期字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(placeholderStyle: TextStyle(color: _red)),
            child: const WFormDatePicker(name: 'birthday', hintText: '生日'),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('生日'));
    expect(paragraph.text.style?.color, _red);
  });

  testWidgets('WForm.fieldStyle.placeholderStyle 作用于多选字段占位符', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(placeholderStyle: TextStyle(color: _red)),
            child: const WFormMultiDropdown(
              name: 'tags',
              hintText: '标签',
              items: {'a': 'A'},
            ),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text('标签'));
    expect(paragraph.text.style?.color, _red);
  });
}

/// 用运行期参数构造，避免 const canonicalize 成同一实例：
/// 那样断言 == 即使没有 operator== 也会过，测不到值语义。
WFormFieldStyle _makeStyle(double height) => WFormFieldStyle(
  height: height,
  containerPadding: const EdgeInsets.symmetric(horizontal: 16),
  textStyle: const TextStyle(color: _red),
  placeholderStyle: const TextStyle(color: _red),
);

void _styleEqualityTests() {
  test('WFormFieldStyle 按值相等（与 WFormBorderStyle / WFormValidatorSettings 一致）', () {
    final a = _makeStyle(52);
    final b = _makeStyle(52);

    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == _makeStyle(53), isFalse);
  });

  testWidgets('WFormFieldStyleScope 默认整体替换外层样式', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            fieldStyle: const WFormFieldStyle(
              height: 40,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
              textStyle: TextStyle(color: _red),
              placeholderStyle: TextStyle(color: _red),
            ),
            child: const WFormFieldStyleScope(
              style: WFormFieldStyle(height: 72),
              child: WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style, isNull);
    expect(field.decoration?.hintStyle, isNull);
    // containerPadding 也丢掉了：内容贴到最左边。
    expect(tester.getRect(find.byType(TextField)).left, 0);
  });

  testWidgets('pageStyle.copyWith(height:) 只覆盖高度，其余沿用页面样式', (tester) async {
    final form = WFormController();
    const page = WFormFieldStyle(
      height: 40,
      containerPadding: EdgeInsets.symmetric(horizontal: 16),
      textStyle: TextStyle(color: _red),
      placeholderStyle: TextStyle(color: _red),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            fieldStyle: page,
            child: WFormFieldStyleScope(
              style: page.copyWith(height: 72),
              child: const WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, _red);
    expect(field.decoration?.hintStyle?.color, _red);
    expect(tester.getRect(find.byType(TextField)).left, 16);
    expect(tester.getSize(find.byType(WFormTextField)).height, 72);
  });

  testWidgets('mergeWithParent: true 只覆盖 height，其余沿用页面样式', (tester) async {
    final form = WFormController();
    const page = WFormFieldStyle(
      height: 40,
      containerPadding: EdgeInsets.symmetric(horizontal: 16),
      textStyle: TextStyle(color: _red),
      placeholderStyle: TextStyle(color: _red),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            fieldStyle: page,
            child: const Column(
              children: [
                WFormTextField(name: 'a', hintText: 'A'),
                WFormFieldStyleScope(
                  style: WFormFieldStyle(height: 72),
                  mergeWithParent: true,
                  child: WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final a = tester.widget<TextField>(find.byType(TextField).at(0));
    final b = tester.widget<TextField>(find.byType(TextField).at(1));

    // 页面字段仍是完整样式。
    expect(a.style?.color, _red);

    // 合并字段：height 被覆盖，padding / 文字 / 占位样式沿用页面。
    expect(b.style?.color, _red);
    expect(b.decoration?.hintStyle?.color, _red);
    expect(tester.getRect(find.byType(TextField).at(1)).left, 16);
    expect(tester.getSize(find.byType(WFormTextField).at(1)).height, 72);
  });

  testWidgets('mergeWithParent: true + style: null 表示完全沿用外层（不清空）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(
              height: 40,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
              textStyle: TextStyle(color: _red),
            ),
            child: const WFormFieldStyleScope(
              style: null,
              mergeWithParent: true,
              child: WFormTextField(name: 'a', hintText: 'A'),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, _red);
    expect(tester.getRect(find.byType(TextField)).left, 16);
    expect(tester.getSize(find.byType(WFormTextField)).height, 40);
  });

  testWidgets('mergeWithParent: true 没有外层样式时等同直接传 style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormFieldStyleScope(
              style: WFormFieldStyle(height: 72),
              mergeWithParent: true,
              child: WFormTextField(name: 'a', hintText: 'A', maxLines: 3),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WFormTextField)).height, 72);
    expect(tester.widget<TextField>(find.byType(TextField)).style, isNull);
  });

  testWidgets('mergeWithParent 逐层向外合并', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(
              height: 40,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
              textStyle: TextStyle(color: _red),
            ),
            child: const WFormFieldStyleScope(
              style: WFormFieldStyle(containerPadding: EdgeInsets.symmetric(horizontal: 24)),
              mergeWithParent: true,
              child: WFormFieldStyleScope(
                style: WFormFieldStyle(height: 72),
                mergeWithParent: true,
                child: WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
              ),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, _red); // 页面
    expect(tester.getRect(find.byType(TextField)).left, 24); // 中间层
    expect(tester.getSize(find.byType(WFormTextField)).height, 72); // 内层
  });

  testWidgets('中间层是整体替换时，合并到它为止', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: const WFormFieldStyle(
              height: 40,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
              textStyle: TextStyle(color: _red),
            ),
            child: const WFormFieldStyleScope(
              // 整体替换：只给 height，丢掉页面的 padding / textStyle
              style: WFormFieldStyle(height: 60),
              child: WFormFieldStyleScope(
                style: WFormFieldStyle(height: 72),
                mergeWithParent: true,
                child: WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
              ),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style, isNull); // 中间层已替换掉页面 textStyle
    expect(tester.getRect(find.byType(TextField)).left, 0); // 页面 padding 不参与
    expect(tester.getSize(find.byType(WFormTextField)).height, 72);
  });

  testWidgets('mergeWithParent 跟随页面 fieldStyle 运行期变化', (tester) async {
    final form = WFormController();
    const blue = Color(0xFF0000FF);

    Widget build(Color color) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: form,
          fieldStyle: WFormFieldStyle(
            height: 40,
            containerPadding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: TextStyle(color: color),
          ),
          child: const WFormFieldStyleScope(
            style: WFormFieldStyle(height: 72),
            mergeWithParent: true,
            child: WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(_red));
    expect(tester.widget<TextField>(find.byType(TextField)).style?.color, _red);

    await tester.pumpWidget(build(blue));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).style?.color, blue);
  });

  testWidgets('WFormFieldStyle.copyWith 保留未指定的字段', (tester) async {
    const page = WFormFieldStyle(
      height: 40,
      containerPadding: EdgeInsets.symmetric(horizontal: 16),
      textStyle: TextStyle(color: _red),
      placeholderStyle: TextStyle(color: _red),
    );
    final scoped = page.copyWith(height: 72);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            fieldStyle: page,
            child: WFormFieldStyleScope(
              style: scoped,
              child: const WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, _red);
    expect(tester.getRect(find.byType(TextField)).left, 16);
    expect(tester.getSize(find.byType(WFormTextField)).height, 72);
  });

  testWidgets('WForm 未传 fieldStyle 时保留外层 WFormFieldStyleScope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WFormFieldStyleScope(
            style: const WFormFieldStyle(
              height: 52,
              textStyle: TextStyle(color: _red),
            ),
            child: WForm(
              controller: WFormController(),
              child: const WFormTextField(name: 'a', hintText: 'A'),
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, _red);
    expect(tester.getSize(find.byType(WFormTextField)).height, 52);
  });
}
