import 'package:flutter/material.dart';

/// 默认的异步失败视图。
///
/// 默认只显示 [title]；[message] 需要调用方显式传入。不要把 DioException /
/// TypeError 原文直接塞给终端用户——错误详情应走日志或 `onError`。
///
/// [title] / [message] / [retryText] 只是 fallback，项目应通过 [WAsyncTheme]
/// 或自定义 builder 覆盖品牌文案。
class WAsyncErrorView extends StatelessWidget {
  const WAsyncErrorView({
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(retryText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
