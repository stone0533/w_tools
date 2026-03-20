import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../common/image.dart';

/// 支持重试的网络图片组件
///
/// 当网络图片加载失败时，会自动重试指定次数
class NetworkImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? Function(BuildContext, String)? placeholder;
  final Widget? Function(BuildContext, String, DownloadProgress)? progressIndicatorBuilder;
  final Widget? Function(BuildContext, String, dynamic)? errorWidget;
  final Widget defaultPlaceholder;
  final Widget defaultErrorWidget;
  final int retryCount;
  final int retryDelay;
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;
  final ValueChanged<double>? onLoadProgress;

  const NetworkImageWithRetry({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    required this.defaultPlaceholder,
    required this.defaultErrorWidget,
    required this.retryCount,
    required this.retryDelay,
    this.onLoadStatusChanged,
    this.onLoadProgress,
  });

  @override
  State<NetworkImageWithRetry> createState() => NetworkImageWithRetryState();
}

class NetworkImageWithRetryState extends State<NetworkImageWithRetry> {
  int currentRetryCount = 0;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    // 检查是否设置了进度指示器构建器
    if (widget.progressIndicatorBuilder != null) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        progressIndicatorBuilder: (context, url, downloadProgress) {
          if (isLoading) {
            widget.onLoadStatusChanged?.call(WImageLoadStatus.loading);
            isLoading = false;
          }
          widget.onLoadProgress?.call(downloadProgress.progress ?? 0.0);
          final progressWidget = widget.progressIndicatorBuilder?.call(
            context,
            url,
            downloadProgress,
          );
          return progressWidget ?? widget.defaultPlaceholder;
        },
        errorWidget: (context, url, error) {
          if (currentRetryCount < widget.retryCount) {
            // 延迟后重试
            Future.delayed(Duration(milliseconds: widget.retryDelay), () {
              setState(() {
                currentRetryCount++;
                isLoading = true;
              });
            });
            return widget.placeholder?.call(context, url) ?? widget.defaultPlaceholder;
          } else {
            widget.onLoadStatusChanged?.call(WImageLoadStatus.failed);
            return widget.errorWidget?.call(context, url, error) ?? widget.defaultErrorWidget;
          }
        },
        imageBuilder: (context, imageProvider) {
          widget.onLoadStatusChanged?.call(WImageLoadStatus.completed);
          widget.onLoadProgress?.call(1.0);
          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) {
          if (isLoading) {
            widget.onLoadStatusChanged?.call(WImageLoadStatus.loading);
            isLoading = false;
          }
          return widget.placeholder?.call(context, url) ?? widget.defaultPlaceholder;
        },
        errorWidget: (context, url, error) {
          if (currentRetryCount < widget.retryCount) {
            // 延迟后重试
            Future.delayed(Duration(milliseconds: widget.retryDelay), () {
              setState(() {
                currentRetryCount++;
                isLoading = true;
              });
            });
            return widget.placeholder?.call(context, url) ?? widget.defaultPlaceholder;
          } else {
            widget.onLoadStatusChanged?.call(WImageLoadStatus.failed);
            return widget.errorWidget?.call(context, url, error) ?? widget.defaultErrorWidget;
          }
        },
        imageBuilder: (context, imageProvider) {
          widget.onLoadStatusChanged?.call(WImageLoadStatus.completed);
          widget.onLoadProgress?.call(1.0);
          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      );
    }
  }
}
