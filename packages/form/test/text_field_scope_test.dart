import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 插槽里跟随输入值变化的**唯一受支持写法**：订阅 `valueListenable`。
///
/// 这条是 FORM-002 的回归网：`WFormTextFieldData.of(context)` 本身只在
/// 密码可见性 / 只读变化时通知，直接读 `hasText` 不重建。
class _SearchAction extends StatelessWidget {
  const _SearchAction();

  @override
  Widget build(BuildContext context) {
    final data = WFormTextFieldData.of(context);
    if (data == null) return const Text('no-scope');
    return ListenableBuilder(
      listenable: data.valueListenable,
      builder: (context, _) => Text(data.hasText ? 'has-text' : 'empty'),
    );
  }
}

void main() {
  test('WFormTextFieldData 可以被消费方实现（可 fake）', () {
    final WFormTextFieldData data = _FakeTextFieldData();
    expect(data.hasText, isTrue);
    expect(data.value, 'fake');
  });

  testWidgets('插槽订阅 valueListenable 后会跟随输入重建', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: WFormController(),
            child: const WFormTextField(
              name: 'q',
              hintText: '搜索',
              actions: [_SearchAction()],
            ),
          ),
        ),
      ),
    );

    expect(find.text('empty'), findsOneWidget);

    await tester.enterText(find.byType(WFormTextField), 'abc');
    await tester.pump();

    expect(find.text('has-text'), findsOneWidget);
  });
}

/// FORM-026：接口必须可以被消费方实现（用于在测试里 fake 输入框状态）。
class _FakeTextFieldData implements WFormTextFieldData {
  @override
  bool get isPasswordVisible => false;

  @override
  bool get obscureText => false;

  @override
  String? get value => 'fake';

  @override
  bool get hasText => true;

  @override
  bool get readOnly => false;

  @override
  ValueListenable<String?> get valueListenable => ValueNotifier<String?>('fake');

  @override
  void togglePasswordVisibility() {}

  @override
  void clear() {}
}
