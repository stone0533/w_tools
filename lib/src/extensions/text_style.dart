import 'package:flutter/material.dart';
import '../components/common/text.dart';

/// TextStyle 扩展类，提供从 WTextConfig 创建 TextStyle 的方法
extension WTextStyle on TextStyle {
  /// 从 WTextConfig 创建 TextStyle
  ///
  /// @param config 文本样式配置
  /// @return 创建的 TextStyle
  static TextStyle fromConfig({required WTextConfig config}) {
    return config.toTextStyle();
  }
}
