import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景二：会员资料编辑。
///
/// 展示：下拉、日期、单选、多选、复选、自定义按钮、只读作用域。
class ProfileExamplePage extends StatefulWidget {
  const ProfileExamplePage({super.key});

  @override
  State<ProfileExamplePage> createState() => _ProfileExamplePageState();
}

class _ProfileExamplePageState extends State<ProfileExamplePage> {
  final _form = WFormController();
  bool _readOnly = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会员资料'),
        actions: [
          IconButton(
            tooltip: _readOnly ? '退出只读' : '只读预览',
            onPressed: () => setState(() => _readOnly = !_readOnly),
            icon: Icon(
              _readOnly ? Icons.edit_rounded : Icons.visibility_outlined,
            ),
          ),
        ],
      ),
      body: WForm(
        controller: _form,
        borderConfig: exampleBorderConfig,
        fieldStyle: exampleFieldStyle,
        dropdownIcon: const Icon(Icons.expand_more_rounded),
        radioUnselectedIcon: const Icon(Icons.radio_button_off),
        radioSelectedIcon: const Icon(Icons.radio_button_checked),
        checkboxUnselectedIcon: const Icon(Icons.check_box_outline_blank),
        checkboxSelectedIcon: const Icon(Icons.check_box),
        validatorSettings: WFormValidatorSettings()
          ..showBorderError = true
          ..continueOnError = true,
        readOnly: _readOnly,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '编辑资料',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _readOnly ? '当前是只读预览，所有字段不可编辑。' : '填写后保存，展示真实表单组合。',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            WFormTextField(
              name: 'name',
              label: '昵称',
              message: '请输入昵称',
              initialValue: 'Alex',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入昵称';
                return null;
              },
            ),
            const SizedBox(height: 16),
            WFormTextField(
              name: 'phone',
              label: '手机号',
              message: '香港手机号 8 位',
              keyboardType: TextInputType.phone,
              inputFormatters: WFormInputFormatters.phone(),
              validator: (value) {
                final digits = (value ?? '').replaceAll(' ', '');
                if (digits.isNotEmpty && digits.length != 8) {
                  return '请输入 8 位手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            WFormDropdown<String>(
              name: 'country',
              label: '国家 / 地区',
              message: '请选择国家 / 地区',
              items: const {
                'CN': '中国大陆',
                'HK': '中国香港',
                'US': '美国',
              },
              initialValue: 'CN',
              validator: (value) => value == null ? '请选择国家 / 地区' : null,
            ),
            const SizedBox(height: 16),
            WFormDatePicker(
              name: 'birthday',
              label: '生日',
              message: '请选择生日',
              initialValue: '1998-06-18',
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              config: WFormDatePickerConfig(
                displayFormat: 'yyyy-MM-dd',
                icon: const Icon(Icons.calendar_today_outlined),
                iconSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 0,
              color: Color(0xFFF9FAFB),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: WFormRadioGroup<String>(
                  name: 'gender',
                  items: {
                    'female': '女',
                    'male': '男',
                  },
                  initialValue: 'female',
                ),
              ),
            ),
            const SizedBox(height: 16),
            WFormMultiDropdown(
              name: 'interests',
              label: '兴趣',
              message: '请选择兴趣',
              items: const {
                'music': '音乐',
                'sports': '运动',
                'travel': '旅行',
              },
              initialValue: const {'travel'},
              config: WFormMultiDropdownConfig(
                disabledKeys: const {'music'},
                itemStyle: const TextStyle(color: Color(0xFF374151)),
                itemCheckedStyle: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              elevation: 0,
              color: Color(0xFFF9FAFB),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: WFormCheckbox(
                  name: 'marketing',
                  title: Text('接收优惠信息'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            WFormButton(
              name: 'coupon',
              label: '请选择优惠券',
              initialValue: 'new_user',
              selectedWidgetBuilder: (value) => Text('已选：$value'),
              onTap: (_, didChange) {
                _pickCoupon().then((value) {
                  if (value != null) didChange(value);
                });
              },
            ),
            const SizedBox(height: 28),
            if (!_readOnly)
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            const SizedBox(height: 16),
            const _ProfileTip(),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickCoupon() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('新客券'),
                onTap: () => Navigator.of(sheetContext).pop('new_user'),
              ),
              ListTile(
                title: const Text('会员专享券'),
                onTap: () => Navigator.of(sheetContext).pop('member_only'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_form.validate()) return;

    setState(() => _saving = true);
    try {
      final values = _form.value;
      debugPrint('profile: $values');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功（示例）')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProfileTip extends StatelessWidget {
  const _ProfileTip();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Color(0xFFF0FDF4),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这个页面覆盖了什么', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('• WForm 统一提供主题 / Scope / 只读'),
            Text('• 下拉 / 日期 / 单选 / 多选 / 复选'),
            Text('• WFormButton 自定义选择按钮'),
            Text('• WFormValidatorSettings 校验设置'),
          ],
        ),
      ),
    );
  }
}
