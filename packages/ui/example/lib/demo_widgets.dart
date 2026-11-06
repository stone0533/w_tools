import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 示例页通用的小组件：分区标题、受限预览框、代码片段。
class DemoSection extends StatelessWidget {
  const DemoSection({
    super.key,
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WText(text: title, variant: WTextVariant.title),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            WText(text: subtitle!, variant: WTextVariant.caption),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 有固定高度的预览框；嵌套 `WScaffold` / `WAppBar` 时必须限高。
class DemoBox extends StatelessWidget {
  const DemoBox({
    super.key,
    required this.child,
    this.height = 240,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 可复制的代码片段。
class CodeText extends StatelessWidget {
  const CodeText(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SelectableText(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

/// 跳转到二级示例页的入口行。
class DemoEntryTile extends StatelessWidget {
  const DemoEntryTile({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WText(text: title, variant: WTextVariant.title),
                    const SizedBox(height: 4),
                    WText(text: description, variant: WTextVariant.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分组标题 + 底部间距；用于 components / buttons 等演示页。
class DemoSectionTitle extends StatelessWidget {
  const DemoSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WText(text: title, variant: WTextVariant.title),
    );
  }
}

/// label / value 的并排小行。
class DemoKeyValue extends StatelessWidget {
  const DemoKeyValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          WText(text: '$label：', variant: WTextVariant.caption),
          WText(text: value, variant: WTextVariant.caption),
        ],
      ),
    );
  }
}
