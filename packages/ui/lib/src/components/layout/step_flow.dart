import 'package:flutter/material.dart';

import 'step.dart';

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
}

/// 保证图标 / 数字在自定义背景色上可读。
