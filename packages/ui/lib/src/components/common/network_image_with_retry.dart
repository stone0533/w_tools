import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'image.dart';

/// 支持重试的网络图片组件
///
/// 当网络图片加载失败时，会自动重试指定次数。
/// 通过在重试时修改 key 强制 CachedNetworkImage 重新发起请求
/// （否则它会命中内部缓存的失败状态而不再请求）。
class WNetworkImageWithRetry extends StatefulWidget {
  /// 网络图片地址
  final String imageUrl;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 图片适配模式
  final BoxFit? fit;

  /// 自定义占位符构建器
  final Widget? Function(BuildContext, String)? placeholder;

  /// 加载进度指示器构建器；非空时走「带进度」的加载分支
  final Widget? Function(BuildContext, String, DownloadProgress)? progressIndicatorBuilder;

  /// 自定义错误占位构建器
  final Widget? Function(BuildContext, String, dynamic)? errorWidget;

  /// 默认占位符（未提供 [placeholder] 时使用）
  final Widget defaultPlaceholder;

  /// 默认错误占位（未提供 [errorWidget] 时使用）
  final Widget defaultErrorWidget;

  /// 最大重试次数
  final int retryCount;

  /// 重试间隔（毫秒）
  final int retryDelay;

  /// 加载状态回调
  final ValueChanged<WImageLoadStatus>? onLoadStatusChanged;

  /// 加载进度回调（0.0-1.0）
  final ValueChanged<double>? onLoadProgress;

  const WNetworkImageWithRetry({
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
  State<WNetworkImageWithRetry> createState() => _WNetworkImageWithRetryState();
}

class _WNetworkImageWithRetryState extends State<WNetworkImageWithRetry> {
  int _currentRetryCount = 0;

  /// 上一次已通知的加载状态（避免重复回调）
  WImageLoadStatus? _lastStatus;

  /// 是否已有待执行的重试（避免 errorWidget 多次构建时重复调度）
  bool _retryScheduled = false;

  /// 通知加载状态（同一状态只通知一次）
  void _notifyStatus(WImageLoadStatus status, {double? progress}) {
    if (_lastStatus == status) return;
    _lastStatus = status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadStatusChanged?.call(status);
      if (progress != null) widget.onLoadProgress?.call(progress);
    });
  }

  /// 延迟重试（同一时刻只允许一个待执行的重试）
  void _scheduleRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    Future.delayed(Duration(milliseconds: widget.retryDelay), () {
      if (!mounted) return;
      setState(() {
        _currentRetryCount++;
        _lastStatus = null;
        _retryScheduled = false;
      });
    });
  }

  @override
  void didUpdateWidget(WNetworkImageWithRetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 地址或重试参数变化时重置本地状态，避免沿用上一次的重试进度
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.retryCount != widget.retryCount ||
        oldWidget.retryDelay != widget.retryDelay) {
      _currentRetryCount = 0;
      _lastStatus = null;
      _retryScheduled = false;
    }
  }

  bool get _hasMoreRetries => _currentRetryCount < widget.retryCount;

  @override
  Widget build(BuildContext context) {
    // 用 ValueKey 绑定当前重试次数 — key 变化时 CachedNetworkImage 会被销毁重建，
    // 从而重新发起网络请求（cached_network_image 内部按 imageUrl 缓存失败状态，
    // 不改 key 的话重建也不会重新 fetch）
    final imageKey = ValueKey('${widget.imageUrl}#retry=$_currentRetryCount');

    Widget onError(BuildContext ctx, String url, dynamic error) {
      if (_hasMoreRetries) {
        _scheduleRetry();
        return widget.placeholder?.call(ctx, url) ?? widget.defaultPlaceholder;
      }
      _notifyStatus(WImageLoadStatus.failed);
      return widget.errorWidget?.call(ctx, url, error) ?? widget.defaultErrorWidget;
    }

    Widget onImageLoaded(BuildContext ctx, ImageProvider imageProvider) {
      _notifyStatus(WImageLoadStatus.completed, progress: 1.0);
      return Image(
        image: imageProvider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (widget.progressIndicatorBuilder != null) {
      return CachedNetworkImage(
        key: imageKey,
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        progressIndicatorBuilder: (ctx, url, downloadProgress) {
          _notifyStatus(WImageLoadStatus.loading);
          widget.onLoadProgress?.call(downloadProgress.progress ?? 0.0);
          return widget.progressIndicatorBuilder!.call(ctx, url, downloadProgress) ??
              widget.defaultPlaceholder;
        },
        errorWidget: onError,
        imageBuilder: onImageLoaded,
      );
    }

    return CachedNetworkImage(
      key: imageKey,
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (ctx, url) {
        _notifyStatus(WImageLoadStatus.loading);
        return widget.placeholder?.call(ctx, url) ?? widget.defaultPlaceholder;
      },
      errorWidget: onError,
      imageBuilder: onImageLoaded,
    );
  }
}
