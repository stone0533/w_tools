// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_toast/w_tools_toast.dart';
import 'package:w_tools_form/src/components/fields/dropdown.dart';
import 'package:w_tools_form/src/components/fields/multi_dropdown.dart';

/// 批量测试所有 Config 类的 setter 链式调用

void main() {
  // ========= core =========
  group('WAsyncOptions', () {
    test('copyWith 保留 / 清空字段', () {
      final options = WAsyncOptions(
        loading: WAsyncLoading(onStart: () {}),
        onError: (_) {},
      );
      final copy = options.copyWith();
      expect(copy.loading, same(options.loading));
      expect(copy.onError, same(options.onError));

      final cleared = options.copyWith(loading: null, onError: null);
      expect(cleared.loading, isNull);
      expect(cleared.onError, isNull);
    });

    test('WAsyncLoading 合并 0→1 / 1→0', () {
      var starts = 0;
      var ends = 0;
      final loading = WAsyncLoading(onStart: () => starts++, onEnd: () => ends++);
      loading.begin();
      loading.begin();
      expect(starts, 1);
      loading.end();
      expect(ends, 0);
      loading.end();
      expect(ends, 1);
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

  group('WNavBarConfig', () {
    test('decoration / padding 可设置', () {
      const c = WNavBarConfig(
        decoration: BoxDecoration(color: Colors.white),
        padding: EdgeInsets.all(4),
      );
      expect(c.decoration, isNotNull);
      expect(c.padding, const EdgeInsets.all(4));
    });
  });

  group('WTabBarConfig', () {
    test('不可变构造 / copyWith', () {
      const c = WTabBarConfig(
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
  group('WFormBorderConfig', () {
    test('defaultDecoration / errorDecoration 可直接构造，并支持 copyWith', () {
      const c = WFormBorderConfig(
        defaultDecoration: WFormBorderDecoration(color: Colors.grey),
        errorDecoration: WFormBorderDecoration(color: Colors.red),
      );
      expect(c.defaultDecoration, isNotNull);
      expect(c.copyWith(errorStyle: const TextStyle(fontSize: 12)).errorStyle, isNotNull);
    });
  });

  group('WFormBorderDecoration', () {
    test('链式方法返回新对象', () {
      const original = WFormBorderDecoration();
      final colored = original.withColor(Colors.blue);
      expect(colored, isA<WFormBorderDecoration>());
      // withBorderRadius 也是链式
      final rounded = original.withBorderRadius(BorderRadius.circular(12));
      expect(rounded, isA<WFormBorderDecoration>());
    });
  });

  group('WFormDropdownConfig', () {
    test('所有 setter 可调用', () {
      final c = WFormDropdownConfig()
        ..height = 48
        ..hint = const Text('请选择')
        ..icon = const Icon(Icons.arrow_downward)
        ..dropdownColor = Colors.white
        ..style = const TextStyle(fontSize: 16);
      expect(c, isNotNull);
    });
  });

  group('WFormMultiDropdownConfig', () {
    test('所有 setter 可调用', () {
      final c = WFormMultiDropdownConfig()
        ..height = 48
        ..enabled = true
        ..icon = const Icon(Icons.arrow_drop_down)
        ..itemPadding = const EdgeInsets.symmetric(vertical: 8);
      expect(c, isNotNull);
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
