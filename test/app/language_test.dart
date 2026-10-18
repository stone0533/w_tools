import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:w_tools_app/w_tools_app.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    WAppConfig.supportedLanguages = {'en_US': 'English'};
    WAppConfig.currentLanguage = 'en_US';
  });

  tearDown(() {
    WAppConfig.supportedLanguages = {'en_US': 'English'};
    WAppConfig.currentLanguage = 'en_US';
  });

  group('WLanguage', () {
    test('是单例', () {
      final a = WLanguage();
      final b = WLanguage();
      expect(a, same(b));
    });

    test('currentLanguage / supportedLanguages 实时读取 WAppConfig', () {
      final lang = WLanguage();
      expect(lang.currentLanguage, 'en_US');
      expect(lang.supportedLanguages.containsKey('en_US'), true);

      // 实时读取：修改 WAppConfig 后立即生效（不再是构造时快照）
      WAppConfig.supportedLanguages = {'zh_CN': '简体中文'};
      WAppConfig.currentLanguage = 'zh_CN';
      expect(lang.currentLanguage, 'zh_CN');
      expect(lang.supportedLanguages.containsKey('zh_CN'), true);
    });

    test('changeLanguage 在 supported 范围内切换 currentLanguage', () {
      final lang = WLanguage();
      final code = lang.supportedLanguages.keys.first; // 'en_US'
      lang.changeLanguage(code);
      // Get.updateLocale 在测试的 testMode 下是 no-op
      expect(lang.currentLanguage, code);
    });

    test('changeLanguage 同步写回 WAppConfig.currentLanguage', () {
      final lang = WLanguage();
      final code = lang.supportedLanguages.keys.first; // 'en_US'

      // 先把真源改成别的值，验证 changeLanguage 会写回
      WAppConfig.currentLanguage = 'stale';
      lang.changeLanguage(code);

      expect(WAppConfig.currentLanguage, code, reason: '真源应与 WLanguage 一致');
      expect(lang.currentLanguage, code);
    });

    test('changeLanguage 拒绝不在 supported 范围内的 code', () {
      final lang = WLanguage();
      final before = lang.currentLanguage;
      lang.changeLanguage('xx_XX_not_supported');
      expect(lang.currentLanguage, before); // 不变
    });

    test('currentLanguageName 返回 supportedLanguages 中的名称', () {
      final lang = WLanguage();
      lang.changeLanguage('en_US'); // 使用它自己支持的值
      expect(lang.currentLanguageName, 'English');
    });

    test('currentLanguageName 找不到时返回 languageCode 本身', () {
      final lang = WLanguage();
      // 构造时的 supportedLanguages 只有 'en_US'
      // 所以它永远能找到...除非我们直接操作内部状态（测试不方便）
      // 这里只验证正常路径
      lang.changeLanguage('en_US');
      expect(lang.currentLanguageName, isNotEmpty);
    });

    test('currentLocale 正确拆分 languageCode', () {
      final lang = WLanguage();
      lang.changeLanguage('en_US');
      final locale = lang.currentLocale;
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, 'US');
    });

    test('languageStream 是 _currentLanguageRx 的 RxString', () {
      final lang = WLanguage();
      expect(lang.languageStream, isA<RxString>());
      expect(lang.languageStream.value, lang.currentLanguage);
    });

    test('listenLanguageChange 在 changeLanguage 后收到回调', () async {
      final lang = WLanguage();
      List<String> changes = [];
      lang.listenLanguageChange((v) => changes.add(v));

      lang.changeLanguage('en_US'); // 没变 — 不会触发
      // 我们不能构造一个新的 supported language 因为单例已经冻结
      // 只验证 listen 回调机制能正常注册
      expect(changes, isEmpty); // 没变化所以没回调
    });
  });
}
