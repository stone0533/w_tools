import 'package:flutter/material.dart';

/// 扫描框样式
///
/// 扫描相关的视觉参数只有这一处：是否显示扫描框、边框颜色、成功色、外边距
/// 与扫描框几何。
///
/// 语义：
/// - [isVisible] 为 false 时全屏扫描，其余字段均不生效；
/// - [borderColor] 是扫描中的边框颜色，[successColor] 是单次扫码成功后
///   （`scanOnce: true` 且传了 `WQrView.onScanned`）的边框颜色，
///   保持到 `WQrController.restart()`。
class WQrOverlayStyle {
  /// 创建扫描框样式
  ///
  /// 约束：`borderLength <= min(cutOutWidth, cutOutHeight) / 2 + borderWidth * 2`
  /// （与插件 `QrScannerOverlayShape` 的断言一致）。
  ///
  /// - [isVisible]：默认 true
  /// - [borderColor]：默认 `Colors.red`
  /// - [successColor]：默认 `Colors.green`
  /// - [margin]：默认 [EdgeInsets.zero]
  /// - [borderWidth]：默认 3.0
  /// - [overlayColor]：默认半透明黑色
  /// - [borderRadius]：默认 0
  /// - [borderLength]：默认 40
  /// - [cutOutWidth]：默认 250
  /// - [cutOutHeight]：默认等于 [cutOutWidth]
  /// - [cutOutBottomOffset]：默认 0
  const WQrOverlayStyle({
    this.isVisible = true,
    this.borderColor = Colors.red,
    this.successColor = Colors.green,
    this.margin = EdgeInsets.zero,
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
       cutOutHeight = cutOutHeight ?? cutOutWidth,
       assert(
         borderLength <=
             (((cutOutHeight ?? cutOutWidth) < cutOutWidth)
                         ? (cutOutHeight ?? cutOutWidth)
                         : cutOutWidth) /
                     2 +
                 borderWidth * 2,
         'borderLength 过大：需 <= min(cutOutWidth, cutOutHeight) / 2 + borderWidth * 2',
       );

  /// 是否绘制扫描框；为 false 时全屏扫描，其余字段不生效
  final bool isVisible;

  /// 扫描中的扫描框边框颜色
  final Color borderColor;

  /// 单次扫码成功后的边框颜色（保持到 `WQrController.restart()`）
  final Color successColor;

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

  @override
  bool operator ==(Object other) =>
      other is WQrOverlayStyle &&
      other.isVisible == isVisible &&
      other.borderColor == borderColor &&
      other.successColor == successColor &&
      other.margin == margin &&
      other.borderWidth == borderWidth &&
      other.overlayColor == overlayColor &&
      other.borderRadius == borderRadius &&
      other.borderLength == borderLength &&
      other.cutOutWidth == cutOutWidth &&
      other.cutOutHeight == cutOutHeight &&
      other.cutOutBottomOffset == cutOutBottomOffset;

  @override
  int get hashCode => Object.hash(
    isVisible,
    borderColor,
    successColor,
    margin,
    borderWidth,
    overlayColor,
    borderRadius,
    borderLength,
    cutOutWidth,
    cutOutHeight,
    cutOutBottomOffset,
  );
}
