import 'package:flutter/material.dart';

import '../components/common/text.dart';

/// TextStyle 扩展（便捷方法）
extension WTextStyleExtension on TextStyle {
  /// 创建加粗的 TextStyle
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// 创建设置颜色后的 TextStyle
  TextStyle withColor(Color color) => copyWith(color: color);

  /// 创建设置字号后的 TextStyle
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

/// TextStyle 扩展（组件相关，依赖 WTextConfig）
extension WUiTextStyleExtension on TextStyle {
  /// 从 WTextConfig 创建 TextStyle
  static TextStyle fromConfig({required WTextConfig config}) {
    return config.toTextStyle();
  }
}
