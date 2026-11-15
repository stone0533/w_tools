import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'language.dart';

/// 把 [WLanguage] 注入子树；`WApp` 会在 `run()` 时自动放在 `GetMaterialApp` 外。
///
/// 页面里用 [of] 读取当前语言；语言切换时依赖者会重建：
///
/// ```dart
/// final language = WLanguageScope.of(context);
/// language.changeLanguage('en_US');
/// ```
///
/// 测试或非 GetX 应用壳可以手动包一层；[maybeOf] 在未注入时返回 null。
class WLanguageScope extends InheritedNotifier<ValueListenable<String>> {
  WLanguageScope({super.key, required this.language, required super.child})
    : super(notifier: language.languageListenable);

  /// 当前子树的语言实例。
  final WLanguage language;

  /// 读取最近的 scope；没有时返回 null。
  static WLanguageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WLanguageScope>();

  /// 读取最近的 [WLanguage]；没有 scope 时抛 [FlutterError]。
  static WLanguage of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError(
        'WLanguageScope.of() 找不到 WLanguageScope。'
        '用 WApp 启动时会自动注入；测试或非 GetX 壳里请手动包一层。',
      );
    }
    return scope.language;
  }
}
