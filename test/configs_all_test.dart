// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

/// 批量测试所有 Config 类的 setter 链式调用
///
/// 隐藏的 `*Config`（如 `WFormDropdownConfig`）是包内实现，白盒测试放在
/// `packages/form/test/internal/`；本文件只使用 barrel 导出的类型。

void main() {
  // ========= core =========
  group('WAsyncOptions', () {
    test('withoutActivity 只清空 activity', () {
      final options = WAsyncOptions(
        activity: WAsyncActivity(onStart: () {}),
        onError: (_) {},
      );
      final copy = options.withoutActivity();
      expect(copy.activity, isNull);
      expect(copy.onError, same(options.onError));
    });

    test('WAsyncActivity 合并 0→1 / 1→0', () async {
      var starts = 0;
      var ends = 0;
      final activity = WAsyncActivity(onStart: () => starts++, onEnd: () => ends++);
      final options = WAsyncOptions(activity: activity);
      await Future.wait([
        WAsync.run<void>(() async {}, options: options),
        WAsync.run<void>(() async {}, options: options),
      ]);
      expect(starts, 1);
      expect(ends, 1);
      expect(activity.isLoading, isFalse);
    });
  });

  group('WCancellationException', () {
    test('构造函数参数名为 reason', () {
      final e = WCancellationException('timeout');
      expect(e.reason, 'timeout');
    });
  });

  // ========= ui Config =========
  group('WAppBarStyle', () {
    test('字段可读', () {
      const style = WAppBarStyle(
        backgroundColor: Colors.blue,
        height: 56,
        titleSpacing: 8,
      );
      expect(style.backgroundColor, Colors.blue);
      expect(style.height, 56);
      expect(style.titleSpacing, 8);
    });
  });

  group('WNavBarStyle', () {
    test('decoration / padding 可设置', () {
      const c = WNavBarStyle(
        decoration: BoxDecoration(color: Colors.white),
        padding: EdgeInsets.all(4),
      );
      expect(c.decoration, isNotNull);
      expect(c.padding, const EdgeInsets.all(4));
    });
  });

  group('WTabBarStyle', () {
    test('不可变构造 / copyWith', () {
      const c = WTabBarStyle(
        labelStyle: TextStyle(fontSize: 16),
        indicatorColor: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 16),
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.center,
      );
      expect(c.copyWith(indicatorColor: Colors.blue).indicatorColor, Colors.blue);
    });
  });

  // ========= form Config =========
  group('WFormBorderStyle', () {
    test('defaultDecoration / errorDecoration 可直接构造，并支持 copyWith', () {
      const c = WFormBorderStyle(
        defaultDecoration: BoxDecoration(color: Colors.grey),
        errorDecoration: BoxDecoration(color: Colors.red),
      );
      expect(c.defaultDecoration, isNotNull);
      expect(c.copyWith(errorStyle: const TextStyle(fontSize: 12)).errorStyle, isNotNull);
    });
  });

  // ========= toast Style =========
  group('WToastStyle', () {
    test('默认字段值', () {
      const s = WToastStyle.defaults;
      expect(s.duration, const Duration(seconds: 2));
      // 默认 null：遮罩运行时用中性半透明黑，文本气泡取主题反色
      expect(s.backgroundColor, isNull);
      expect(s.align, Alignment.center);
      expect(s.animationDuration, const Duration(milliseconds: 200));
    });

    test('copyWith 保留字段并支持清空', () {
      final s = WToastStyle.defaults.copyWith(
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.white,
      );
      expect(s.duration, const Duration(seconds: 3));
      expect(s.backgroundColor, Colors.white);

      final cleared = s.copyWith(backgroundColor: null);
      expect(cleared.backgroundColor, isNull);
      // 原对象不受影响
      expect(s.backgroundColor, Colors.white);
    });
  });
}
