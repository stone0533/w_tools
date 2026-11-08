import 'package:flutter/material.dart';

/// 刷新失败但仍有旧数据时使用的紧凑错误条。
class WAsyncErrorBanner extends StatelessWidget {
  const WAsyncErrorBanner({
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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title: $error',
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
    );
  }
}
