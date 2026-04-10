import 'package:flutter/material.dart';

/// 应用配置类，提供应用初始化和运行的核心功能
///
/// 这是一个静态类，负责：
/// - 应用初始化
/// - 系统UI设置
/// - 屏幕方向配置
/// - 环境变量加载
/// - 应用运行
class WConfig {
  /// 资源图片路径
  static String assetsImagePath = 'assets/images/';

  /// 支持的语言列表，键为语言代码，值为语言名称
  static Map<String, String> supportedLanguages = {'en_US': 'English'};

  /// 当前语言
  static String currentLanguage = 'en_US';

  static Widget dropdownIcon = const Icon(Icons.keyboard_arrow_down);
  static Widget radioUnselectedIcon = const Icon(Icons.radio_button_off);
  static Widget radioSelectedIcon = const Icon(Icons.radio_button_checked);
  static Widget checkboxUnselectedIcon = const Icon(Icons.check_box_outline_blank);
  static Widget checkboxSelectedIcon = const Icon(Icons.check_box);
  static Widget obscureTextIcon = const Icon(Icons.visibility_off);
  static Widget obscureTextIconOn = const Icon(Icons.visibility);

  /// 默认的 token 存储键名
  static const String tokenKey = 'token';

  /// 默认的 refresh token 存储键名
  static const String refreshTokenKey = 'refresh_token';

  /// 默认的 token 过期时间存储键名
  static const String tokenExpiryKey = 'token_expiry';

  /// 私有构造函数，防止实例化
  WConfig._();
}
