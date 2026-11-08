import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  const supported = {'en_US': 'English', 'zh_CN': '简体中文'};

  test('入参 map 被拷贝，外部修改不影响实例', () {
    final map = <String, String>{'en_US': 'English'};
    final config = WLocaleConfig(supportedLanguages: map);
    map['zh_CN'] = '简体中文';

    expect(config.supportedLanguages.containsKey('zh_CN'), isFalse);
    expect(
      () => config.supportedLanguages['zh_CN'] = '简体中文',
      throwsUnsupportedError,
    );
  });

  test('initial / fallback 必须在支持列表内', () {
    expect(
      () => WLocaleConfig(supportedLanguages: supported, initialLanguage: 'fr_FR'),
      throwsArgumentError,
    );
    expect(
      () => WLocaleConfig(supportedLanguages: supported, fallbackLanguage: 'fr_FR'),
      throwsArgumentError,
    );
  });

  test('相同内容 == / hashCode 一致', () {
    final a = WLocaleConfig(supportedLanguages: supported);
    final b = WLocaleConfig(supportedLanguages: supported);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('copyWith 可改 initial / fallback', () {
    final base = WLocaleConfig(supportedLanguages: supported);
    final copy = base.copyWith(
      initialLanguage: 'zh_CN',
      fallbackLanguage: 'en_US',
    );

    expect(copy.initialLanguage, 'zh_CN');
    expect(copy.fallbackLanguage, 'en_US');
    expect(copy.supportedLanguages, supported);
  });
}
