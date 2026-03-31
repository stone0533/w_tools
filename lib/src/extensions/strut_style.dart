import 'package:flutter/material.dart';
import '../components/common/text.dart';

/// StrutStyle 扩展类，提供从 WTextConfig 创建 StrutStyle 的方法
extension WStrutStyle on StrutStyle {
  /// 从 WTextConfig 创建 StrutStyle
  ///
  /// @param config 文本样式配置
  /// @return 创建的 StrutStyle
  static StrutStyle fromConfig({required WTextConfig config}) {
    return config.toStrutStyle();
  }
}
