import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_form/w_tools_form.dart';

/// 防止 README / docs/agents/form.md 中的公开 API 示例随重构失效。
///
/// 测试不解析 Markdown，而是用同一组入口做编译和渲染校验；
/// 文档中的 API 改名时，这里会先红。
void main() {
  testWidgets('README / form agents 示例使用的直接 API 可编译', (tester) async {
    final form = WFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WForm(
            controller: form,
            borderConfig: WFormBorderConfig.standard(radius: 12),
            fieldStyle: const WFormFieldStyle(
              height: 52,
              containerPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            validatorSettings: WFormValidatorSettings()..showBorderError = true,
            child: ListView(
              children: [
                WFormTextField(
                  name: 'email',
                  label: '邮箱',
                  message: '请输入邮箱',
                  validator: (value) => (value == null || value.isEmpty) ? '请输入邮箱' : null,
                ),
                const WFormDropdown<String>(
                  name: 'country',
                  label: '国家 / 地区',
                  items: {
                    'CN': '中国大陆',
                    'HK': '中国香港',
                  },
                ),
                const WFormMultiDropdown(
                  name: 'interests',
                  label: '兴趣',
                  items: {
                    'music': '音乐',
                    'travel': '旅行',
                  },
                ),
                const WFormDatePicker(
                  name: 'birthday',
                  label: '生日',
                ),
                const WFormCheckbox(
                  name: 'marketing',
                  title: Text('接收优惠信息'),
                ),
                const WFormRadioGroup<String>(
                  name: 'gender',
                  items: {
                    'female': '女',
                    'male': '男',
                  },
                ),
                WFormButton(
                  name: 'coupon',
                  label: '选择优惠券',
                  onTap: (_, didChange) => didChange('new_user'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('邮箱'), findsWidgets);
    expect(form.validate(), isFalse);
  });
}
