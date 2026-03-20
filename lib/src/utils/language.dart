import 'dart:ui';
import 'package:get/get.dart';

import '../config.dart';

/// 语言管理类，用于管理应用语言设置并在语言变更时通知监听者
class WLanguage {
  /// 单例实例
  static final WLanguage _instance = WLanguage._internal();

  /// 工厂构造函数
  factory WLanguage() => _instance;

  /// 内部构造函数
  WLanguage._internal();

  /// 当前语言代码
  late final RxString _currentLanguage = WConfig.instance.currentLanguage.obs;

  /// 获取当前语言代码
  String get currentLanguage => _currentLanguage.value;

  /// 语言变更流，用于监听语言变更
  RxString get languageStream => _currentLanguage;

  /// 支持的语言列表
  final Map<String, String> supportedLanguages = WConfig.instance.supportedLanguages;

  /// 切换语言
  /// [languageCode] 语言代码，如 'zh_CN', 'en_US'
  void changeLanguage(String languageCode) {
    if (supportedLanguages.containsKey(languageCode)) {
      _currentLanguage.value = languageCode;
      // 在这里可以添加实际的语言切换逻辑，如更新GetX的locale
      Get.updateLocale(Locale(languageCode.split('_')[0], languageCode.split('_')[1]));
    }
  }

  /// 监听语言变更
  /// [callback] 语言变更时的回调函数
  void listenLanguageChange(Function(String) callback) {
    _currentLanguage.listen(callback);
  }

  /// 获取当前语言的显示名称
  String getCurrentLanguageName() {
    return supportedLanguages[currentLanguage] ?? currentLanguage;
  }

  /// 获取语言对应的Locale对象
  Locale getCurrentLocale() {
    final parts = currentLanguage.split('_');
    return Locale(parts[0], parts[1]);
  }
}
