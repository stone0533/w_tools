// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景四：字段级配置与 controller 读取。
class AdvancedFieldsPage extends StatefulWidget {
  const AdvancedFieldsPage({super.key});

  @override
  State<AdvancedFieldsPage> createState() => _AdvancedFieldsPageState();
}

class _AdvancedFieldsPageState extends State<AdvancedFieldsPage> {
  final _form = WFormController();
  String? _snapshot;
  String? _validationResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高级字段')),
      body: WForm(
        controller: _form,
        borderConfig: exampleBorderConfig,
        fieldStyle: exampleFieldStyle,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        dropdownIcon: const Icon(Icons.expand_more_rounded),
        checkboxUnselectedIcon: const Icon(Icons.check_box_outline_blank),
        checkboxSelectedIcon: const Icon(Icons.check_box),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '字段配置',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '展示 leading / maxLines / 禁用下拉 / 自定义勾选与单选样式。',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            const WFormTextField(
              name: 'bio',
              label: '个人简介',
              message: '最多三行',
              maxLines: 3,
              leading: Icon(Icons.notes_rounded),
            ),
            const SizedBox(height: 16),
            const WFormDropdown<String>(
              name: 'city',
              label: '城市',
              initialValue: 'HK',
              enabled: false,
              items: {'HK': '香港', 'SZ': '深圳', 'SH': '上海'},
              icon: Icon(Icons.lock_outline_rounded),
            ),
            const SizedBox(height: 16),
            const WFormCheckbox(
              name: 'agree',
              title: Text('接收产品更新'),
              initialValue: true,
              unselectedIcon: Icon(Icons.check_box_outline_blank),
              selectedIcon: Icon(Icons.check_box),
            ),
            const SizedBox(height: 16),
            const WFormRadioGroup<String>(
              name: 'level',
              items: {'basic': '基础', 'pro': '专业'},
              initialValue: 'basic',
              style: TextStyle(fontWeight: FontWeight.w500),
              selectedIcon: Icon(Icons.radio_button_checked),
              unselectedIcon: Icon(Icons.radio_button_off),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _form.setValue('bio', '由 controller 写入的简介');
                    _form.setValue('level', 'pro');
                  },
                  icon: const Icon(Icons.edit_note),
                  label: const Text('写入示例值'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _form.clearValue('bio'),
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('清空简介'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _snapshot =
                          'values: ${_form.value}\n'
                          'fields: ${_form.getFieldsValue<String>('bio')}';
                      _snapshot =
                          '$_snapshot\n'
                          'formEntered: ${_form.formEntered}\n'
                          'entered: ${_form.isAllEntered(['bio', 'agree', 'level'])}';
                    });
                  },
                  icon: const Icon(Icons.memory),
                  label: const Text('读取 controller 状态'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final ok = _form.validate(
                  items: [
                    WFormValidatorItem(
                      fieldName: 'bio',
                      validatorBuilder: () => (value) {
                        final text = value as String? ?? '';
                        return text.contains('!') ? '简介不能包含感叹号' : null;
                      },
                    ),
                  ],
                );
                setState(() {
                  _validationResult = ok ? '自定义校验通过' : '自定义校验失败';
                });
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('自定义校验'),
            ),
            if (_snapshot != null) ...[
              const SizedBox(height: 8),
              Text(
                _snapshot!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF374151),
                ),
              ),
            ],
            if (_validationResult != null) ...[
              const SizedBox(height: 8),
              Text(_validationResult!),
            ],
          ],
        ),
      ),
    );
  }
}
