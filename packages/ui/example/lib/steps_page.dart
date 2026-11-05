import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// WStep / WStepFlow / WStepStyle 的完整演示。
class StepsDemoPage extends StatefulWidget {
  const StepsDemoPage({super.key});

  @override
  State<StepsDemoPage> createState() => _StepsDemoPageState();
}

class _StepsDemoPageState extends State<StepsDemoPage> {
  static const _labels = ['下单', '付款', '发货', '完成'];

  int _current = 2;
  late final WStepFlow _flow = WStepFlow(
    labels: _labels,
    itemBuilder: (context, index, state) => _FlowItem(
      index: index,
      state: state,
    ),
    separatorBuilder: (context, index, completed) => Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: completed ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
    ),
    semanticLabelBuilder: (current, total) => '第 $current 步，共 $total 步',
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final customStyle = WStepStyle(
      completedColor: const Color(0xFF10B981),
      currentColor: scheme.primary,
      upcomingColor: scheme.outline,
      itemSize: 34,
      labelSpacing: 10,
      separatorHeight: 3,
      separatorIndent: 4,
      labelStyle: const TextStyle(fontSize: 11),
      completedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      currentLabelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    );

    return WScaffold(
      title: 'WStep / WStepFlow',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DemoSection(
            title: '默认 WStep（current 从 1 开始）',
            subtitle: 'current 越界 / labels 为空会在 debug 断言',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WStep(labels: _labels, current: _current),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const WText(text: 'current', variant: WTextVariant.caption),
                    Expanded(
                      child: Slider(
                        value: _current.toDouble(),
                        min: 1,
                        max: _labels.length.toDouble(),
                        divisions: _labels.length - 1,
                        label: '$_current',
                        onChanged: (value) => setState(() => _current = value.round()),
                      ),
                    ),
                    WText(text: '$_current', variant: WTextVariant.bodyStrong),
                  ],
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WStepStyle：颜色 / 尺寸 / 间距 / 标签样式',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WStep(
                  labels: _labels,
                  current: _current,
                  style: customStyle,
                ),
                const CodeText(
                  'WStep(\n'
                  '  labels: [...], current: 2,\n'
                  '  style: WStepStyle(\n'
                  '    completedColor: ..., currentColor: ...,\n'
                  '    itemSize: 34, labelSpacing: 10,\n'
                  '    labelStyle: ..., currentLabelStyle: ...,\n'
                  '  ),\n'
                  ')',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'itemBuilder / separatorBuilder / semanticLabelBuilder',
            subtitle: '索引从 1 开始；语义标签默认是英文，可自定义',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WStep(
                  labels: _labels,
                  current: _current,
                  itemBuilder: (context, index, state) => _FlowItem(
                    index: index,
                    state: state,
                  ),
                  separatorBuilder: (context, index, completed) => Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: completed ? const Color(0xFF10B981) : scheme.outlineVariant,
                  ),
                  semanticLabelBuilder: (current, total) => '第 $current 步，共 $total 步',
                ),
                const CodeText(
                  'WStep(\n'
                  '  labels: [...], current: 2,\n'
                  '  itemBuilder: (context, index, state) => ...,\n'
                  '  separatorBuilder: (context, index, completed) => ...,\n'
                  '  semanticLabelBuilder: (current, total) => ...,\n'
                  ')',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'WStepFlow：多处复用同一套流程',
            subtitle: '构造时复制并冻结 labels；copyWith 派生新流程',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _flow.build(current: _current),
                const SizedBox(height: 16),
                _flow.copyWith(labels: const ['下单', '付款', '发货', '完成', '评价']).build(
                    current: _current),
                const CodeText(
                  'final flow = WStepFlow(labels: [...], itemBuilder: ..., ...);\n'
                  'flow.build(current: 2);\n'
                  'flow.copyWith(labels: [...5 步]).build(current: 2);',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({required this.index, required this.state});

  final int index;
  final WStepState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (state) {
      WStepState.completed => const Color(0xFF10B981),
      WStepState.current => scheme.primary,
      WStepState.upcoming => scheme.outline,
    };
    final filled = state != WStepState.upcoming;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: state == WStepState.completed
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$index',
                  style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          '步骤 $index',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: state == WStepState.current ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
