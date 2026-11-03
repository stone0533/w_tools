import 'package:flutter/material.dart';

/// 二维码扫描框样式配置
class WQrViewOverlayShape {
  /// 边框宽度（逻辑像素）
  final double borderWidth;

  /// 遮罩颜色
  final Color overlayColor;

  /// 边框圆角（逻辑像素）
  final double borderRadius;

  /// 边框长度（逻辑像素）
  final double borderLength;

  /// 扫描框宽度（逻辑像素）
  final double cutOutWidth;

  /// 扫描框高度（逻辑像素）
  final double cutOutHeight;

  /// 扫描框底部偏移（逻辑像素）
  final double cutOutBottomOffset;

  /// 创建扫描框样式
  ///
  /// - [borderWidth]：默认 3.0
  /// - [overlayColor]：默认半透明黑色
  /// - [borderRadius]：默认 0
  /// - [borderLength]：默认 40
  /// - [cutOutWidth]：默认 250
  /// - [cutOutHeight]：默认等于 [cutOutWidth]
  /// - [cutOutBottomOffset]：默认 0
  const WQrViewOverlayShape({
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 250,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  }) : assert(borderWidth > 0, 'borderWidth 必须大于 0'),
       assert(borderLength > 0, 'borderLength 必须大于 0'),
       assert(cutOutWidth > 0, 'cutOutWidth 必须大于 0'),
       assert(
         (cutOutHeight ?? cutOutWidth) > 0,
         'cutOutHeight 必须大于 0',
       ),
       cutOutHeight = cutOutHeight ?? cutOutWidth;

  @override
  bool operator ==(Object other) =>
      other is WQrViewOverlayShape &&
      other.borderWidth == borderWidth &&
      other.overlayColor == overlayColor &&
      other.borderRadius == borderRadius &&
      other.borderLength == borderLength &&
      other.cutOutWidth == cutOutWidth &&
      other.cutOutHeight == cutOutHeight &&
      other.cutOutBottomOffset == cutOutBottomOffset;

  @override
  int get hashCode => Object.hash(
    borderWidth,
    overlayColor,
    borderRadius,
    borderLength,
    cutOutWidth,
    cutOutHeight,
    cutOutBottomOffset,
  );
}
