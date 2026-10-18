// Web 平台 — 无 dart:io
// Web 没有文件系统，Image.file(File) 不可用
// 此文件仅在 dart.library.html 可用时被编译

import 'package:flutter/material.dart';

/// Web 平台文件图片构建器
///
/// Web 没有文件系统，file:// 路径不可用 → 显示 error widget
Widget buildFileImagePlatform({
  required BuildContext context,
  required String data,
  required VoidCallback handleLoadLoading,
  required VoidCallback handleLoadCompleted,
  required VoidCallback handleLoadFailed,
  Widget? Function(BuildContext, String)? placeholder,
  Widget? Function(BuildContext, String, dynamic)? errorWidget,
  required Widget defaultPlaceholder,
  required Widget defaultErrorWidget,
  required double? width,
  required double? height,
  required BoxFit fit,
}) {
  // Web 平台无文件系统 → 直接回调失败
  WidgetsBinding.instance.addPostFrameCallback((_) {
    handleLoadFailed();
  });
  return errorWidget?.call(context, data, 'Web 平台不支持 file:// 路径') ?? defaultErrorWidget;
}
