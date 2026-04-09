import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools/src/utils/toast.dart';

// 清理函数，在每个测试结束后调用
void cleanUp() {
  try {
    BotToast.cleanAll();
  } catch (e) {
    // 忽略 BotToast 未初始化的错误
  }
  // 清理全局加载状态
  // 注意：现在每个 WToastConfig 实例有自己的加载状态
}

void main() {
  testWidgets('WToast integration test', (WidgetTester tester) async {
    // 测试开始前清理
    cleanUp();
    // 测试结束后清理
    addTearDown(cleanUp);
    // Build a simple app with a button to trigger toasts
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showSuccess('Test success');
                  },
                  child: const Text('Show Success'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showError('Test error');
                  },
                  child: const Text('Show Error'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showWarning('Test warning');
                  },
                  child: const Text('Show Warning'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showLoading();
                  },
                  child: const Text('Show Loading'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.hideLoading();
                  },
                  child: const Text('Hide Loading'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Test showSuccess
    await tester.tap(find.text('Show Success'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showError
    await tester.tap(find.text('Show Error'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showWarning
    await tester.tap(find.text('Show Warning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showLoading and hideLoading
    await tester.tap(find.text('Show Loading'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Hide Loading'));
    await tester.pump(const Duration(milliseconds: 500));

    // Clean up toasts
    BotToast.cleanAll();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });

  testWidgets('WToastConfig integration test', (WidgetTester tester) async {
    // 测试开始前清理
    cleanUp();
    // 测试结束后清理
    addTearDown(cleanUp);
    // Build a simple app with a button to trigger config-based toasts
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showSuccess('Config success');
                  },
                  child: const Text('Show Config Success'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showError('Config error');
                  },
                  child: const Text('Show Config Error'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showWarning('Config warning');
                  },
                  child: const Text('Show Config Warning'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.showLoading();
                  },
                  child: const Text('Show Config Loading'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final config = WToastConfig();
                    config.hideLoading();
                  },
                  child: const Text('Hide Config Loading'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Test showSuccess via config
    await tester.tap(find.text('Show Config Success'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showError via config
    await tester.tap(find.text('Show Config Error'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showWarning via config
    await tester.tap(find.text('Show Config Warning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test showLoading and hideLoading via config
    await tester.tap(find.text('Show Config Loading'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Hide Config Loading'));
    await tester.pump(const Duration(milliseconds: 500));

    // Clean up toasts
    BotToast.cleanAll();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}
