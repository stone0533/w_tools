import 'package:flutter/material.dart';

import 'image_types.dart';

/// 内置的错误占位：图标 + 文案 + 可选重试按钮。
///
/// 通过 `WImageStyle(showRetryButton: true)` 启用；业务也可以直接复用它。
class WImageErrorView extends StatelessWidget {
  const WImageErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = '重试',
  });

  final WImageError error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer.withValues(alpha: 0.35),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: colors.error),
              const SizedBox(height: 4),
              Text(
                error.message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
