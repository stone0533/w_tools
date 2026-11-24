import 'dart:collection';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'device_hub.dart';
import 'geometry.dart';

/// 标定结果：DeviceHub 窗口 + 设备屏幕矩形（屏幕坐标，单位 point）。
class Calibration {
  const Calibration({
    required this.window,
    required this.deviceRect,
    required this.deviceWidth,
    required this.deviceHeight,
    this.screenshotWidth = 0,
    this.screenshotHeight = 0,
    this.deviceScale = 0,
    this.scale = 0,
    this.windowTitle,
  });

  final HubWindow window;

  /// 设备屏幕矩形（屏幕坐标，point）
  ///
  /// 由窗口截图里的 bbox 加上**取整后的窗口原点**得到，直接用于 [toScreen]。
  final DRect deviceRect;

  /// 设备逻辑分辨率（point），例如 402 × 874
  final int deviceWidth;
  final int deviceHeight;

  /// 设备截图的像素尺寸（px）
  final int screenshotWidth;
  final int screenshotHeight;

  /// DeviceHub 窗口截图 px / point（Retina 通常为 2）；不是设备截图的 scale。
  final double scale;

  /// 标定时读到的 DeviceHub 窗口标题（例如 `iPhone 17 Pro – iOS 26.5`）。
  ///
  /// 只用于诊断：`calibrate --json` 里带上它，方便核对标定的是哪台设备。
  final String? windowTitle;

  /// 设备截图 px / point（例如 1206 / 402 = 3）；优先使用标定时读到的真实密度。
  final int deviceScale;

  /// 设备截图 px / point。
  ///
  /// [deviceScale] 来自 `ScreenMetrics.scale`（plist 真实值）；为 0 时才退回
  /// `screenshotWidth / deviceWidth`（旧缓存 / 单测构造）。
  double get screenshotScale {
    if (deviceScale > 0) return deviceScale.toDouble();
    return deviceWidth == 0 ? 0 : screenshotWidth / deviceWidth;
  }

  /// 设备坐标（point）→ 屏幕坐标（point）。
  ///
  /// [deviceRect] 已经是屏幕坐标；不要再叠加 [window] 原点，否则会整体偏移
  /// window.x / window.y。
  DPoint toScreen(DPoint devicePoint) {
    final fx = deviceWidth == 0 ? 0.0 : devicePoint.x / deviceWidth;
    final fy = deviceHeight == 0 ? 0.0 : devicePoint.y / deviceHeight;
    return DPoint(
      deviceRect.left + fx * deviceRect.width,
      deviceRect.top + fy * deviceRect.height,
    );
  }

  /// CLI 的 `calibrate --json` 形状（唯一一份序列化）。
  ///
  /// 两套 scale 必须分开命名：`window.scale` 是窗口截图 px/point，
  /// `screenshot.scale` 是设备截图 px/point，混用会算错坐标。
  Map<String, Object?> toJson() => {
        'coordinateSpace': 'screen',
        'calibrationVersion': 2,
        'window': {...window.toJson(), 'scale': scale},
        'deviceRect': {
          'x': deviceRect.left,
          'y': deviceRect.top,
          'w': deviceRect.width,
          'h': deviceRect.height,
        },
        'device': {'width': deviceWidth, 'height': deviceHeight},
        'screenshot': {
          'width': screenshotWidth,
          'height': screenshotHeight,
          'scale': screenshotScale,
          'windowScale': scale,
        },
        if (windowTitle != null) 'windowTitle': windowTitle,
      };
}

/// 在 DeviceHub 窗口截图里找「设备屏幕矩形」。
///
/// 思路：机身是接近纯黑的圆角块 → 取最大黑色连通域的外接框 → 向内缩掉边框 →
/// 再按设备宽高比修正。纯函数，便于单测。
///
/// 下面的常量是针对 DeviceHub 窗口（深色机身 + 浅色背景）的实测经验值：
/// 换 Xcode 大版本、DeviceHub 换皮或换缩放后需要重新标定这些数字。
class CalibrationDetector {
  const CalibrationDetector();

  /// 三通道和低于该值算「机身黑」。
  static const int _darkMaxSum = 160;

  /// 机身边框横向内缩比例。
  static const double _bezelInsetRatio = 0.032;

  /// 设备屏幕高度至少占窗口高度的比例；明显偏小说明预览被别的窗口压住。
  static const double _minDeviceHeightRatio = 0.45;

  /// 横屏预览判据：宽高比 > 1.5，且与「设备高/宽」的倒数关系误差 < 25%。
  static const double _landscapeMinRatio = 1.5;
  static const double _landscapeTolerance = 0.25;

  /// 连通域分析前的降采样目标宽度（避免大窗口 BFS 太慢）。
  static const int _downsampleWidth = 240;

  /// [image] 是窗口截图（px），[scale] 是 px / point。
  /// [targetAspect] = deviceWidth / deviceHeight。
  ///
  /// [windowTitle] 只用于把「窗口里选中的不是目标设备」这类误诊写进错误提示。
  Calibration detect({
    required img.Image image,
    required HubWindow window,
    required double scale,
    required int deviceWidth,
    required int deviceHeight,
    int? screenshotWidth,
    int? screenshotHeight,
    int? deviceScale,
    String? windowTitle,
  }) {
    final targetAspect = deviceWidth / deviceHeight;
    final bbox = _largestDarkBBox(image);
    if (bbox == null) {
      throw StateError(
        '在 DeviceHub 窗口里找不到设备机身（是不是没打开模拟器 / 没有屏幕录制权限？）'
        '${windowTitle == null ? '' : '；当前窗口：$windowTitle'}',
      );
    }

    // 横屏预览：机身 bbox 会变成宽>高，但 simctl 截图仍是设备原生竖屏；
    // 当前映射只支持竖屏，明确报错，避免被后面的“遮挡”检查误诊。
    final previewRatio = bbox.width / bbox.height;
    final landscapeRatio = deviceHeight / deviceWidth;
    final looksLandscape = previewRatio > _landscapeMinRatio &&
        ((previewRatio - landscapeRatio).abs() / landscapeRatio) < _landscapeTolerance;
    if (deviceHeight > deviceWidth && looksLandscape) {
      throw StateError(
        '检测到设备预览横屏（约 ${previewRatio.toStringAsFixed(1)}:1），但设备截图仍是竖屏；'
        '当前版本不支持旋转设备，请把模拟器切回 Portrait 后重试。',
      );
    }

    // 去掉机身边框：横向按比例内缩，纵向由宽高比修正
    final insetX = math.max(3.0, bbox.width * _bezelInsetRatio);
    var rect = bbox.deflate(insetX);
    final ratio = rect.width / rect.height;
    if (ratio > targetAspect) {
      rect = rect.withSize(rect.height * targetAspect, rect.height);
    } else if (ratio < targetAspect) {
      rect = rect.withSize(rect.width, rect.width / targetAspect);
    }

    // 遮挡检测：设备屏幕应占窗口高度的多数；明显偏小说明被别的窗口压住，
    // 或者 Device Hub 里选中的是一台已关机设备（只显示机模 + Start）。
    if (rect.height < window.height * _minDeviceHeightRatio) {
      throw StateError(
        '设备预览只识别到 ${rect.height.toStringAsFixed(0)}px 高。可能原因：'
        '① 窗口被其它窗口遮挡；② Device Hub 里选中的设备已关机 / 没有实时预览'
        '${windowTitle == null ? '' : '（当前窗口：$windowTitle）'}。'
        '请把 Device Hub 置于最前，并确认窗口里选中的是目标设备。',
      );
    }

    // `capture` 用 `screencapture -R <round(x)>,<round(y)>,<w>,<h>` 截窗口，
    // 所以截图里的 bbox 是**窗口局部**坐标；加回取整后的窗口原点才是屏幕坐标。
    final originX = window.x.round();
    final originY = window.y.round();
    return Calibration(
      window: window,
      deviceRect: DRect(
        originX + rect.left / scale,
        originY + rect.top / scale,
        rect.width / scale,
        rect.height / scale,
      ),
      deviceWidth: deviceWidth,
      deviceHeight: deviceHeight,
      screenshotWidth: screenshotWidth ?? image.width,
      screenshotHeight: screenshotHeight ?? image.height,
      deviceScale: deviceScale ?? 0,
      scale: scale,
      windowTitle: windowTitle,
    );
  }

  /// 最大黑色连通域的外接框（px）；找不到返回 null。
  static DRect? _largestDarkBBox(img.Image image) {
    final step = math.max(1, (image.width / _downsampleWidth).ceil()).toInt();
    final w = (image.width / step).ceil();
    final h = (image.height / step).ceil();
    final dark = List<bool>.filled(w * h, false);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final px = image.getPixel(x * step, y * step);
        dark[y * w + x] = px.r + px.g + px.b < _darkMaxSum;
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
