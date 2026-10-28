import 'package:flutter/material.dart';

import '../../layout/container.dart';
import 'button_style.dart';
import '../text.dart';

/// 常用按钮样式预设。
///
/// 这些是只读模板；需要微调时用 `copyWith`，不要直接修改嵌套的
/// `WContainerConfig` / `WTextConfig`。
abstract final class WButtonStyles {
  static final _primary = WButtonStyle(
    container: WContainerConfig()
      ..padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
      ..color = const Color(0xFF3949AB)
      ..borderRadius = BorderRadius.circular(8),
    textStyle: WTextConfig()
      ..color = Colors.white
      ..fontSize = 14
      ..fontWeight = FontWeight.w600,
  );

  static final _secondary = WButtonStyle(
    container: WContainerConfig()
      ..padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
      ..color = Colors.transparent
      ..border = Border.all(color: const Color(0xFF3949AB))
      ..borderRadius = BorderRadius.circular(8),
    textStyle: WTextConfig()
      ..color = const Color(0xFF3949AB)
      ..fontSize = 14
      ..fontWeight = FontWeight.w600,
  );

  static final _text = WButtonStyle(
    container: WContainerConfig()
      ..padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
      ..color = Colors.transparent,
    textStyle: WTextConfig()
      ..color = const Color(0xFF3949AB)
      ..fontSize = 14
      ..fontWeight = FontWeight.w500,
  );

  static final _danger = WButtonStyle(
    container: WContainerConfig()
      ..padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
      ..color = const Color(0xFFD32F2F)
      ..borderRadius = BorderRadius.circular(8),
    textStyle: WTextConfig()
      ..color = Colors.white
      ..fontSize = 14
      ..fontWeight = FontWeight.w600,
  );
  static WButtonStyle get primary => _primary.copy();
  static WButtonStyle get secondary => _secondary.copy();
  static WButtonStyle get text => _text.copy();
  static WButtonStyle get danger => _danger.copy();
}
