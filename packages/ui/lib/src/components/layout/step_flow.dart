import 'package:flutter/foundation.dart';

import 'step.dart';

/// 一组步骤的不可变定义，可在多个页面复用。
///
/// 页面只需要传 `current`：
///
/// ```dart
/// final steps = WStepFlow(labels: const ['下单', '付款', '完成']);
/// steps.build(current: 2);
/// ```
class WStepFlow {
  WStepFlow({
    required List<String> labels,
    this.style = const WStepStyle(),
    this.itemBuilder,
    this.separatorBuilder,
    this.semanticLabelBuilder,
  }) : labels = List.unmodifiable(labels);

  final List<String> labels;
  final WStepStyle style;
  final WStepItemBuilder? itemBuilder;
  final WStepSeparatorBuilder? separatorBuilder;
  final WStepSemanticLabelBuilder? semanticLabelBuilder;

  WStepFlow copyWith({
    List<String>? labels,
    WStepStyle? style,
    WStepItemBuilder? itemBuilder,
    WStepSeparatorBuilder? separatorBuilder,
    WStepSemanticLabelBuilder? semanticLabelBuilder,
  }) {
    return WStepFlow(
      labels: labels ?? this.labels,
      style: style ?? this.style,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      separatorBuilder: separatorBuilder ?? this.separatorBuilder,
      semanticLabelBuilder: semanticLabelBuilder ?? this.semanticLabelBuilder,
    );
  }

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
      semanticLabelBuilder: semanticLabelBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WStepFlow &&
          listEquals(other.labels, labels) &&
          other.style == style &&
          other.itemBuilder == itemBuilder &&
          other.separatorBuilder == separatorBuilder &&
          other.semanticLabelBuilder == semanticLabelBuilder;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(labels),
    style,
    itemBuilder,
    separatorBuilder,
    semanticLabelBuilder,
  );
}
