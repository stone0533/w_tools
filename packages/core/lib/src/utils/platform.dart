import 'package:flutter/foundation.dart';

/// 平台类型
enum WPlatformType {
  /// Android
  android,

  /// iOS
  ios,

  /// Web
  web,

  /// Linux
  linux,

  /// macOS
  macos,

  /// Windows
  windows,

  /// Fuchsia
  fuchsia,
}

/// 平台工具类
///
/// 基于 `kIsWeb` 与 `defaultTargetPlatform` 判断当前平台。
class WPlatform {
  // 纯静态工具类，禁止实例化
  WPlatform._();

  /// 当前平台类型
  static WPlatformType get platformType {
    if (kIsWeb) {
      return WPlatformType.web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return WPlatformType.android;
      case TargetPlatform.iOS:
        return WPlatformType.ios;
      case TargetPlatform.linux:
        return WPlatformType.linux;
      case TargetPlatform.macOS:
        return WPlatformType.macos;
      case TargetPlatform.windows:
        return WPlatformType.windows;
      case TargetPlatform.fuchsia:
        return WPlatformType.fuchsia;
    }
  }

  /// 是否为移动平台（Android / iOS）
  static bool get isMobile {
    return platformType == WPlatformType.android || platformType == WPlatformType.ios;
  }

  /// 是否为桌面平台（Linux / macOS / Windows）
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

  /// 获取当前平台对应的值
  ///
  /// - [android] / [ios] / [web]：对应平台的返回值
  /// - [desktop]：Linux / macOS / Windows 共用的返回值
  /// - [fallback]：Fuchsia 等其他平台的返回值
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

  /// 执行当前平台对应的操作
  ///
  /// 参数含义与 [getPlatformValue] 一致。
  static void runForPlatform({
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
