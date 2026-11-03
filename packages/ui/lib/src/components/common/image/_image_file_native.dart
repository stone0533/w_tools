// 原生平台（iOS/Android/Desktop）— 有 dart:io
// 此文件仅在 dart.library.io 可用时被编译

import 'dart:io';

import 'package:flutter/painting.dart';

/// 原生平台的文件图片 provider；路径不存在时由 `Image.errorBuilder` 处理
ImageProvider? buildFileImageProvider(String path) => FileImage(File(path));
