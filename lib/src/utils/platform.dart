import 'dart:io';
import 'package:flutter/foundation.dart';

/// 平台类型
enum WPlatformType {
  android, // Android 平台
  ios, // iOS 平台
  web, // Web 平台
  linux, // Linux 平台
  macos, // macOS 平台
  windows, // Windows 平台
  unknown, // 未知平台
}

/// 平台工具类
class WPlatform {
  /// 获取当前平台类型
  static WPlatformType get platformType {
    if (kIsWeb) {
      return WPlatformType.web;
    } else if (Platform.isAndroid) {
      return WPlatformType.android;
    } else if (Platform.isIOS) {
      return WPlatformType.ios;
    } else if (Platform.isLinux) {
      return WPlatformType.linux;
    } else if (Platform.isMacOS) {
      return WPlatformType.macos;
    } else if (Platform.isWindows) {
      return WPlatformType.windows;
    } else {
      return WPlatformType.unknown;
    }
  }

  /// 是否为移动平台
  static bool get isMobile {
    return platformType == WPlatformType.android || platformType == WPlatformType.ios;
  }

  /// 是否为桌面平台
  static bool get isDesktop {
    return platformType == WPlatformType.linux ||
        platformType == WPlatformType.macos ||
        platformType == WPlatformType.windows;
  }

  /// 是否为 Web 平台
  static bool get isWeb {
    return platformType == WPlatformType.web;
  }

  /// 是否为 Android 平台
  static bool get isAndroid {
    return platformType == WPlatformType.android;
  }

  /// 是否为 iOS 平台
  static bool get isIOS {
    return platformType == WPlatformType.ios;
  }

  /// 是否为 Linux 平台
  static bool get isLinux {
    return platformType == WPlatformType.linux;
  }

  /// 是否为 macOS 平台
  static bool get isMacOS {
    return platformType == WPlatformType.macos;
  }

  /// 是否为 Windows 平台
  static bool get isWindows {
    return platformType == WPlatformType.windows;
  }

  /// 获取平台特定的值
  ///
  /// @param android Android 平台的值
  /// @param ios iOS 平台的值
  /// @param web Web 平台的值
  /// @param desktop 桌面平台的值
  /// @param fallback 回退值
  /// @return 平台特定的值
  static T getPlatformValue<T>({
    required T android,
    required T ios,
    required T web,
    required T desktop,
    required T fallback,
  }) {
    switch (platformType) {
      case WPlatformType.android:
        return android;
      case WPlatformType.ios:
        return ios;
      case WPlatformType.web:
        return web;
      case WPlatformType.linux:
      case WPlatformType.macos:
      case WPlatformType.windows:
        return desktop;
      default:
        return fallback;
    }
  }

  /// 执行平台特定的操作
  ///
  /// @param android Android 平台的操作
  /// @param ios iOS 平台的操作
  /// @param web Web 平台的操作
  /// @param desktop 桌面平台的操作
  /// @param fallback 回退操作
  static void executePlatformAction({
    required void Function() android,
    required void Function() ios,
    required void Function() web,
    required void Function() desktop,
    required void Function() fallback,
  }) {
    switch (platformType) {
      case WPlatformType.android:
        android();
        break;
      case WPlatformType.ios:
        ios();
        break;
      case WPlatformType.web:
        web();
        break;
      case WPlatformType.linux:
      case WPlatformType.macos:
      case WPlatformType.windows:
        desktop();
        break;
      default:
        fallback();
        break;
    }
  }
}
