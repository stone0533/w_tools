import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 扩展页的后半部分：BoxDecoration / Gradients & Shadows。
List<Widget> buildExtensionVisualSections({
  required ColorScheme scheme,
}) {
  return [
    DemoSection(
      title: 'WBoxDecorationExtension',
      subtitle: 'withBackground（color / gradient 二选一）/ circle',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Container(
            width: 72,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration().withBackground(color: scheme.primaryContainer),
            child: const WText(text: 'color', variant: WTextVariant.caption),
          ),
          Container(
            width: 72,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.primary),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: const WText(text: 'border', variant: WTextVariant.caption),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration()
                .withBackground(color: scheme.tertiaryContainer)
                .circle(),
          ),
          Container(
            width: 72,
            height: 48,
            decoration: const BoxDecoration().withBackground(
              gradient: WGradients.vertical(const [Color(0xFF6366F1), Color(0xFF06B6D4)]),
            ),
          ),
        ],
      ),
    ),
    DemoSection(
      title: 'WGradients / WShadows 预设',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final gradient in <Gradient>[
                WGradients.vertical(const [Color(0xFF6366F1), Color(0xFF06B6D4)]),
                WGradients.horizontal(const [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  gradient: WGradients.radial(
                    const [Color(0xFF34D399), Color(0xFF065F46)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final shadow in <List<BoxShadow>>[
                WShadows.none,
                WShadows.card,
                WShadows.elevated,
                WShadows.floating,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: shadow,
                    ),
                  ),
                ),
            ],
          ),
          const CodeText(
            'BoxDecoration(gradient: WGradients.horizontal([...]), boxShadow: WShadows.card)',
          ),
        ],
      ),
    ),
  ];
}
