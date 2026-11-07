import 'package:flutter/material.dart';
import 'package:w_tools_form/w_tools_form.dart';

import '../form_style.dart';

/// 真实场景三：锚定式弹层。
///
/// 展示：WFormPopup + WFormButton 的组合；弹层贴在字段下方，而不是居中 Dialog。
class PopupExamplePage extends StatefulWidget {
  const PopupExamplePage({super.key});

  @override
  State<PopupExamplePage> createState() => _PopupExamplePageState();
}

class _PopupExamplePageState extends State<PopupExamplePage> {
  final _form = WFormController();
  final _anchorKey = GlobalKey();
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('锚定弹层')),
      body: WForm(
        controller: _form,
        fieldStyle: exampleFieldStyle,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '选择优惠券',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'WFormPopup 贴在字段下方，适合选择 / 下拉类交互；确认框仍用 showDialog。',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            Container(
              key: _anchorKey,
              child: WFormButton(
                name: 'coupon',
                label: '请选择优惠券',
                leading: const Icon(Icons.local_offer_outlined),
                selectedWidgetBuilder: (value) => Text('已选：$value'),
                onTap: (_, didChange) async {
                  final value = await _showCouponPopup();
                  if (value != null) {
                    didChange(value);
                    if (mounted) setState(() => _selected = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selected == null ? '尚未选择优惠券' : '当前优惠券：$_selected',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            const Card(
              elevation: 0,
              color: Color(0xFFF0FDF4),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('弹层边界', style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('• WFormPopup 是锚定式弹层，不是居中确认框'),
                    Text('• 同一 Navigator 同时只允许一个 WFormPopup'),
                    Text('• 弹层位置在打开时计算一次，滚动后不自动跟随'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCouponPopup() {
    final anchor = _anchorKey.currentContext;
    if (anchor == null) return Future<String?>.value();

    return WFormPopup.show<String>(
      context: anchor,
      anchorContext: anchor,
      width: 220,
      borderRadius: BorderRadius.circular(12),
      builder: (popupContext) => Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('新客券'),
              onTap: () => Navigator.of(popupContext).pop('new_user'),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('会员专享券'),
              onTap: () => Navigator.of(popupContext).pop('member_only'),
            ),
          ],
        ),
      ),
    );
  }
}
