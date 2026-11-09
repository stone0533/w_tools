import 'dart:async';
import 'dart:math' as math;
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
      final grabStarted = sw.elapsed;
      final now = await _grab();
      final grabTook = sw.elapsed - grabStarted;
      if (now == last) {
        stableSince += interval + grabTook;
        if (stableSince >= stableFor) return true;
      } else {
        last = now;
        stableSince = Duration.zero;
      }
      await Future<void>.delayed(interval);
    }
    return false;
  }
}

/// 截图指纹：相等即「画面没变」。
///
/// PNG 先解码成像素再采样，避免「同一画面、不同 PNG 压缩/元数据」被误判为变化；
/// 非 PNG（测试或异常输出）退化为长度 + 字节采样。
class ScreenFingerprint {
  const ScreenFingerprint._();

  static String of(Uint8List bytes, {int step = 4096}) {
    final image = img.decodePng(bytes);
    if (image == null) {
      var acc = bytes.length;
      for (var i = 0; i < bytes.length; i += step) {
        acc = (acc * 31 + bytes[i]) & 0x7fffffff;
      }
      return '$acc';
    }
    // 约采样 [step] 个像素（step 是「字节步长」的旧语义，这里换算成像素步长）。
    final stride = math.max(1, math.sqrt(step).round());
    var acc = image.width * 1000003 + image.height;
    for (var y = 0; y < image.height; y += stride) {
      for (var x = 0; x < image.width; x += stride) {
        final p = image.getPixel(x, y);
        acc = (acc * 31 + p.r.toInt() + p.g.toInt() * 3 + p.b.toInt() * 7) & 0x7fffffff;
      }
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

/// `verify` 在等待画面稳定时超时；CLI 把它映射成退出码 3（外部/超时）。
class VerificationTimeout implements Exception {
  const VerificationTimeout(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 点按自检：先等稳定 → 取指纹 → 点 → 等稳定 → 比指纹。
///
/// 直接比「点击前后一帧」会把水波纹/动画当成页面变化，所以中间要等稳定。
/// 任何一次稳定等待超时都抛 [VerificationTimeout]，不把「没等到稳定」误报成「没变化」。
class TapVerifier {
  const TapVerifier._();

  static Future<bool> verify({
    required Stability stability,
    required Future<String> Function() fingerprint,
    required Future<void> Function() tap,
    Duration stableFor = const Duration(milliseconds: 600),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!await stability.waitStable(stableFor: stableFor, timeout: timeout)) {
      throw const VerificationTimeout('点击前画面在超时内没有稳定，无法可靠判定');
    }
    final before = await fingerprint();
    await tap();
    if (!await stability.waitStable(stableFor: stableFor, timeout: timeout)) {
      throw const VerificationTimeout('点击后画面在超时内没有稳定，无法可靠判定');
    }
    return before != await fingerprint();
  }
}

/// 截图健康检查：真机锁屏/息屏时 devicectl 会吐一张全黑图。
class ScreenStats {
  const ScreenStats._();

  /// 采样判断是否「几乎全黑」（亮度均值 < [threshold]）。
  static bool isMostlyDark(Uint8List pngBytes, {int threshold = 12, int step = 8}) {
    final image = img.decodePng(pngBytes);
    if (image == null) return false;
    var sum = 0;
    var count = 0;
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final p = image.getPixel(x, y);
        sum += (p.r.toInt() + p.g.toInt() + p.b.toInt()) ~/ 3;
        count++;
      }
    }
    if (count == 0) return false;
    return sum / count < threshold;
  }
}
