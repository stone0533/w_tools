// Web 平台 — 无 dart:io
// 此文件在 Web（含 WASM）被编译：没有文件系统，返回 null 由上层渲染「不支持」

import 'package:flutter/material.dart';

/// Web 平台没有文件系统，`file://` 路径无法读取
ImageProvider? buildFileImageProvider(String path) => null;
