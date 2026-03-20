import 'package:flutter/material.dart';

/// 主题模式
enum WThemeMode {
  light, // 亮色主题
  dark, // 暗色主题
  system, // 跟随系统
}

/// 主题配置
class WThemeConfig {
  /// 主题颜色
  final Color primaryColor;

  /// 次要颜色
  final Color secondaryColor;

  /// 背景颜色
  final Color backgroundColor;

  /// 卡片颜色
  final Color cardColor;

  /// 文本颜色
  final Color textColor;

  /// 次要文本颜色
  final Color secondaryTextColor;

  /// 边框颜色
  final Color borderColor;

  /// 错误颜色
  final Color errorColor;

  /// 成功颜色
  final Color successColor;

  /// 警告颜色
  final Color warningColor;

  /// 构造函数
  const WThemeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
  });

  /// 默认亮色主题
  factory WThemeConfig.light() {
    return const WThemeConfig(
      primaryColor: Colors.blue,
      secondaryColor: Colors.green,
      backgroundColor: Colors.white,
      cardColor: Colors.white,
      textColor: Colors.black,
      secondaryTextColor: Colors.grey,
      borderColor: Colors.grey,
      errorColor: Colors.red,
      successColor: Colors.green,
      warningColor: Colors.yellow,
    );
  }

  /// 默认暗色主题
  factory WThemeConfig.dark() {
    return const WThemeConfig(
      primaryColor: Colors.blueAccent,
      secondaryColor: Colors.greenAccent,
      backgroundColor: Colors.grey,
      cardColor: Colors.grey,
      textColor: Colors.white,
      secondaryTextColor: Colors.grey,
      borderColor: Colors.grey,
      errorColor: Colors.redAccent,
      successColor: Colors.greenAccent,
      warningColor: Colors.yellowAccent,
    );
  }

  /// 转换为 ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        error: errorColor,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
      ),
    );
  }
}
