import 'package:flutter/material.dart';

/// 扫描框样式
///
/// 传给 `WQrView.style`；`style: null` 表示不绘制扫描框（全屏扫描）。
///
/// [borderWidth] / [borderLength] / 扫描框尺寸必须为正数（本类断言）；
/// `borderLength` 与扫描框尺寸的比例约束由插件 `QrScannerOverlayShape` 断言。
class WQrOverlayStyle {
  /// 创建扫描框样式
  ///
  /// - [borderColor]：默认 `Colors.red`
  /// - [margin]：默认 [EdgeInsets.zero]
  /// - [borderWidth]：默认 3.0
  /// - [overlayColor]：默认半透明黑色
  /// - [borderRadius]：默认 0
  /// - [borderLength]：默认 40
  /// - [cutOutWidth]：默认 250
  /// - [cutOutHeight]：默认等于 [cutOutWidth]
  /// - [cutOutBottomOffset]：默认 0
  const WQrOverlayStyle({
    this.borderColor = Colors.red,
    this.margin = EdgeInsets.zero,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 250,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  }) : cutOutHeight = cutOutHeight ?? cutOutWidth,
       assert(borderWidth > 0, 'borderWidth 必须大于 0'),
       assert(borderLength > 0, 'borderLength 必须大于 0'),
       assert(cutOutWidth > 0, 'cutOutWidth 必须大于 0'),
       assert((cutOutHeight ?? cutOutWidth) > 0, 'cutOutHeight 必须大于 0');

  /// 扫描框边框颜色
  final Color borderColor;

  /// 扫描框外边距
  final EdgeInsetsGeometry margin;

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
}
