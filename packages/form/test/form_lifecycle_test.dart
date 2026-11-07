import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('onChanged 覆盖复选框与 reset', (tester) async {
    final form = WFormController();
    final events = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            onChanged: (values) => events.add(Map.of(values)),
            child: const WFormCheckbox(name: 'agree', title: Text('同意')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('同意'));
    await tester.pump();
    form.reset();
    await tester.pump();

    expect(events, [
      {'agree': true},
      {'agree': false},
    ]);
  });

  testWidgets('运行期修改 validatorSettings 会同步到 controller', (tester) async {
    final form = WFormController();
    Widget build(WFormValidatorSettings settings) => MaterialApp(
      home: Scaffold(
        body: WForm(controller: form, validatorSettings: settings, child: const SizedBox()),
      ),
    );

    const off = WFormValidatorSettings();
    await tester.pumpWidget(build(off));
    expect(form.validatorSettings, same(off));

    const on = WFormValidatorSettings(showBorderError: true);
    await tester.pumpWidget(build(on));
    expect(form.validatorSettings, same(on));
  });

  testWidgets('字段 name 变化会清理旧 formEntered', (tester) async {
    final form = WFormController();
    var name = 'a';
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return WForm(
                controller: form,
                child: WFormTextField(name: name, label: 'A'),
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    expect(form.formEntered['a'], isTrue);

    setHostState(() => name = 'b');
    await tester.pump();

    expect(form.formEntered.containsKey('a'), isFalse);
  });

  testWidgets('WFormFieldStyleScope 运行期变化会更新字段高度', (tester) async {
    Widget build(double height) => MaterialApp(
      home: Scaffold(
        body: WForm(
          controller: WFormController(),
          child: WFormFieldStyleScope(
            style: WFormFieldStyle(height: height),
            child: const WFormTextField(name: 'a', label: 'A'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(52));
    expect(tester.getSize(find.byType(WFormTextField)).height, 52);

    await tester.pumpWidget(build(72));
    expect(tester.getSize(find.byType(WFormTextField)).height, 72);
  });

  testWidgets('WForm 在 GlobalKey 重新挂载时保持 controller 所有权', (tester) async {
    final form = WFormController();
    final formKey = GlobalKey();
    final formWidget = WForm(
      key: formKey,
      controller: form,
      child: const WFormTextField(name: 'a', label: 'A'),
    );

    Widget build({required bool firstParent}) => MaterialApp(
      home: Scaffold(
        body: firstParent
            ? Column(children: [formWidget])
            : Row(children: [Expanded(child: formWidget)]),
      ),
    );

    await tester.pumpWidget(build(firstParent: true));
    expect(find.text('A'), findsWidgets);

    await tester.pumpWidget(build(firstParent: false));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('w-form-duplicate-controller')), findsNothing);
    expect(find.text('A'), findsWidgets);
  });

  testWidgets('下拉字段 name 变化会清理旧 formEntered', (tester) async {
    final form = WFormController();
    var name = 'a';
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return WForm(
                controller: form,
                child: WFormDropdown<String>(
                  name: name,
                  label: 'A',
                  bordered: false,
                  items: const {'x': 'X'},
                ),
              );
            },
          ),
        ),
      ),
    );

    form.updateValue('a', 'x');
    await tester.pump();
    expect(form.formEntered['a'], isTrue);

    setHostState(() => name = 'b');
    await tester.pump();

    expect(form.formEntered.containsKey('a'), isFalse);
  });

  testWidgets('savedValue / getFieldsValue / setError callback', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderStyle: WFormBorderStyle.standard(),
            child: const WFormTextField(name: 'email', label: '邮箱'),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.pump();
    expect(form.getFieldsValue<String>('email'), 'a@b.com');

    form.validate();
    expect(form.savedValue['email'], 'a@b.com');

    var called = 0;
    form.setError('email', callback: () => called++);
    expect(called, 1);

    form.handleChange('email', 'b@c.com', callback: () => called++);
    expect(called, 2);
  });

  testWidgets('多选弹层跟随外部值变化', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormMultiDropdown(
              name: 'tags',
              label: '标签',
              items: {'a': 'A', 'b': 'B'},
              initialValue: {'a'},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    form.setValue<Set<String>>('tags', {});
    await tester.pump();
    expect(find.byIcon(Icons.check_box), findsNothing);
  });

  testWidgets('日期字段 firstDate 在未来时也能打开选择器', (tester) async {
    final form = WFormController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: WFormDatePicker(
              name: 'future',
              label: '未来',
              firstDate: DateTime(2030),
              lastDate: DateTime(2040),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('未来'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
