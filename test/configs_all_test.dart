import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_core/w_tools_core.dart';
import 'package:w_tools_ui/w_tools_ui.dart';
import 'package:w_tools_form/w_tools_form.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

/// 批量测试所有 Config 类的 setter 链式调用

void main() {
  // ========= core =========
  group('WAsyncConfig', () {
    test('copyWith 传递参数', () {
      final cfg = WAsyncConfig(showLoading: false);
      final copy = cfg.copyWith(showLoading: true);
      expect(copy.showLoading, true);
    });

    test('fallbackOnError / onLoadingStart 可设置', () {
      void onLoadingStart() {}
      final cfg = WAsyncConfig(
        showLoading: true,
        onLoadingStart: onLoadingStart,
        fallbackOnError: (e) {},
      );
      expect(cfg.showLoading, true);
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

  group('WContainerConfig', () {
    test('链式方法返回 this', () {
      final c = WContainerConfig();
      expect(c.center(), same(c));
      expect(c.paddingAll(8), same(c));
      expect(c.borderRadiusAll(12), same(c));
      expect(c.size(100), same(c));
      expect(c.shapeCircle(), same(c));
      expect(c.clipBehaviorAntiAlias(), same(c));
    });

    test('所有 setter 可调用', () {
      final c = WContainerConfig()
        ..width = 100
        ..height = 50
        ..margin = const EdgeInsets.all(4)
        ..padding = const EdgeInsets.all(8)
        ..color = Colors.green
        ..alignment = Alignment.center
        ..clipBehavior = Clip.antiAlias;
      expect(c, isNotNull);
    });
  });

  group('WListViewConfig', () {
    test('setter 可调用', () {
      final c = WListViewConfig()
        ..padding = const EdgeInsets.symmetric(horizontal: 16)
        ..physics = const AlwaysScrollableScrollPhysics();
      expect(c, isNotNull);
    });
  });

  group('WNavBarConfig', () {
    test('setter containerConfig 可调用', () {
      final c = WNavBarConfig()..containerConfig = WContainerConfig();
      expect(c, isNotNull);
    });
  });

  group('WStepConfig', () {
    test('setter length / builder 可调用', () {
      final c = WStepConfig()..length = 3;
      expect(c, isNotNull);
    });

    test('copyWith', () {
      final c = WStepConfig()..length = 2;
      final copy = c.copyWith(length: 5);
      // copyWith 创建新实例，length 应已更新（私有字段无 getter 但 setter 可赋值）
      expect(copy, isA<WStepConfig>());
    });
  });

  group('WTabBarConfig', () {
    test('所有 setter 可调用', () {
      final c = WTabBarConfig()
        ..labelStyle = const TextStyle(fontSize: 16)
        ..indicatorColor = Colors.red
        ..padding = const EdgeInsets.symmetric(horizontal: 16)
        ..indicatorSize = TabBarIndicatorSize.label
        ..tabAlignment = TabAlignment.center;
      expect(c, isNotNull);
    });
  });

  group('WRichTextConfig', () {
    test('链式方法返回 this', () {
      final c = WRichTextConfig();
      expect(c.overflowEllipsis(), same(c));
      expect(c.textAlignCenter(), same(c));
      expect(c.decorationUnderline(), same(c));
      expect(c.familyNotoSansTC(), same(c));
    });

    test('setter 可调用', () {
      final c = WRichTextConfig()
        ..fontSize = 16
        ..color = Colors.purple
        ..fontWeight = FontWeight.bold
        ..maxLines = 3
        ..softWrap = true
        ..letterSpacing = 0.5;
      expect(c, isNotNull);
    });
  });

  // ========= form Config =========
  group('WFormBorderConfig', () {
    test('setter defaultDecoration / errorDecoration 可调用', () {
      final c = WFormBorderConfig()
        ..defaultDecoration = const WFormBorderDecoration(color: Colors.grey)
        ..errorDecoration = const WFormBorderDecoration(color: Colors.red);
      expect(c, isNotNull);
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

  // ========= toast Config =========
  group('WToastConfig', () {
    test('默认字段值', () {
      final c = WToastConfig();
      expect(c.duration, const Duration(seconds: 2));
      expect(c.backgroundColor, Colors.black38);
      expect(c.align, Alignment.center);
      expect(c.animationDuration, const Duration(milliseconds: 200));
    });

    test('所有 setter 可调用', () {
      final c = WToastConfig()
        ..duration = const Duration(seconds: 2)
        ..backgroundColor = Colors.white
        ..align = Alignment.bottomCenter
        ..animationDuration = const Duration(milliseconds: 300);
      // builder / callback 字段返回 Widget 或 void，不能放在级联链中
      c.toastBuilder = (cancel) => const SizedBox.shrink();
      c.onClose = () {};
      c.successBuilder = (msg, cancel) => const SizedBox.shrink();
      c.errorBuilder = (msg, cancel) => const SizedBox.shrink();
      c.warningBuilder = (msg, cancel) => const SizedBox.shrink();
      c.loadingBuilder = (msg, cancel, dismissible) => const SizedBox.shrink();
      expect(c, isNotNull);
    });
  });
}
