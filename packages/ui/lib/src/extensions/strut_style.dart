import 'package:flutter/material.dart';

import '../components/common/text.dart';

/// StrutStyle 扩展（便捷方法）
extension WStrutStyleExtension on StrutStyle {
  /// 创建默认的 StrutStyle
  static StrutStyle withHeight([double height = 1.0]) {
    return StrutStyle(height: height);
  }
}

/// StrutStyle 扩展（组件相关，依赖 WTextConfig）
extension WUiStrutStyleExtension on StrutStyle {
  /// 从 WTextConfig 创建 StrutStyle
  static StrutStyle fromConfig({required WTextConfig config}) {
    return config.toStrutStyle();
  }
}
