import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// WButton 使用场景示例。
class ButtonsPage extends StatefulWidget {
  const ButtonsPage({super.key});

  @override
  State<ButtonsPage> createState() => _ButtonsPageState();
}

class _ButtonsPageState extends State<ButtonsPage> {
  static const _hero = WButtonSize(
    name: 'hero',
    minHeight: 56,
    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  var _submitting = false;
  var _enabled = true;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _enabled = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提交完成（示例中禁用提交按钮）')),
    );
  }

  void _showConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除？'),
        content: const Text('删除后不可恢复。'),
        actions: [
          WButton.text(
            '取消',
            onTap: () => Navigator.pop(dialogContext),
          ),
          WButton.danger(
            '删除',
            onTap: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除（示例）')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: '1. 项目主题：定义一次，页面一行',
          subtitle: '主按钮 / 次按钮 / 文字按钮 / 危险按钮',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              WButton.primary('提交', onTap: _submit),
              WButton.secondary('取消', onTap: () {}),
              WButton.text('查看更多', onTap: () {}),
              WButton.danger('删除', onTap: _showConfirmDialog),
            ],
          ),
        ),
        _Section(
          title: '2. 表单提交：loading / disabled',
          subtitle: 'loading 保持按钮尺寸，不会跳版',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WButton.primary(
                '提交',
                enabled: _enabled,
                loading: _submitting,
                onTap: _submit,
              ),
              WButton.secondary(
                '重置',
                enabled: !_submitting,
                onTap: () => setState(() => _enabled = true),
              ),
              Text(_submitting ? '提交中…' : (_enabled ? '可提交' : '已提交')),
            ],
          ),
        ),
        _Section(
          title: '3. 尺寸：默认 3 档 + 任意自定义',
          subtitle: '尺寸是值对象，不是固定 enum',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WButton.primary('Small', size: WButtonSize.small, onTap: () {}),
              WButton.primary('Medium', size: WButtonSize.medium, onTap: () {}),
              WButton.primary('Large', size: WButtonSize.large, onTap: () {}),
              WButton.primary('Hero', size: _hero, onTap: () {}),
            ],
          ),
        ),
        _Section(
          title: '4. 图标按钮 / 纯图标工具栏',
          subtitle: '图标按钮建议提供 tooltip',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WButton.icon(
                Icons.add,
                label: '新增',
                onTap: () {},
              ),
              WButton.icon(
                Icons.refresh,
                tooltip: '刷新',
                onTap: () {},
              ),
              WButton.icon(
                Icons.more_horiz,
                tooltip: '更多',
                onTap: () {},
              ),
              WButton.icon(
                Icons.delete_outline,
                tooltip: '删除',
                style: WButtonStyles.danger,
                onTap: _showConfirmDialog,
              ),
            ],
          ),
        ),
        _Section(
          title: '5. 列表行操作：紧凑文字按钮',
          subtitle: '适合表格/列表右侧操作',
          child: Card(
            child: Column(
              children: [
                for (var i = 1; i <= 3; i++)
                  ListTile(
                    leading: CircleAvatar(child: Text('$i')),
                    title: Text('列表项 $i'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WButton.text(
                          '编辑',
                          size: WButtonSize.small,
                          onTap: () {},
                        ),
                        WButton.text(
                          '删除',
                          size: WButtonSize.small,
                          style: WButtonStyles.danger,
                          onTap: _showConfirmDialog,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        _Section(
          title: '6. 对话框：取消 / 危险确认',
          subtitle: '在 AlertDialog.actions 中直接使用',
          child: WButton.secondary(
            '打开确认框',
            onTap: _showConfirmDialog,
          ),
        ),
        _Section(
          title: '7. 项目自定义变体',
          subtitle: 'variants 中注册 brand / warning 等',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              WButton.variant('brand', '品牌按钮', onTap: () {}),
              WButton.variant('warning', '警告按钮', onTap: () {}),
            ],
          ),
        ),
        _Section(
          title: '8. 纯点击区域：包裹任意 child',
          subtitle: 'effect: none 时不改变子组件视觉',
          child: WButton(
            style: const WButtonStyle(effect: WButtonEffectType.none),
            onTap: () {},
            child: const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('点击整行'),
                subtitle: Text('可点击的卡片 / 列表项 / 自定义内容'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ),
        ),
        _Section(
          title: '10. 复杂按钮：多行文本 + 图片 + 图标',
          subtitle: '复杂内容直接用 child，一行式只服务简单文本/图标',
          child: WButton(
            style: WButtonStyles.primary.copyWith(
              container: WContainerConfig()
                ..padding = const EdgeInsets.all(12)
                ..color = Colors.white
                ..borderRadius = BorderRadius.circular(12)
                ..border = Border.all(color: Colors.black12),
              minHeight: 88,
              effect: WButtonEffectType.scale,
              pressedScale: 0.99,
              semanticLabel: '订单 A123，3 件商品，待支付，共 128 元',
              semanticHint: '双击查看订单详情',
            ),
            onTap: () {},
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WImage.assetImage(
                  'demo.png',
                  style: const WImageStyle(
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '订单 #A123',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '3 件商品 · 待支付',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '¥ 128.00',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Spacer(),
                          const Text(
                            '查看详情',
                            style: TextStyle(
                              color: Color(0xFF3949AB),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right, color: Colors.black38),
                ),
              ],
            ),
          ),
        ),
        _Section(
          title: '9. 键盘与无障碍',
          subtitle: 'Tab 聚焦，Enter / Space 激活',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              WButton.primary(
                '聚焦我',
                autofocus: true,
                tooltip: '按 Enter 或 Space 触发',
                onTap: () {},
              ),
              WButton.secondary(
                '带语义的按钮',
                style: const WButtonStyle(
                  semanticLabel: '保存草稿',
                  semanticHint: '保存当前内容但不提交',
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
