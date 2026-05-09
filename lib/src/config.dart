import 'package:flutter/material.dart';
import 'api/clients/http_config.dart';

/// 应用配置类，提供应用初始化和运行的核心功能
///
/// 这是一个静态类，负责：
/// - 应用初始化
/// - 系统UI设置
/// - 屏幕方向配置
/// - 环境变量加载
/// - 应用运行
class WConfig {
  /// 资产图片路径
  static String assetImagePath = 'assets/images/';

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
  static  String? _tokenKey;

  /// 默认的 refresh token 存储键名
  static  String? _refreshTokenKey;

  /// 默认的 token 过期时间存储键名
  static  String? _tokenExpiryKey;

  /// 默认 HTTP 配置（全局共享）
  static HttpConfig httpConfig = HttpConfig();

  /// 获取 token 存储键名
  static String get tokenKey => _tokenKey??'token';

  /// 设置 token 存储键名
  /// 
  /// @param value 要设置的 token 存储键名
  /// @throws StateError 如果已经设置过 token 存储键名
  static set tokenKey(String value) {
    if (_tokenKey != null) {
      throw StateError('tokenKey 已经设置过，不能重复设置');
    }
    _tokenKey = value;
  }

  /// 获取 refresh token 存储键名
  static String get refreshTokenKey => _refreshTokenKey??'refresh_token';

  /// 设置 refresh token 存储键名
  /// 
  /// @param value 要设置的 refresh token 存储键名
  /// @throws StateError 如果已经设置过 refresh token 存储键名
  static set refreshTokenKey(String value) {
    if (_refreshTokenKey != null) {
      throw StateError('refreshTokenKey 已经设置过，不能重复设置');
    }
    _refreshTokenKey = value;
  }

  /// 获取 token 过期时间存储键名
  static String get tokenExpiryKey => _tokenExpiryKey??'token_expiry';

  /// 设置 token 过期时间存储键名
  /// 
  /// @param value 要设置的 token 过期时间存储键名
  /// @throws StateError 如果已经设置过 token 过期时间存储键名
  static set tokenExpiryKey(String value) {
    if (_tokenExpiryKey != null) {
      throw StateError('tokenExpiryKey 已经设置过，不能重复设置');
    }
    _tokenExpiryKey = value;
  }

  /// 私有构造函数，防止实例化
  WConfig._();

  /// 配置方法，支持链式调用
  ///
  /// @example
  /// ```dart
  /// WConfig.setup
  ///   ..dropdownIcon = const Icon(Icons.arrow_downward)
  ///   ..radioUnselectedIcon = const Icon(Icons.radio_button_unchecked)
  ///   ..radioSelectedIcon = const Icon(Icons.radio_button_checked);
  /// ```
  static WConfigSetup get setup => WConfigSetup._();
}

/// WConfig 配置辅助类，用于支持链式配置
class WConfigSetup {
  /// 私有构造函数
  WConfigSetup._();

  /// 设置下拉图标
  set dropdownIcon(Widget value) => WConfig.dropdownIcon = value;

  /// 设置单选框未选中图标
  set radioUnselectedIcon(Widget value) => WConfig.radioUnselectedIcon = value;

  /// 设置单选框选中图标
  set radioSelectedIcon(Widget value) => WConfig.radioSelectedIcon = value;

  /// 设置复选框未选中图标
  set checkboxUnselectedIcon(Widget value) => WConfig.checkboxUnselectedIcon = value;

  /// 设置复选框选中图标
  set checkboxSelectedIcon(Widget value) => WConfig.checkboxSelectedIcon = value;

  /// 设置密码隐藏图标
  set obscureTextIcon(Widget value) => WConfig.obscureTextIcon = value;

  /// 设置密码显示图标
  set obscureTextIconOn(Widget value) => WConfig.obscureTextIconOn = value;

  /// 设置资源图片路径
  set assetImagePath(String value) => WConfig.assetImagePath = value;

  /// 设置支持的语言列表
  set supportedLanguages(Map<String, String> value) => WConfig.supportedLanguages = value;

  /// 设置当前语言
  set currentLanguage(String value) => WConfig.currentLanguage = value;

  /// 设置 token 存储键名
  set tokenKey(String value) => WConfig.tokenKey = value;

  /// 设置 refresh token 存储键名
  set refreshTokenKey(String value) => WConfig.refreshTokenKey = value;

  /// 设置 token 过期时间存储键名
  set tokenExpiryKey(String value) => WConfig.tokenExpiryKey = value;

  /// 设置默认 HTTP 配置
  set httpConfig(HttpConfig value) => WConfig.httpConfig = value;
}
