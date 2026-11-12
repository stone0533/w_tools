import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// WText / WTextVariant / WTextStyles 的完整演示。
class TextDemoPage extends StatelessWidget {
  const TextDemoPage({super.key});

  static const _variants = <(String, WTextVariant)>[
    ('display', WTextVariant.display),
    ('headline', WTextVariant.headline),
    ('title', WTextVariant.title),
    ('price', WTextVariant.price),
    ('bodyStrong', WTextVariant.bodyStrong),
    ('body', WTextVariant.body),
    ('number', WTextVariant.number),
    ('caption', WTextVariant.caption),
    ('label', WTextVariant.label),
    ('button', WTextVariant.button),
    ('badge', WTextVariant.badge),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = WTextStyles.of(context);
    final brand = base.copyWith(
      title: base.title.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      price: base.price.copyWith(
        color: scheme.tertiary,
        fontSize: 26,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );

    return WScaffold(
      title: 'WText / WTextStyles',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: '11 个 variant',
            subtitle: '默认用 variant；先复用它，再考虑局部 style',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in _variants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 92,
                          child: WText(
                            text: entry.$1,
                            variant: WTextVariant.caption,
                          ),
                        ),
                        Expanded(
                          child: WText(
                            text: '示例文本 Aa 123',
                            variant: entry.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const DemoSection(
            title: 'price / number 的表格数字',
            subtitle: '价格用 tabular figures，避免数字宽度跳动',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WText(
                  text: '¥1,234.00',
                  variant: WTextVariant.price,
                  style: TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: 4),
                WText(
                  text: '¥1,234.50',
                  variant: WTextVariant.price,
                  style: TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                CodeText(
                  "WText(\n"
                  "  text: '¥1,234.00',\n"
                  "  variant: WTextVariant.price,\n"
                  "  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),\n"
                  ")",
                ),
              ],
            ),
          ),
          const DemoSection(
            title: '覆盖参数：maxLines / overflow / softWrap / textAlign',
            subtitle: '只覆盖需要的那一项，不要把整段 TextStyle 抄进来',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: WText(
                    text: '这是一段很长的文本，用来演示 maxLines 与溢出省略。',
                    variant: WTextVariant.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: WText(
                    text: 'softWrap: false 时不会换行',
                    variant: WTextVariant.body,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 260,
                  child: WText(
                    text: 'textAlign: center',
                    variant: WTextVariant.bodyStrong,
                    textAlign: TextAlign.center,
                  ),
                ),
                CodeText(
                  'WText(text: ..., maxLines: 2, overflow: TextOverflow.ellipsis)\n'
                  'WText(text: ..., softWrap: false)\n'
                  'WText(text: ..., textAlign: TextAlign.center)',
                ),
              ],
            ),
          ),
          DemoSection(
            title: '覆盖参数：textScaler / style / color / semanticsLabel',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WText(
                  text: 'textScaler: 1.3',
                  variant: WTextVariant.body,
                  textScaler: TextScaler.linear(1.3),
                ),
                const SizedBox(height: 8),
                const WText(
                  text: 'style: letterSpacing 2',
                  variant: WTextVariant.body,
                  style: TextStyle(letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                WText(
                  text: 'color: colorScheme.error',
                  variant: WTextVariant.body,
                  color: scheme.error,
                ),
                const SizedBox(height: 8),
                const WText(
                  text: 'semanticsLabel',
                  variant: WTextVariant.body,
                  semanticsLabel: '给读屏器的说明',
                ),
                const CodeText(
                  'WText(text: ..., textScaler: const TextScaler.linear(1.3))\n'
                  'WText(text: ..., style: const TextStyle(letterSpacing: 2))\n'
                  'WText(text: ..., color: colorScheme.error)\n'
                  'WText(text: ..., semanticsLabel: ...)',
                ),
              ],
            ),
          ),
          DemoSection(
            title: '自定义 WTextStyles',
            subtitle: 'withWTextStyles 同时写 textTheme 与 WTextStyles 扩展',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Theme(
                  data: Theme.of(context).withWTextStyles(brand),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WText(text: '品牌 title', variant: WTextVariant.title),
                      SizedBox(height: 4),
                      WText(text: '¥2,048.00', variant: WTextVariant.price),
                    ],
                  ),
                ),
                const CodeText(
                  'final brand = WTextStyles.of(context).copyWith(\n'
                  "  title: base.title.copyWith(color: scheme.primary),\n"
                  ");\n"
                  'Theme(\n'
                  '  data: Theme.of(context).withWTextStyles(brand),\n'
                  '  child: ...,\n'
                  ')',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WTextStyles 的 11 个角色',
            subtitle: '兜底来自 TextTheme；安装后按品牌样式解析',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(label: 'body.fontSize', value: base.body.fontSize?.toString() ?? '-'),
                _KeyValue(
                  label: 'title.fontWeight',
                  value: base.title.fontWeight?.toString() ?? '-',
                ),
                _KeyValue(label: 'price.fontSize', value: base.price.fontSize?.toString() ?? '-'),
                const CodeText(
                  'WTextStyles.of(context).copyWith(title: ..., price: ..., number: ...)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: WText(text: label, variant: WTextVariant.caption),
          ),
          WText(text: value, variant: WTextVariant.bodyStrong),
        ],
      ),
    );
  }
}
