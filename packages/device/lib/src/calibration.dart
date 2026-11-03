import 'dart:collection';
import 'dart:math' as math;
import 'geometry.dart';

import 'package:image/image.dart' as img;

import 'device_hub.dart';

/// 标定结果：DeviceHub 窗口 + 设备屏幕在窗口内的矩形（窗口坐标，单位 point）。
class Calibration {
  const Calibration({
    required this.window,
    required this.deviceRect,
    required this.deviceWidth,
    required this.deviceHeight,
    this.screenshotWidth = 0,
    this.screenshotHeight = 0,
    this.scale = 0,
  });

  final HubWindow window;

  /// 设备屏幕矩形（窗口局部坐标，point）
  final DRect deviceRect;

  /// 设备逻辑分辨率（point），例如 402 × 874
  final int deviceWidth;
  final int deviceHeight;

  /// 标定时设备截图的像素尺寸；缓存命中时可直接复用，避免重复截图。
  final int screenshotWidth;
  final int screenshotHeight;

  /// 标定时的 px / point；`--scale` 变化时缓存应失效。
  final double scale;

  bool matches(HubWindow w) => window.sameAs(w);

  /// 设备坐标（point）→ 屏幕坐标（point）。
  DPoint toScreen(DPoint devicePoint) {
    final fx = deviceWidth == 0 ? 0.0 : devicePoint.x / deviceWidth;
    final fy = deviceHeight == 0 ? 0.0 : devicePoint.y / deviceHeight;
    return DPoint(
      window.x + deviceRect.left + fx * deviceRect.width,
      window.y + deviceRect.top + fy * deviceRect.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'window': window.toJson(),
        'deviceRect': {
          'x': deviceRect.left,
          'y': deviceRect.top,
          'w': deviceRect.width,
          'h': deviceRect.height,
        },
        'deviceWidth': deviceWidth,
        'deviceHeight': deviceHeight,
        'screenshotWidth': screenshotWidth,
        'screenshotHeight': screenshotHeight,
        'scale': scale,
      };

  static Calibration? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final window = HubWindow.fromJson(json['window'] as Map<String, dynamic>?);
    final r = json['deviceRect'];
    if (window == null || r is! Map) return null;
    num? at(String k) => r[k] as num?;
    final x = at('x'), y = at('y'), w = at('w'), h = at('h');
    final dw = json['deviceWidth'] as num?;
    final dh = json['deviceHeight'] as num?;
    if (x == null || y == null || w == null || h == null || dw == null || dh == null) {
      return null;
    }
    final sw = json['screenshotWidth'] as num?;
    final sh = json['screenshotHeight'] as num?;
    final scale = json['scale'] as num?;
    return Calibration(
      window: window,
      deviceRect: DRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
      deviceWidth: dw.toInt(),
      deviceHeight: dh.toInt(),
      screenshotWidth: sw?.toInt() ?? 0,
      screenshotHeight: sh?.toInt() ?? 0,
      scale: scale?.toDouble() ?? 0,
    );
  }
}

/// 在 DeviceHub 窗口截图里找「设备屏幕矩形」。
///
/// 思路：机身是接近纯黑的圆角块 → 取最大黑色连通域的外接框 → 向内缩掉边框 →
/// 再按设备宽高比修正。纯函数，便于单测。
class CalibrationDetector {
  const CalibrationDetector();

  /// [image] 是窗口截图（px），[scale] 是 px / point。
  /// [targetAspect] = deviceWidth / deviceHeight。
  Calibration detect({
    required img.Image image,
    required HubWindow window,
    required double scale,
    required int deviceWidth,
    required int deviceHeight,
    int? screenshotWidth,
    int? screenshotHeight,
  }) {
    final targetAspect = deviceWidth / deviceHeight;
    final bbox = _largestDarkBBox(image);
    if (bbox == null) {
      throw StateError('在 DeviceHub 窗口里找不到设备机身（是不是没打开模拟器 / 没有屏幕录制权限？）');
    }

    // 去掉机身边框：横向约 3.2%，纵向按宽高比折算
    final insetX = math.max(3.0, bbox.width * 0.032);
    var rect = bbox.deflate(insetX);
    // 按目标宽高比修正（保留中心）
    final ratio = rect.width / rect.height;
    if (ratio > targetAspect) {
      rect = rect.withSize(rect.height * targetAspect, rect.height);
    } else if (ratio < targetAspect) {
      rect = rect.withSize(rect.width, rect.width / targetAspect);
    }

    // 遮挡检测：设备屏幕应占窗口高度的多数；明显偏小说明被别的窗口压住
    if (rect.height < window.height * 0.45) {
      throw StateError(
        '设备预览可能被其它窗口遮挡（只识别到 ${rect.height.toStringAsFixed(0)}px 高）。'
        '请把 DeviceHub 窗口置于最前再试。',
      );
    }

    final inPoints = DRect(
      rect.left / scale,
      rect.top / scale,
      rect.width / scale,
      rect.height / scale,
    );
    return Calibration(
      window: window,
      deviceRect: inPoints,
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      screenshotWidth: screenshotWidth ?? image.width,
      screenshotHeight: screenshotHeight ?? image.height,
      scale: scale,
    );
  }

  /// 最大黑色连通域的外接框（px）；找不到返回 null。
  static DRect? _largestDarkBBox(img.Image image) {
    // 降采样，避免 872×1084 × 多次 BFS 太慢
    final step = math.max(1, (image.width / 240).ceil()).toInt();
    final w = (image.width / step).ceil();
    final h = (image.height / step).ceil();
    final dark = List<bool>.filled(w * h, false);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final px = image.getPixel(x * step, y * step);
        final v = px.r + px.g + px.b;
        dark[y * w + x] = v < 160;
      }
    }

    final visited = List<bool>.filled(w * h, false);
    var bestArea = 0;
    DRect? best;
    for (var i = 0; i < dark.length; i++) {
      if (!dark[i] || visited[i]) continue;
      // BFS
      var area = 0;
      var minX = w, minY = h, maxX = 0, maxY = 0;
      final q = Queue<int>()..add(i);
      visited[i] = true;
      while (q.isNotEmpty) {
        final cur = q.removeFirst();
        area++;
        final cx = cur % w, cy = cur ~/ w;
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;
        for (final d in [1, -1, w, -w]) {
          final n = cur + d;
          if (n < 0 || n >= dark.length) continue;
          if ((d == 1 && cx == w - 1) || (d == -1 && cx == 0)) continue;
          if (!dark[n] || visited[n]) continue;
          visited[n] = true;
          q.add(n);
        }
      }
      if (area > bestArea) {
        bestArea = area;
        best = DRect(
          minX * step.toDouble(),
          minY * step.toDouble(),
          (maxX - minX + 1) * step.toDouble(),
          (maxY - minY + 1) * step.toDouble(),
        );
      }
    }
    return best;
  }
}
