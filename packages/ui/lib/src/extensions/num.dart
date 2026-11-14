import 'package:flutter/material.dart';

/// num 布局扩展：只保留没有 Flutter 原生等价写法的两处糖。
///
/// `SizedBox` / `EdgeInsets` / `BorderRadius` 一律用 Flutter 原生构造，
/// 不再提供 `heightBox` / `widthBox` / `allPadding` 之外的布局别名。
extension WNumLayoutExtension on num {
  /// 创建四边等距的 EdgeInsets
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// 主题描边色（ColorScheme.outline）的 BorderSide；新代码优先用它。
  BorderSide borderSideOf(BuildContext context, {Color? color}) => BorderSide(
    width: toDouble(),
    color: color ?? Theme.of(context).colorScheme.outline,
  );
}
