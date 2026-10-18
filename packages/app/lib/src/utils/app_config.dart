/// 应用层配置（语言）
///
/// [currentLanguage] 是语言的**唯一真源**，但本类**不响应式** ——
/// 直接赋值不会触发任何通知；需要响应式切换请用 `WLanguage.changeLanguage`。
class WAppConfig {
  /// 支持的语言列表的存储（请通过 [supportedLanguages] 读写）
  static Map<String, String> _supportedLanguages = {'en_US': 'English'};

  /// 支持的语言列表，键为语言代码，值为语言名称
  ///
  /// **只读**：返回不可变快照，就地修改会抛 `UnsupportedError`；
  /// 需要变更请**整体赋值**（`WAppConfig.supportedLanguages = {...}`）。
  static Map<String, String> get supportedLanguages =>
      Map.unmodifiable(_supportedLanguages);

  /// 整体替换支持的语言列表（内部为拷贝，外部后续修改不影响本类）
  static set supportedLanguages(Map<String, String> value) {
    _supportedLanguages = Map<String, String>.from(value);
  }

  /// 当前语言码（语言的唯一真源）
  static String currentLanguage = 'en_US';

  WAppConfig._();
}
