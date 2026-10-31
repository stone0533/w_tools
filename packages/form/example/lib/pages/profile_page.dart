import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景二：会员资料编辑。
///
/// 展示：下拉、日期、单选、多选、复选、自定义字段按钮、只读作用域。
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
              _readOnly
                  ? Icons.edit_rounded
                  : Icons.visibility_outlined,
            ),
          ),
        ],
      ),
      body: exampleFormTheme(
        child: WFormScope(
          formData: _form,
          child: WFormReadOnlyScope(
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
                _nameField(),
                const SizedBox(height: 16),
                _countryField(),
                const SizedBox(height: 16),
                _birthdayField(),
                const SizedBox(height: 16),
                _genderField(),
                const SizedBox(height: 16),
                _interestsField(),
                const SizedBox(height: 16),
                _marketingField(),
                const SizedBox(height: 16),
                _couponField(),
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
        ),
      ),
    );
  }

  Widget _nameField() {
    final config = exampleTextConfig()
      ..textInputAction = TextInputAction.next;

    return config.build(
      name: 'name',
      hintText: '昵称',
      initialValue: 'Alex',
      bordered: true,
      hintTextList: const ['请输入昵称'],
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '请输入昵称';
        return null;
      },
    );
  }

  Widget _countryField() {
    return exampleDropdownConfig().build<String>(
      name: 'country',
      items: const {
        'CN': '中国大陆',
        'HK': '中国香港',
        'US': '美国',
      },
      initialValue: 'CN',
      hintText: '国家 / 地区',
      bordered: true,
      hintTextList: const ['请选择国家 / 地区'],
      validator: (value) => value == null ? '请选择国家 / 地区' : null,
    );
  }

  Widget _birthdayField() {
    return exampleDateConfig(hintText: '选择生日').build(
      name: 'birthday',
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialValue: '1998-06-18',
      bordered: true,
      hintTextList: const ['请选择生日'],
    );
  }

  Widget _genderField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: (WFormRadioGroupConfig()
              ..style = const TextStyle(fontSize: 16))
            .build<String>(
              name: 'gender',
              items: const {
                'female': '女',
                'male': '男',
              },
              initialValue: 'female',
            ),
      ),
    );
  }

  Widget _interestsField() {
    return exampleMultiConfig().build(
      name: 'interests',
      items: const {
        'music': '音乐',
        'sports': '运动',
        'travel': '旅行',
      },
      initialValue: const {'travel'},
      hintText: '兴趣',
      bordered: true,
      hintTextList: const ['请选择兴趣'],
    );
  }

  Widget _marketingField() {
    return Card(
      elevation: 0,
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: WFormCheckboxConfig().build(
          name: 'marketing',
          title: const Text('接收优惠信息'),
        ),
      ),
    );
  }

  Widget _couponField() {
    final config = WFormFieldButtonConfig()
      ..hintWidget = const Text('请选择优惠券')
      ..height = 52
      ..containerPadding = const EdgeInsets.symmetric(horizontal: 16);

    return config.build(
      name: 'coupon',
      bordered: true,
      initialValue: 'new_user',
      selectedWidgetBuilder: (value) => Text('已选：$value'),
      onTap: (_, didChange) {
        _pickCoupon().then((value) {
          if (value != null) didChange(value);
        });
      },
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
    final valid = _form.validators(
      settings: WFormValidatorSettings()
        ..showBorderError = true
        ..continueOnError = true,
      items: [
        WFormValidatorItem.field('name'),
        WFormValidatorItem.field('country'),
      ],
    ).validate();
    if (!valid) return;

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
            Text('• 下拉 / 日期 / 单选 / 多选 / 复选'),
            Text('• WFormFieldButtonConfig 自定义选择按钮'),
            Text('• WFormReadOnlyScope 一键只读'),
            Text('• WFormValidatorSettings 校验设置'),
          ],
        ),
      ),
    );
  }
}
