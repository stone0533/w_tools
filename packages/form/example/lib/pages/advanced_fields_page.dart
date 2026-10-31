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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高级字段')),
      body: WForm(
        controller: _form,
        borderConfig: exampleBorderConfig,
        fieldStyle: exampleFieldStyle,
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
            WFormTextField(
              name: 'bio',
              label: '个人简介',
              message: '最多三行',
              maxLines: 3,
              config: WFormTextFieldConfig()..leading = const Icon(Icons.notes_rounded),
            ),
            const SizedBox(height: 16),
            WFormDropdown<String>(
              name: 'city',
              label: '城市',
              initialValue: 'HK',
              enabled: false,
              items: const {'HK': '香港', 'SZ': '深圳', 'SH': '上海'},
              config: WFormDropdownConfig(
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            WFormCheckbox(
              name: 'agree',
              title: const Text('接收产品更新'),
              initialValue: true,
              config: WFormCheckboxConfig(
                unselectedIcon: const Icon(Icons.check_box_outline_blank),
                selectedIcon: const Icon(Icons.check_box),
              ),
            ),
            const SizedBox(height: 16),
            WFormRadioGroup<String>(
              name: 'level',
              items: const {'basic': '基础', 'pro': '专业'},
              initialValue: 'basic',
              config: WFormRadioGroupConfig(
                style: const TextStyle(fontWeight: FontWeight.w500),
                selectedIcon: const Icon(Icons.radio_button_checked),
                unselectedIcon: const Icon(Icons.radio_button_off),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _snapshot =
                      'values: ${_form.value}\n'
                      'entered: ${_form.isAllEntered(['bio', 'agree', 'level'])}';
                });
              },
              icon: const Icon(Icons.memory),
              label: const Text('读取 controller 状态'),
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
          ],
        ),
      ),
    );
  }
}
