import 'package:flutter/material.dart';

/// 默认的异步失败视图，可作为整页错误态或紧凑错误条。
///
/// [title] / [retryText] 只是 fallback，项目应通过 [WAsyncTheme] 或
/// 自定义 builder 覆盖品牌文案。
class WAsyncErrorView extends StatelessWidget {
  const WAsyncErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.title = 'Something went wrong',
    this.retryText = 'Retry',
  });

  final Object error;
  final VoidCallback? onRetry;
  final String title;
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
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
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
