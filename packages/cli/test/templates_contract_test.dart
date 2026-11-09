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

    // 反馈怎么提交只在「完成前」留几行，完整流程在 .w_tools/AI_PROMPTS.md（L-1），
    // 避免默认关闭的通道占掉常驻上下文。
    test('$lang closing 模板保留反馈开关与提交入口', () {
      final text = File('templates/agents/$lang/closing.md').readAsStringSync();
      expect(text, contains('feedback.enabled'));
      expect(text, contains('feedback search'));
      expect(text, contains('feedback submit'));
      expect(text, contains('--issue'));
      expect(text, contains('AI_PROMPTS.md'));
      expect(text, contains('L-1'));
      expect(text, isNot(contains('--local')));
    });

    test('$lang toast 模板包含初始化', () {
      final text = File('templates/agents/$lang/toast.md').readAsStringSync();
      expect(text, contains('BotToastInit'));
      expect(text, contains('BotToastNavigatorObserver'));
    });

    test('$lang async 模板说明 state 是 ValueListenable、Obx 不会跟着重建', () {
      final text = File('templates/agents/$lang/async.md').readAsStringSync();
      expect(text, contains('ValueListenable'));
      expect(text, contains('Obx'));
    });

    test('$lang app 模板提醒插件里用 registerService 注册服务', () {
      final text = File('templates/agents/$lang/app.md').readAsStringSync();
      expect(text, contains('registerService'));
      expect(text, contains('Get.putAsync'));
      expect(text, contains('void'));
    });
  }
}
