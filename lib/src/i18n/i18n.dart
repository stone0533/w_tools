import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 国际化资源类
class WTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': {
      'hello': '你好',
    },
    'en_US': {
      'hello': 'Hello',
    },
  };
}

/// 国际化工具类
class WLocale {
  /// 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  /// 默认语言
  static const Locale defaultLocale = Locale('zh', 'CN');

  /// 回退语言
  static const Locale fallbackLocale = Locale('en', 'US');
}
