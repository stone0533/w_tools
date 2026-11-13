import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';
import 'extensions_page_sections.dart';

/// 7 个扩展文件 + 颜色预设 / 阴影 / 渐变 的完整演示。
class ExtensionsDemoPage extends StatefulWidget {
  const ExtensionsDemoPage({super.key});

  @override
  State<ExtensionsDemoPage> createState() => _ExtensionsDemoPageState();
}

class _ExtensionsDemoPageState extends State<ExtensionsDemoPage> {
  final GlobalKey _boxKey = GlobalKey();
  int _taps = 0;
  String? _position;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = TextStyle(fontSize: 14, color: scheme.onSurface);

    return WScaffold.basic(
      title: '扩展方法',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: 'WNumLayoutExtension / WNumFormatExtension：间距 / 圆角 / 数字格式',
            subtitle: 'heightBox / widthBox / squareBox / allPadding / 格式化',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 32, height: 32, color: scheme.primary),
                    8.widthBox,
                    Container(width: 32, height: 32, color: scheme.secondary),
                    8.widthBox,
                    Container(width: 32, height: 32, color: scheme.tertiary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 32, height: 32, color: scheme.primary),
                    8.squareBox,
                    Container(width: 32, height: 32, color: scheme.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: 12.allPadding,
                    child: const WText(
                      text: '12.allPadding',
                      variant: WTextVariant.body,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _KeyValue(label: '1234.toThousandsSeparated', value: 1234.toThousandsSeparated),
                _KeyValue(
                  label: "1234.5.toCurrency(symbol: '¥')",
                  value: 1234.5.toCurrency(symbol: '¥'),
                ),
                _KeyValue(label: '0.125.toPercent', value: 0.125.toPercent),
                _KeyValue(label: '0.125.toPercentWithFixed(2)', value: 0.125.toPercentWithFixed(2)),
                _KeyValue(label: '42.toPadLeft(5)', value: 42.toPadLeft(5)),
                _KeyValue(label: '12.borderRadius', value: 12.borderRadius.toString()),
                const CodeText(
                  'Container(width: 32, height: 32), 8.widthBox, ...\n'
                  'Padding(padding: 12.allPadding, child: ...)\n'
                  '1234.5.toCurrency(symbol: "¥")',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WStringExtension：数字 / 去空格 / 颜色 / 资源路径',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(label: "'42'.toInt()", value: '${'42'.toInt()}'),
                _KeyValue(label: "'3.14'.toDouble()", value: '${'3.14'.toDouble()}'),
                _KeyValue(label: "'1e3'.toNum()", value: '${'1e3'.toNum()}'),
                _KeyValue(label: "' a b\\nc '.trimAll()", value: ' a b\nc '.trimAll()),
                _KeyValue(label: "'logo.png'.assetImagePath", value: 'logo.png'.assetImagePath),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 24, height: 24, color: '#FF5733'.toColor()),
                    8.widthBox,
                    const WText(text: "'#FF5733'.toColor()", variant: WTextVariant.caption),
                  ],
                ),
              ],
            ),
          ),
          DemoSection(
            title: '颜色：WColorExtension / toHex',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 24, height: 24, color: WColorExtension.fromHex('#4F46E5')),
                    8.widthBox,
                    const WText(
                      text: "WColorExtension.fromHex('#4F46E5')",
                      variant: WTextVariant.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 24, height: 24, color: '#80FF5733'.toColor()),
                    8.widthBox,
                    const WText(
                      text: "'#80FF5733'（alpha 在前）",
                      variant: WTextVariant.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _KeyValue(
                  label: "scheme.primary.toHex()",
                  value: scheme.primary.toHex(),
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'TextStyle.copyWith',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('bold', style: baseStyle.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  'color(error)',
                  style: baseStyle.copyWith(color: scheme.error),
                ),
                Text('fontSize(20)', style: baseStyle.copyWith(fontSize: 20)),
                const CodeText(
                  'TextStyle.copyWith(fontWeight: ...) / copyWith(color: ...) / copyWith(fontSize: ...)',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WWidgetExtension：布局 / 间距 / 装饰 / 点击',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(height: 24, color: scheme.primary).expanded(),
                    8.widthBox,
                    Container(height: 24, color: scheme.secondary).expanded(2),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(width: 20, height: 20, color: scheme.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(width: 20, height: 20, color: scheme.secondary),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      color: scheme.tertiary,
                    ).withStartPadding(4),
                    Container(
                      width: 20,
                      height: 20,
                      color: scheme.error,
                    ).withEndPadding(4),
                  ],
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 60,
                          color: scheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          color: scheme.surfaceContainerHighest,
                          padding: const EdgeInsets.all(8),
                          child: const WText(
                            text: 'IntrinsicHeight 让两列等高',
                            variant: WTextVariant.caption,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120,
                  height: 40,
                  alignment: Alignment.center,
                  child: const WText(text: 'withDecoration', variant: WTextVariant.caption),
                ).withDecoration(
                  const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)]),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: WText(
                    text: 'toPressable 点击 $_taps 次',
                    variant: WTextVariant.caption,
                  ),
                ).toPressable(onTap: () => setState(() => _taps++)),
                const SizedBox(height: 8),
                WText(
                  text:
                      'withTopSafeSpace / withBottomBarSpace：按平台安全区加 Padding'
                      '（当前 status=${WScreen.statusBarHeight.toStringAsFixed(1)}，'
                      'bottom=${WScreen.bottomSafeAreaHeight.toStringAsFixed(1)}）',
                  variant: WTextVariant.caption,
                ),
              ],
            ),
          ),
          ...buildExtensionVisualSections(
            context: context,
            scheme: scheme,
            boxKey: _boxKey,
            position: _position,
            onPosition: (value) => setState(() => _position = value),
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
