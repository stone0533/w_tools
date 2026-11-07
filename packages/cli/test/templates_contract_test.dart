import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('CLI-008 模板不再教旧子命令入口', () {
    final legacy = RegExp(r'w_tools_cli:(?:init|doctor|context|list|explain|feedback)\b');
    for (final file in Directory('templates').listSync(recursive: true).whereType<File>()) {
      expect(
        legacy.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} 仍在教 `w_tools_cli:<cmd>`，应改为 `w_tools_cli:w_tools <cmd>`',
      );
    }
  });

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
      expect(text, contains('issue: true'));
      expect(text, contains('--issue'));
      expect(text, anyOf(contains('包/版本'), contains('package/version')));
      expect(text, isNot(contains('docs/feedback/TEMPLATE.md')));
      expect(text, isNot(contains('--local')));
    });

    test('$lang toast 模板包含初始化', () {
      final text = File('templates/agents/$lang/toast.md').readAsStringSync();
      expect(text, contains('BotToastInit'));
      expect(text, contains('BotToastNavigatorObserver'));
    });
  }
}
