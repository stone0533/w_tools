import 'package:flutter/widgets.dart';

enum WStepState { completed, current, upcoming }

/// 步骤项构建器。
///
/// [index] 从 1 开始，等于 [WStep.labels] 中的位置。
/// 返回的 widget 会被放进 Expanded 单元格，不要再返回 Expanded。
typedef WStepItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      WStepState state,
    );

/// 分割线构建器。
///
/// [index] 从 1 开始，表示分割线位于第 index 步和第 index + 1 步之间。
typedef WStepSeparatorBuilder =
    Widget Function(
      BuildContext context,
      int index,
      bool completed,
    );

/// 步骤条语义标签构建器。
typedef WStepSemanticLabelBuilder =
    String Function(
      int current,
      int total,
    );

/// 步骤条视觉样式。
