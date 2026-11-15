import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'language.dart';

/// 把 [WLanguage] 注入子树，页面不必保存全局语言实例。
///
/// 语言切换时，依赖 [of] 的 widget 会重建：
///
/// ```dart
/// final language = WLanguageScope.of(context);
/// language.changeLanguage('en_US');
/// ```
///
/// `WApp` 在 3.2.0 里还不会自动插入本 scope；需要页面内访问时，
/// 在 `WAppOptions.appWrapper` 或测试里手动包一层。
class WLanguageScope extends InheritedNotifier<ValueListenable<String>> {
  WLanguageScope({
    super.key,
    required WLanguage language,
    required super.child,
  }) : _language = language,
       super(notifier: language.languageListenable);

  final WLanguage _language;

  /// 读取最近的 [WLanguage]；没有 scope 时抛 [FlutterError]。
  static WLanguage of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WLanguageScope>();
    if (scope == null) {
      throw FlutterError(
        'WLanguageScope.of() 找不到 WLanguageScope。'
        '请在 WAppOptions.appWrapper 或测试里手动包一层。',
      );
    }
    return scope._language;
  }
}
