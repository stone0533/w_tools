import 'package:flutter/material.dart';

import 'step_flow.dart';
import 'step_style.dart';
import 'step_types.dart';

export 'step_flow.dart';
export 'step_style.dart';
export 'step_types.dart';

Color _onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

/// 步骤条。
///
/// [current] 从 1 开始，等于当前步骤在 [labels] 中的位置。
///
/// 直接传 [labels] 时由调用方保证列表不再变化；需要复用流程请使用
/// [WStepFlow]，它会在构造时复制并冻结 labels。
class WStep extends StatelessWidget {
  const WStep({
    super.key,
    required this.current,
    required this.labels,
    this.itemBuilder,
    this.separatorBuilder,
    this.semanticLabelBuilder,
    this.style = const WStepStyle(),
  });

  final int current;
  final List<String> labels;
  final WStepItemBuilder? itemBuilder;
  final WStepSeparatorBuilder? separatorBuilder;
  final WStepSemanticLabelBuilder? semanticLabelBuilder;
  final WStepStyle style;

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'WStep.labels 不能为空');
    assert(
      current >= 1 && current <= labels.length,
      'WStep.current 必须在 1..${labels.length} 之间',
    );
    assert(style.itemSize > 0, 'WStepStyle.itemSize 必须大于 0');
    assert(style.labelSpacing >= 0, 'WStepStyle.labelSpacing 不能为负');
    assert(style.separatorHeight >= 0, 'WStepStyle.separatorHeight 不能为负');
    assert(style.separatorIndent >= 0, 'WStepStyle.separatorIndent 不能为负');

    final scheme = Theme.of(context).colorScheme;
    final colors = style.resolve(scheme);
    final completedColor = colors.completed;
    final currentColor = colors.current;
    final upcomingColor = colors.upcoming;
    final children = <Widget>[];
    for (var index = 1; index <= labels.length; index++) {
      final state = index < current
          ? WStepState.completed
          : index == current
          ? WStepState.current
          : WStepState.upcoming;

      children.add(
        Expanded(
          child:
              itemBuilder?.call(context, index, state) ??
              _buildItem(index, state, completedColor, currentColor, upcomingColor),
        ),
      );

      if (index < labels.length) {
        final completed = index < current;
        children.add(
          Expanded(
            child:
                separatorBuilder?.call(context, index, completed) ??
                _buildSeparator(completed, completedColor, upcomingColor),
          ),
        );
      }
    }

    return Semantics(
      label:
          semanticLabelBuilder?.call(current, labels.length) ?? 'Step $current of ${labels.length}',
      child: Row(children: children),
    );
  }

  Widget _buildItem(
    int index,
    WStepState state,
    Color completedColor,
    Color currentColor,
    Color upcomingColor,
  ) {
    final color = switch (state) {
      WStepState.completed => completedColor,
      WStepState.current => currentColor,
      WStepState.upcoming => upcomingColor,
    };
    final filled = state != WStepState.upcoming;
    final labelStyle = _labelStyle(state, completedColor, currentColor, upcomingColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: style.itemSize,
          height: style.itemSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(color: color),
          ),
          child: state == WStepState.completed
              ? Icon(
                  Icons.check,
                  size: style.itemSize * 0.55,
                  color: _onColor(completedColor),
                )
              : Text(
                  '$index',
                  style: TextStyle(
                    color: filled ? _onColor(color) : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        SizedBox(height: style.labelSpacing),
        Text(
          labels[index - 1],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: labelStyle,
        ),
      ],
    );
  }

  TextStyle _labelStyle(
    WStepState state,
    Color completedColor,
    Color currentColor,
    Color upcomingColor,
  ) {
    final color = switch (state) {
      WStepState.completed => completedColor,
      WStepState.current => currentColor,
      WStepState.upcoming => upcomingColor,
    };
    final base = style.labelStyle ?? const TextStyle(fontSize: 12);
    final stateStyle = switch (state) {
      WStepState.completed => style.completedLabelStyle,
      WStepState.current => style.currentLabelStyle,
      WStepState.upcoming => style.upcomingLabelStyle,
    };
    return base.copyWith(color: color).merge(stateStyle);
  }

  Widget _buildSeparator(bool completed, Color completedColor, Color upcomingColor) {
    return Container(
      height: style.separatorHeight,
      margin: EdgeInsets.symmetric(horizontal: style.separatorIndent),
      color: completed ? completedColor : upcomingColor,
    );
  }
}
