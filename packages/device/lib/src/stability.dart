import 'dart:async';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'geometry.dart';

/// 等画面「稳定」：连续 [stableFor] 内截图不再变化。
///
/// 用一个可注入的 `grab()` 取指纹（生产里是截图 bytes 的哈希），便于单测。
class Stability {
  Stability({
    required Future<String> Function() grab,
    this.interval = const Duration(milliseconds: 300),
  }) : _grab = grab;

  final Future<String> Function() _grab;
  final Duration interval;

  /// 返回是否在 [timeout] 内稳定；超时返回 false（保留最后一次指纹）。
  Future<bool> waitStable({
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final sw = Stopwatch()..start();
    String? last;
    var stableSince = Duration.zero;
    while (sw.elapsed < timeout) {
      final now = await _grab();
      if (now == last) {
        stableSince += interval;
        if (stableSince >= stableFor) return true;
      } else {
        last = now;
        stableSince = Duration.zero;
      }
      await Future<void>.delayed(interval);
    }
    return false;
  }

  /// 执行 [action] 后，看画面在 [timeout] 内是否发生变化。
  Future<bool> changedAfter(Future<void> Function() action,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final before = await _grab();
    await action();
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      final after = await _grab();
      if (after != before) return true;
      await Future<void>.delayed(interval);
    }
    return false;
  }
}

/// 截图指纹：相等即「画面没变」。
///
/// 用长度 + 每隔 [step] 字节采样，足够判断变化，不追求加密强度。
class ScreenFingerprint {
  const ScreenFingerprint._();

  static String of(Uint8List bytes, {int step = 4096}) {
    var acc = bytes.length;
    for (var i = 0; i < bytes.length; i += step) {
      acc = (acc * 31 + bytes[i]) & 0x7fffffff;
    }
    return '$acc';
  }

  /// 只对图片的 [region]（px）取指纹：局部变化（弹 Toast / 改一行字）才看得见，
  /// 不会被 banner 轮播、页面滚动之类的无关变化干扰。
  ///
  /// 解码失败时退化成整图指纹（不抛）。
  static String ofRegion(
    Uint8List pngBytes, {
    required DRect region,
    int step = 2,
  }) {
    final image = img.decodePng(pngBytes);
    if (image == null) return of(pngBytes);
    final left = region.left.round().clamp(0, image.width - 1);
    final top = region.top.round().clamp(0, image.height - 1);
    final right = (region.left + region.width).round().clamp(left + 1, image.width);
    final bottom = (region.top + region.height).round().clamp(top + 1, image.height);

    var acc = (right - left) * (bottom - top);
    for (var y = top; y < bottom; y += step) {
      for (var x = left; x < right; x += step) {
        final p = image.getPixel(x, y);
        acc = (acc * 31 + p.r.toInt() + p.g.toInt() * 3 + p.b.toInt() * 7) & 0x7fffffff;
      }
    }
    return '$acc';
  }
}

/// 点按自检：先等稳定 → 取指纹 → 点 → 等稳定 → 比指纹。
///
/// 直接比「点击前后一帧」会把水波纹/动画当成页面变化，所以中间要等稳定。
class TapVerifier {
  const TapVerifier._();

  static Future<bool> verify({
    required Stability stability,
    required Future<String> Function() fingerprint,
    required Future<void> Function() tap,
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await stability.waitStable(stableFor: stableFor, timeout: timeout);
    final before = await fingerprint();
    await tap();
    await stability.waitStable(stableFor: stableFor, timeout: timeout);
    return before != await fingerprint();
  }
}
