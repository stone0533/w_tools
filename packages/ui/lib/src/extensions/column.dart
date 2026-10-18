import 'package:flutter/widgets.dart';

/// Column 扩展，提供常用的布局辅助方法
extension WColumnExtension on Column {
  /// 将 Column 包装在 IntrinsicHeight 中
  Widget withIntrinsicHeight() {
    return IntrinsicHeight(
      child: this,
    );
  }
}
