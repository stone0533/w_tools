import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

void main() {
  testWidgets('WFormController.requireOf 在表单内返回同一 controller', (tester) async {
    final form = WFormController();
    WFormController? seen;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: Builder(
              builder: (context) {
                seen = WFormController.requireOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(seen, same(form));
  });

  testWidgets('无 WForm 祖先时 requireOf 抛 StateError', (tester) async {
    Object? error;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            try {
              WFormController.requireOf(context);
            } catch (e) {
              error = e;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(error, isStateError);
  });

  testWidgets('WFormReadOnly.of 反映只读 / 非只读作用域', (tester) async {
    final form = WFormController();
    late bool insideReadOnly;
    late bool insideEditable;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WForm(
                controller: form,
                readOnly: true,
                child: Builder(
                  builder: (context) {
                    insideReadOnly = WFormReadOnly.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Builder(
                builder: (context) {
                  insideEditable = WFormReadOnly.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(insideReadOnly, isTrue);
    expect(insideEditable, isFalse);
  });

  testWidgets('getFieldsValue<T> 类型不匹配时抛 TypeError', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            child: const WFormTextField(name: 'a', hintText: 'A', initialValue: 'text'),
          ),
        ),
      ),
    );

    expect(() => form.getFieldsValue<int>('a'), throwsA(isA<TypeError>()));
  });
}
