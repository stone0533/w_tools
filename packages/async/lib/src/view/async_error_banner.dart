import 'package:flutter/material.dart';

/// 刷新失败但仍有旧数据时使用的紧凑错误条。
///
/// 默认只显示 [title]；[message] 需要调用方显式传入，不要直接传异常原文。
class WAsyncErrorBanner extends StatelessWidget {
  const WAsyncErrorBanner({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryText = 'Retry',
  });

  final String title;

  /// 面向用户的补充说明；null 时不渲染。不要直接传异常原文。
  final String? message;
  final VoidCallback? onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message == null ? title : '$title: $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(retryText),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
