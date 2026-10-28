// 原生平台（iOS/Android/Desktop）— 有 dart:io
// 此文件仅在 dart.library.io 可用时被编译

import 'dart:io';

import 'package:flutter/material.dart';

import 'image.dart';

/// 原生平台的文件图片 provider；路径不存在时由 `Image.errorBuilder` 处理
ImageProvider? buildFileImageProvider(String path) => FileImage(File(path));

/// 原生平台专用 extension — 提供 buildFile(File) 便利 API
///
/// 这样原生平台调用方可以继续用 `config.buildFile(file)`。
extension WImageConfigIO on WImageConfig {
  /// 构建文件图片组件（dart:io File 对象）
  ///
  /// 仅在原生平台（iOS/Android/Desktop）可用。
  /// Web 平台请使用 `buildFilePath(String path)`。
  WImage buildFile(
    File file, {
    Key? key,
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<WImageProgress>? onProgress,
    WImageController? controller,
  }) {
    return WImage.file(
      file.path,
      key: key,
      config: this,
      onLoadStatusChanged: onLoadStatusChanged,
      onProgress: onProgress,
      controller: controller,
    );
  }
}
