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
    this.compact = false,
  });

  final WImageError error;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// 小尺寸时只显示图标（不显示文案/按钮）
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer.withValues(alpha: 0.35),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
          final showText = !compact && width >= 96 && height >= 64;
          final showButton = !compact && onRetry != null && width >= 120 && height >= 112;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: colors.error),
                  if (showText) ...[
                    const SizedBox(height: 4),
                    Text(
                      error.message,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (showButton) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(retryLabel),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
