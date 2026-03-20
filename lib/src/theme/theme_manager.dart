import 'package:flutter/material.dart';
import 'theme.dart';

/// 主题管理器
class WThemeManager {
  /// 单例实例
  static final WThemeManager _instance = WThemeManager._internal();

  /// 主题模式
  WThemeMode _themeMode = WThemeMode.system;

  /// 亮色主题配置
  WThemeConfig _lightTheme = WThemeConfig.light();

  /// 暗色主题配置
  WThemeConfig _darkTheme = WThemeConfig.dark();

  /// 主题变更监听器
  final List<Function(ThemeData)> _listeners = [];

  /// 构造函数
  factory WThemeManager() {
    return _instance;
  }

  /// 内部构造函数
  WThemeManager._internal();

  /// 获取当前主题
  ThemeData get currentTheme {
    switch (_themeMode) {
      case WThemeMode.light:
        return _lightTheme.toThemeData();
      case WThemeMode.dark:
        return _darkTheme.toThemeData();
      case WThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
            ? _darkTheme.toThemeData()
            : _lightTheme.toThemeData();
    }
  }

  /// 获取当前主题模式
  WThemeMode get themeMode => _themeMode;

  /// 设置主题模式
  Future<void> setThemeMode(WThemeMode mode) async {
    _themeMode = mode;
    _notifyListeners();
  }

  /// 设置亮色主题
  Future<void> setLightTheme(WThemeConfig theme) async {
    _lightTheme = theme;
    if (_themeMode == WThemeMode.light || _themeMode == WThemeMode.system) {
      _notifyListeners();
    }
  }

  /// 设置暗色主题
  Future<void> setDarkTheme(WThemeConfig theme) async {
    _darkTheme = theme;
    if (_themeMode == WThemeMode.dark || _themeMode == WThemeMode.system) {
      _notifyListeners();
    }
  }

  /// 注册主题变更监听器
  void addListener(Function(ThemeData) listener) {
    _listeners.add(listener);
  }

  /// 移除主题变更监听器
  void removeListener(Function(ThemeData) listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(currentTheme);
    }
  }

  /// 清空所有监听器
  void clearListeners() {
    _listeners.clear();
  }
}
