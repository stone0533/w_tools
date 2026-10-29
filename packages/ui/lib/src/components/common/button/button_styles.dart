import 'package:flutter/material.dart';

import 'button_style.dart';

/// 常用按钮样式 fallback 预设。
///
/// 项目应定义自己的 `AppButtons` / `WButtonStyle` 覆盖这些默认值；这里的颜色是最小可用 fallback，
/// 不保证适配所有明暗主题。
abstract final class WButtonStyles {
  static final primary = WButtonStyle.filled(
    backgroundColor: const Color(0xFF3949AB),
    foregroundColor: Colors.white,
  );

  static final secondary = WButtonStyle.outlined(
    foregroundColor: const Color(0xFF3949AB),
    borderColor: const Color(0xFF3949AB),
  );

  static final text = WButtonStyle.text(
    foregroundColor: const Color(0xFF3949AB),
  );

  static final danger = WButtonStyle.filled(
    backgroundColor: const Color(0xFFD32F2F),
    foregroundColor: Colors.white,
  );
}
