import 'package:flutter/material.dart';
import 'package:w_tools/src/config.dart';
import 'package:w_tools/src/components/common/image.dart';

import 'color.dart';

/// String 扩展类，提供各种便捷方法
extension WStringExtension on String {
  /// 将字符串转换为 int
  ///
  /// @return 转换后的 int 值，如果转换失败则返回 null
  int? toInt() {
    return int.tryParse(this);
  }

  /// 将字符串转换为 double
  ///
  /// @return 转换后的 double 值，如果转换失败则返回 null
  double? toDouble() {
    return double.tryParse(this);
  }

  /// 将字符串转换为 num
  ///
  /// @return 转换后的 num 值，如果转换失败则返回 null
  num? toNum() {
    return num.tryParse(this);
  }

  /// 删除全部空格
  ///
  /// @return 删除空格后的字符串
  String trimAll() {
    return replaceAll(RegExp(r"\s+|\s+\b|\b\s"), '');
  }

  /// 将十六进制字符串转换为颜色
  ///
  /// @return 转换后的 Color 对象
  Color toColor() {
    return HexColor.fromHex(this);
  }

  /// 拼接资产图片路径
  ///
  /// @return 完整的资产图片路径
  String appendAssetsImage() {
    return '${WConfig.instance.assetsImagePath}$this';
  }

  /// 将字符串转换为 WImage 组件
  ///
  /// @param width 图片宽度
  /// @param height 图片高度
  /// @param size 图片尺寸（同时设置宽度和高度）
  /// @param fit 图片适配模式
  /// @param onLoadStatusChanged 加载状态回调
  /// @param onLoadProgress 加载进度回调
  /// @return WImage 组件
  WImage toImage({
    double? width,
    double? height,
    double? size,
    BoxFit? fit,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    final config = WImageConfig()
      ..width = size ?? width
      ..height = size ?? height;

    if (fit != null) {
      config.fit = fit;
    }

    return WImage(
      config: config,
      data: this,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }
}
