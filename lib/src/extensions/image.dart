import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 图片扩展类，提供图片预加载功能
extension WImageExtension on Image {
  //  package:google_maps_flutter_platform_interface/src/types/bitmap.dart
  // Future<BitmapDescriptor> loadIcon() async {
  //   String assetPath = 'assets/images/map_address_icon.png';
  //   ByteData bytes = await rootBundle.load(assetPath);
  //   return BitmapDescriptor.bytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  //       imagePixelRatio: 2.5);
  // }

  /// 预加载图片资源
  ///
  /// @param images 图片资源路径列表
  /// @description 提前将图片加载到内存中，避免使用时的加载延迟
  static void imagePrecache({List<String>? images}) {
    if (Get.context != null) {
      images?.forEach((element) {
        precacheImage(AssetImage(element), Get.context!);
      });
    }
  }
}
