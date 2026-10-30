import 'package:flutter/material.dart';

/// 步骤状态。
enum WStepState { completed, current, upcoming }

/// 步骤项构建器。
///
/// [index] 从 1 开始，等于 [WStep.labels] 中的位置。
/// 返回的 widget 会被放进 Expanded 单元格，不要再返回 Expanded。
typedef WStepItemBuilder = Widget Function(
  BuildContext context,
  int index,
  WStepState state,
);

/// 分割线构建器。
///
/// [index] 从 1 开始，表示分割线位于第 index 步和第 index + 1 步之间。
typedef WStepSeparatorBuilder = Widget Function(
  BuildContext context,
  int index,
  bool completed,
);

/// 步骤条视觉样式。
class WStepStyle {
  const WStepStyle({
    this.completedColor = Colors.blue,
    this.currentColor = Colors.blue,
    this.upcomingColor = Colors.grey,
    this.itemSize = 28,
    this.labelSpacing = 8,
    this.separatorHeight = 2,
    this.separatorIndent = 8,
    this.labelStyle,
    this.completedLabelStyle,
    this.currentLabelStyle,
    this.upcomingLabelStyle,
  });

  final Color completedColor;
  final Color currentColor;
  final Color upcomingColor;
  final double itemSize;
  final double labelSpacing;
  final double separatorHeight;
  final double separatorIndent;
  final TextStyle? labelStyle;
  final TextStyle? completedLabelStyle;
  final TextStyle? currentLabelStyle;
  final TextStyle? upcomingLabelStyle;
}

/// 一组步骤的不可变定义，可在多个页面复用。
///
/// 页面只需要传 [current]：
///
/// ```dart
/// AppSteps.register.build(current: step)
/// ```
class WStepFlow {
  const WStepFlow({
    required this.labels,
    this.style = const WStepStyle(),
    this.itemBuilder,
    this.separatorBuilder,
  });

  final List<String> labels;
  final WStepStyle style;
  final WStepItemBuilder? itemBuilder;
  final WStepSeparatorBuilder? separatorBuilder;

  WStep build({
    Key? key,
    required int current,
  }) {
    return WStep(
      key: key,
      current: current,
      labels: labels,
      style: style,
      itemBuilder: itemBuilder,
      separatorBuilder: separatorBuilder,
    );
  }
}

/// 步骤条。
///
/// [current] 从 1 开始，等于当前步骤在 [labels] 中的位置。
class WStep extends StatelessWidget {
  const WStep({
    super.key,
    required this.current,
    required this.labels,
    this.itemBuilder,
    this.separatorBuilder,
    this.style = const WStepStyle(),
  });

  final int current;
  final List<String> labels;
  final WStepItemBuilder? itemBuilder;
  final WStepSeparatorBuilder? separatorBuilder;
  final WStepStyle style;

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'WStep.labels 不能为空');
    assert(
      current >= 1 && current <= labels.length,
      'WStep.current 必须在 1..${labels.length} 之间',
    );

    final children = <Widget>[];
    for (var index = 1; index <= labels.length; index++) {
      final state = index < current
          ? WStepState.completed
          : index == current
              ? WStepState.current
              : WStepState.upcoming;

      children.add(
        Expanded(
          child: itemBuilder?.call(context, index, state) ?? _buildItem(index, state),
        ),
      );

      if (index < labels.length) {
        final completed = index < current;
        children.add(
          Expanded(
            child: separatorBuilder?.call(context, index, completed) ?? _buildSeparator(completed),
          ),
        );
      }
    }

    return Semantics(
      label: 'Step $current of ${labels.length}',
      child: Row(children: children),
    );
  }

  Widget _buildItem(int index, WStepState state) {
    final color = switch (state) {
      WStepState.completed => style.completedColor,
      WStepState.current => style.currentColor,
      WStepState.upcoming => style.upcomingColor,
    };
    final filled = state != WStepState.upcoming;
    final labelStyle = _labelStyle(state);

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
                  color: Colors.white,
                )
              : Text(
                  '$index',
                  style: TextStyle(
                    color: filled ? Colors.white : color,
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

  TextStyle _labelStyle(WStepState state) {
    final color = switch (state) {
      WStepState.completed => style.completedColor,
      WStepState.current => style.currentColor,
      WStepState.upcoming => style.upcomingColor,
    };
    final base = style.labelStyle ?? const TextStyle(fontSize: 12);
    final stateStyle = switch (state) {
      WStepState.completed => style.completedLabelStyle,
      WStepState.current => style.currentLabelStyle,
      WStepState.upcoming => style.upcomingLabelStyle,
    };
    return base.copyWith(color: color).merge(stateStyle);
  }

  Widget _buildSeparator(bool completed) {
    return Container(
      height: style.separatorHeight,
      margin: EdgeInsets.symmetric(horizontal: style.separatorIndent),
      color: completed ? style.completedColor : style.upcomingColor,
    );
  }
}
