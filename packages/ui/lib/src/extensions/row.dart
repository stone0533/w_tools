import 'package:flutter/widgets.dart';

/// Row 扩展，提供常用的布局辅助方法
extension WRowExtension on Row {
  /// 将 Row 包装在 IntrinsicHeight 中
  Widget withIntrinsicHeight() {
    return IntrinsicHeight(
      child: this,
    );
  }
}
