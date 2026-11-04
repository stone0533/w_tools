import 'dart:io';

import 'package:test/test.dart';

void main() {
  for (final lang in ['zh', 'en']) {
    test('$lang app 模板只教真实入口', () {
      final text = File('templates/agents/$lang/app.md').readAsStringSync();
      expect(text, contains('WApp.options'));
      expect(text, isNot(contains('WApp.start()')));
      expect(text, isNot(contains('WApp.appWrapper')));
    });

    test('$lang feedback 模板要求 submit', () {
      final text = File('templates/agents/$lang/feedback.md').readAsStringSync();
      expect(text, contains('feedback submit'));
      expect(text, contains('--local'));
      expect(text, contains('--gh'));
      expect(text, anyOf(contains('包/版本'), contains('package/version')));
      expect(text, isNot(contains('docs/feedback/TEMPLATE.md')));
      expect(text, isNot(contains('直接写台账')));
    });

    test('$lang toast 模板包含初始化', () {
      final text = File('templates/agents/$lang/toast.md').readAsStringSync();
      expect(text, contains('BotToastInit'));
      expect(text, contains('BotToastNavigatorObserver'));
    });
  }
}
