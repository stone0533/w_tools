import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  setUp(() {
    // reset
    WAppConfig.supportedLanguages = {'en_US': 'English'};
    WAppConfig.currentLanguage = 'en_US';
  });

  group('WAppConfig', () {
    test('默认值正确', () {
      expect(WAppConfig.currentLanguage, 'en_US');
      expect(WAppConfig.supportedLanguages, {'en_US': 'English'});
    });

    test('可以修改 currentLanguage', () {
      WAppConfig.currentLanguage = 'zh_CN';
      expect(WAppConfig.currentLanguage, 'zh_CN');
    });

    test('可以添加新的 supportedLanguages', () {
      WAppConfig.supportedLanguages = {
        'en_US': 'English',
        'zh_CN': '简体中文',
        'ja_JP': '日本語',
      };
      expect(WAppConfig.supportedLanguages.length, 3);
      expect(WAppConfig.supportedLanguages['zh_CN'], '简体中文');
    });

    test('可以整体替换 supportedLanguages', () {
      WAppConfig.supportedLanguages = {'zh_CN': '简体中文'};
      expect(WAppConfig.supportedLanguages, {'zh_CN': '简体中文'});
    });

    test('supportedLanguages 为只读快照，就地修改抛 UnsupportedError', () {
      expect(
        () => WAppConfig.supportedLanguages['zh_CN'] = '简体中文',
        throwsUnsupportedError,
      );
    });

    test('setter 会拷贝入参，外部后续修改不影响内部', () {
      final source = <String, String>{'en_US': 'English'};
      WAppConfig.supportedLanguages = source;

      source['zh_CN'] = '简体中文'; // 修改外部 map

      expect(WAppConfig.supportedLanguages.containsKey('zh_CN'), isFalse);
    });
  });
}
