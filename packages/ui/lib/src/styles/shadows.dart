import 'package:flutter/material.dart';

/// 中性的阴影预设；品牌色阴影由项目自定义。
abstract final class WShadows {
  static const none = <BoxShadow>[];

  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const elevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}
