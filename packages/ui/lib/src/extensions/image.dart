import 'package:flutter/material.dart';

/// 图片扩展类，提供图片预加载功能
extension WImageExtension on Image {
  /// 预加载图片资源（仅 asset）
  ///
  /// 已废弃：请使用 `WImagePreloader.preloadImages` 或 Flutter 的
  /// `precacheImage`。这个方法只支持 AssetImage，不能处理网络/文件/Base64。
  ///
  /// - [context]：BuildContext 上下文
  /// - [images]：图片资源路径列表
  /// 提前将图片加载到内存中，避免使用时的加载延迟
  @Deprecated('Use WImagePreloader.preloadImages or precacheImage instead')
  static void imagePrecache({
    required BuildContext context,
    List<String>? images,
  }) {
    images?.forEach((element) {
      precacheImage(AssetImage(element), context);
    });
  }
}
