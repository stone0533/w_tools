import 'package:flutter/material.dart';

import 'button_style.dart';

/// 常用按钮样式预设。
///
/// 这些是只读模板；需要微调时用 `copyWith`，不要直接修改嵌套配置。
abstract final class WButtonStyles {
  static final _primary = WButtonStyle.filled(
    backgroundColor: const Color(0xFF3949AB),
    foregroundColor: Colors.white,
  );

  static final _secondary = WButtonStyle.outlined(
    foregroundColor: const Color(0xFF3949AB),
    borderColor: const Color(0xFF3949AB),
  );

  static final _text = WButtonStyle.text(
    foregroundColor: const Color(0xFF3949AB),
  );

  static final _danger = WButtonStyle.filled(
    backgroundColor: const Color(0xFFD32F2F),
    foregroundColor: Colors.white,
  );

  static WButtonStyle get primary => _primary.copy();
  static WButtonStyle get secondary => _secondary.copy();
  static WButtonStyle get text => _text.copy();
  static WButtonStyle get danger => _danger.copy();
}
