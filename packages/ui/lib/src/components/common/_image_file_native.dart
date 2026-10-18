// 原生平台（iOS/Android/Desktop）— 有 dart:io
// 此文件仅在 dart.library.io 可用时被编译

import 'dart:io';
import 'package:flutter/material.dart';

import 'image.dart';

/// 原生平台文件图片构建器
///
/// 检查文件存在 → Image.file 渲染
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
  return _WFileImage(
    data: data,
    handleLoadLoading: handleLoadLoading,
    handleLoadCompleted: handleLoadCompleted,
    handleLoadFailed: handleLoadFailed,
    placeholder: placeholder,
    errorWidget: errorWidget,
    defaultPlaceholder: defaultPlaceholder,
    defaultErrorWidget: defaultErrorWidget,
    width: width,
    height: height,
    fit: fit,
  );
}

/// 文件图片组件（缓存 exists Future，避免父级重建时重复 IO）
class _WFileImage extends StatefulWidget {
  final String data;
  final VoidCallback handleLoadLoading;
  final VoidCallback handleLoadCompleted;
  final VoidCallback handleLoadFailed;
  final Widget? Function(BuildContext, String)? placeholder;
  final Widget? Function(BuildContext, String, dynamic)? errorWidget;
  final Widget defaultPlaceholder;
  final Widget defaultErrorWidget;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _WFileImage({
    required this.data,
    required this.handleLoadLoading,
    required this.handleLoadCompleted,
    required this.handleLoadFailed,
    required this.placeholder,
    required this.errorWidget,
    required this.defaultPlaceholder,
    required this.defaultErrorWidget,
    required this.width,
    required this.height,
    required this.fit,
  });

  @override
  State<_WFileImage> createState() => _WFileImageState();
}

class _WFileImageState extends State<_WFileImage> {
  late Future<bool> _existsFuture;

  File get _file => File(widget.data.replaceFirst('file://', ''));

  @override
  void initState() {
    super.initState();
    _existsFuture = _file.exists();
  }

  @override
  void didUpdateWidget(_WFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _existsFuture = _file.exists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _existsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          widget.handleLoadLoading();
          return widget.placeholder?.call(context, widget.data) ?? widget.defaultPlaceholder;
        }
        if (!snapshot.data!) {
          widget.handleLoadFailed();
          return widget.errorWidget?.call(context, widget.data, 'File not found') ??
              widget.defaultErrorWidget;
        }
        widget.handleLoadCompleted();
        return Image.file(
          _file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            widget.handleLoadFailed();
            return widget.errorWidget?.call(context, widget.data, error) ??
                widget.defaultErrorWidget;
          },
        );
      },
    );
  }
}

/// 原生平台专用 extension — 提供 buildFile(File) 便利 API
///
/// 这样原生平台调用方可以继续用 config.buildFile(file)
extension WImageConfigIO on WImageConfig {
  /// 构建文件图片组件（dart:io File 对象）
  ///
  /// 仅在原生平台（iOS/Android/Desktop）可用。
  /// Web 平台请使用 `buildFilePath(String path)`。
  WImage buildFile(
    File file, {
    ValueChanged<WImageLoadStatus>? onLoadStatusChanged,
    ValueChanged<double>? onLoadProgress,
  }) {
    return buildFilePath(
      file.path,
      onLoadStatusChanged: onLoadStatusChanged,
      onLoadProgress: onLoadProgress,
    );
  }
}
