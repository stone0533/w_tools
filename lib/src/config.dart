import 'package:flutter/material.dart';

/// 应用配置类，提供应用初始化和运行的核心功能
///
/// 这是一个单例类，负责：
/// - 应用初始化
/// - 系统UI设置
/// - 屏幕方向配置
/// - 环境变量加载
/// - 应用运行
class WConfig {
  /// 资源图片路径
  late String assetsImagePath;

  /// 支持的语言列表，键为语言代码，值为语言名称
  late Map<String, String> supportedLanguages;

  /// 当前语言
  late String currentLanguage;

  late Widget dropdownIcon;
  late Widget radioUnselectedIcon;
  late Widget radioSelectedIcon;
  late Widget checkboxUnselectedIcon;
  late Widget checkboxSelectedIcon;
  late Widget obscureTextIcon;
  late Widget obscureTextIconOn;

  /// 单例实例
  static final WConfig _instance = WConfig._internal();

  /// 私有构造函数
  WConfig._internal() {
    // 初始化默认值
    assetsImagePath = 'assets/images/';
    currentLanguage = 'en_US';
    supportedLanguages = {'en_US': 'English'};
    dropdownIcon = const Icon(Icons.keyboard_arrow_down);
    radioUnselectedIcon = const Icon(Icons.radio_button_off);
    radioSelectedIcon = const Icon(Icons.radio_button_checked);
    checkboxUnselectedIcon = const Icon(Icons.check_box_outline_blank);
    checkboxSelectedIcon = const Icon(Icons.check_box);
    obscureTextIcon = const Icon(Icons.visibility_off);
    obscureTextIconOn = const Icon(Icons.visibility);
  }

  /// 获取单例实例
  static WConfig get instance => _instance;
}
