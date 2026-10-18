import 'dart:async';
import 'dart:ui' show Locale;
import 'package:get/get.dart';

import 'app_config.dart';

/// 语言管理类，用于管理应用语言设置并在语言变更时通知监听者
class WLanguage {
  static final WLanguage _instance = WLanguage._internal();

  /// 获取语言管理单例
  factory WLanguage() => _instance;

  WLanguage._internal();

  /// 语言变更通知通道（真源见 [WAppConfig.currentLanguage]）
  late final RxString _currentLanguageRx = WAppConfig.currentLanguage.obs;

  /// 当前语言码（真源为 [WAppConfig.currentLanguage]）
  String get currentLanguage => WAppConfig.currentLanguage;

  /// 语言变更的响应式流（[changeLanguage] 成功后更新，供 UI 订阅）
  RxString get languageStream => _currentLanguageRx;

  /// 支持的语言列表（实时读取 [WAppConfig]，运行期新增语言立即可用）
  Map<String, String> get supportedLanguages => WAppConfig.supportedLanguages;

  /// 当前语言的显示名称（未收录时回退为语言代码本身）
  String get currentLanguageName =>
      supportedLanguages[currentLanguage] ?? currentLanguage;

  /// 当前语言对应的 [Locale]
  Locale get currentLocale => _toLocale(currentLanguage);

  /// 切换语言
  ///
  /// 会同步写回 [WAppConfig.currentLanguage]（唯一真源），
  /// 并通过 [languageStream] 通知订阅者。
  /// [languageCode] 语言代码，如 'zh_CN', 'en_US'、'en'；未收录时忽略
  void changeLanguage(String languageCode) {
    if (supportedLanguages.containsKey(languageCode)) {
      WAppConfig.currentLanguage = languageCode;
      _currentLanguageRx.value = languageCode;
      Get.updateLocale(_toLocale(languageCode));
    }
  }

  /// 监听语言变更
  ///
  /// 返回 [StreamSubscription]，调用方可在合适时机取消订阅以避免内存泄漏。
  /// [callback] 语言变更时的回调函数
  StreamSubscription<String> listenLanguageChange(
    void Function(String) callback,
  ) {
    return _currentLanguageRx.listen(callback);
  }

  /// 将语言代码安全转换为 Locale（无国家/地区码时仅取 languageCode）
  Locale _toLocale(String languageCode) {
    final parts = languageCode.split('_');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }
}
