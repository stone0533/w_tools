import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 底部弹窗工具（基于 GetX 的 `Get.bottomSheet`）
class WBottomSheet {
  /// 显示一个底部弹窗；点击遮罩关闭由 Get 的 barrier 负责
  ///
  /// - [content]：弹窗内容（按自身高度布局，不会被强制撑满全屏）
  /// - 返回 `Get.back(result: ...)` 的结果
  /// - 其余参数透传给 `Get.bottomSheet`（背景色 / 遮罩 / 圆角 / 拖拽等）
  static Future<T?> show<T>(
    Widget content, {
    Color? backgroundColor,
    Color? barrierColor,
    bool? isDismissible,
    bool? enableDrag,
    ShapeBorder? shape,
    Clip? clipBehavior,
    bool? ignoreSafeArea,
    double? elevation,
    bool isScrollControlled = true,
  }) {
    return Get.bottomSheet<T>(
      content,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      isDismissible: isDismissible ?? true,
      enableDrag: enableDrag ?? true,
      shape: shape,
      clipBehavior: clipBehavior,
      ignoreSafeArea: ignoreSafeArea,
      elevation: elevation,
      isScrollControlled: isScrollControlled,
    );
  }
}
