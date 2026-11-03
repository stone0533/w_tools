import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 底部弹窗工具（基于 GetX 的 `Get.bottomSheet` / `Get.back`）
class WBottomSheet {
  /// 显示一个底部弹窗；点击内容区上方的空白区域可关闭
  ///
  /// - [content]：弹窗内容
  /// - 其余参数透传给 `Get.bottomSheet`（背景色 / 遮罩 / 圆角 / 拖拽等）
  static void show(
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
    Get.bottomSheet(
      Column(
        children: [
          // 自建遮罩点击区：占满内容之上的剩余空间，点击即关闭弹窗
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(),
            ),
          ),
          content,
        ],
      ),
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
