import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 扩展页的后半部分：GlobalKey / BoxDecoration / Gradients & Shadows。
List<Widget> buildExtensionVisualSections({
  required BuildContext context,
  required ColorScheme scheme,
  required GlobalKey boxKey,
  required String? position,
  required ValueChanged<String?> onPosition,
}) {
  return [
    DemoSection(
      title: 'WGlobalKeyExtension：offset() / rect()',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: boxKey,
              width: 80,
              height: 40,
              alignment: Alignment.center,
              color: scheme.primaryContainer,
              child: const WText(text: 'target', variant: WTextVariant.caption),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              WButton(
                label: '读取位置',
                style: WButtonStyleSet.of(context).secondary,
                onTap: () {
                  final offset = boxKey.offset();
                  final rect = boxKey.rect();
                  onPosition('offset=$offset\nrect=$rect');
                },
              ),
            ],
          ),
          if (position != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              position,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ],
      ),
    ),
    DemoSection(
      title: 'WBoxDecorationExtension',
      subtitle: 'withColor / withBorder / withBorderRadius / withShadow / withShape',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Container(
            width: 72,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration()
                .withColor(scheme.primaryContainer)
                .withBorderRadius(const BorderRadius.all(Radius.circular(10))),
            child: const WText(text: 'color', variant: WTextVariant.caption),
          ),
          Container(
            width: 72,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration()
                .withColor(scheme.surface)
                .withBorder(Border.all(color: scheme.primary))
                .withBorderRadius(const BorderRadius.all(Radius.circular(10))),
            child: const WText(text: 'border', variant: WTextVariant.caption),
          ),
          Container(
            width: 72,
            height: 48,
            decoration: const BoxDecoration()
                .withColor(scheme.secondaryContainer)
                .withBorderRadius(const BorderRadius.all(Radius.circular(10)))
                .withShadow(WShadows.card),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration()
                .withColor(scheme.tertiaryContainer)
                .withShape(BoxShape.circle),
          ),
          Container(
            width: 72,
            height: 48,
            decoration: const BoxDecoration()
                .withGradient(
                  WGradients.vertical([const Color(0xFF6366F1), const Color(0xFF06B6D4)]),
                )
                .withBorderRadius(const BorderRadius.all(Radius.circular(10))),
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
