import 'package:flutter/material.dart';

import 'package:w_tools_core/w_tools_core.dart' as core;
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_app/w_tools_app.dart';
import 'package:w_tools_ui/w_tools_ui.dart' show WAssets;

// 暴露各子包的 Config 类供直接引用
export 'package:w_tools_form/w_tools_form.dart' show WFormDefaults;
export 'package:w_tools_app/w_tools_app.dart' show WAppConfig;
export 'package:w_tools_api/w_tools_api.dart' show WApiConfig;

/// 应用配置类（Umbrella 兼容层）
///
/// 所有配置字段已按职责拆分到各子包（WFormDefaults / WAppConfig / WApiConfig），
/// 此类作为统一入口提供向后兼容的静态访问路径。
/// 新代码建议直接使用对应的子包 Config 类。
class WConfig {
  /// 资产图片路径（代理 `w_tools_ui` 的 `WAssets.imagePath`）
  ///
  /// 资源前缀只认 `WAssets.imagePath` 一个开关：这里是它的转发，
  /// `'logo.png'.assetImagePath` 也会读同一个值。
  static String get assetImagePath => WAssets.imagePath;
  static set assetImagePath(String v) => WAssets.imagePath = v;

  /// token 存储键名
  static String get tokenKey => core.WConfig.tokenKey;
  static set tokenKey(String v) => core.WConfig.tokenKey = v;

  /// refresh token 存储键名
  static String get refreshTokenKey => core.WConfig.refreshTokenKey;
  static set refreshTokenKey(String v) => core.WConfig.refreshTokenKey = v;

  /// token 过期时间存储键名
  static String get tokenExpiryKey => core.WConfig.tokenExpiryKey;
  static set tokenExpiryKey(String v) => core.WConfig.tokenExpiryKey = v;

  // ======== Form ========
  static Widget get dropdownIcon => WFormDefaults.dropdownIcon;
  static set dropdownIcon(Widget v) => WFormDefaults.dropdownIcon = v;

  static Widget get radioUnselectedIcon => WFormDefaults.radioUnselectedIcon;
  static set radioUnselectedIcon(Widget v) => WFormDefaults.radioUnselectedIcon = v;

  static Widget get radioSelectedIcon => WFormDefaults.radioSelectedIcon;
  static set radioSelectedIcon(Widget v) => WFormDefaults.radioSelectedIcon = v;

  static Widget get checkboxUnselectedIcon => WFormDefaults.checkboxUnselectedIcon;
  static set checkboxUnselectedIcon(Widget v) => WFormDefaults.checkboxUnselectedIcon = v;

  static Widget get checkboxSelectedIcon => WFormDefaults.checkboxSelectedIcon;
  static set checkboxSelectedIcon(Widget v) => WFormDefaults.checkboxSelectedIcon = v;

  static Widget get obscureTextIcon => WFormDefaults.obscureTextIcon;
  static set obscureTextIcon(Widget v) => WFormDefaults.obscureTextIcon = v;

  static Widget get obscureTextVisibleIcon => WFormDefaults.obscureTextVisibleIcon;
  static set obscureTextVisibleIcon(Widget v) => WFormDefaults.obscureTextVisibleIcon = v;

  // ======== App ========
  static Map<String, String> get supportedLanguages => WAppConfig.supportedLanguages;
  static set supportedLanguages(Map<String, String> v) => WAppConfig.supportedLanguages = v;

  static String get currentLanguage => WAppConfig.currentLanguage;
  static set currentLanguage(String v) => WAppConfig.currentLanguage = v;

  WConfig._();

  /// 链式配置入口（保持旧 API）
  static WConfigSetup get setup => WConfigSetup._();
}

/// WConfig 链式配置辅助类（保持旧 API）
class WConfigSetup {
  WConfigSetup._();

  set assetImagePath(String value) => WConfig.assetImagePath = value;
  set tokenKey(String value) => WConfig.tokenKey = value;
  set refreshTokenKey(String value) => WConfig.refreshTokenKey = value;
  set tokenExpiryKey(String value) => WConfig.tokenExpiryKey = value;
  set dropdownIcon(Widget value) => WConfig.dropdownIcon = value;
  set radioUnselectedIcon(Widget value) => WConfig.radioUnselectedIcon = value;
  set radioSelectedIcon(Widget value) => WConfig.radioSelectedIcon = value;
  set checkboxUnselectedIcon(Widget value) => WConfig.checkboxUnselectedIcon = value;
  set checkboxSelectedIcon(Widget value) => WConfig.checkboxSelectedIcon = value;
  set obscureTextIcon(Widget value) => WConfig.obscureTextIcon = value;
  set obscureTextVisibleIcon(Widget value) => WConfig.obscureTextVisibleIcon = value;
  set supportedLanguages(Map<String, String> value) => WConfig.supportedLanguages = value;
  set currentLanguage(String value) => WConfig.currentLanguage = value;
}
