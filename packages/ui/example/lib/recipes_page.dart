// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

const _redPixel =
    'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAIklEQVR4nGO8Y2PDQApgIkk1w6gG4gATkergYFQDMYBkDQBDhAF0tn7oPgAAAABJRU5ErkJggg==';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(_redPixel);
    final provider = MemoryImage(bytes);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('头像：WImage + 正方形 + 全圆角'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.asset('assets/demo.png'),
            style: WImageStyle(
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(36),
            ),
          ),
        ),
        const _Code(
          'style: WImageStyle(width: 72, height: 72, borderRadius: BorderRadius.circular(36))',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('缩略图：WImage + 正方形 + 解码上限'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.asset('assets/demo.png'),
            style: const WImageStyle(width: 96, height: 96),
            options: const WImageLoadOptions(memCacheWidth: 288, memCacheHeight: 288),
          ),
        ),
        const _Code(
          'style: WImageStyle(width: 96, height: 96), options: WImageLoadOptions(memCacheWidth: 288, memCacheHeight: 288)',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('封面：WImage + WImageStyle.cover'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.asset('assets/demo.png'),
            style: WImageStyle.cover(aspectRatio: 16 / 9, radius: 12),
          ),
        ),
        const _Code(
          'WImage.source(source: ..., style: WImageStyle.cover(aspectRatio: 16 / 9, radius: 12))',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('宽度铺满 + 高度上限：ConstrainedBox(maxHeight) + fitWidth'),
        const SizedBox(height: 8),
        _Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: WImage.source(
              source: WImageSource.asset('assets/demo.png'),
              style: const WImageStyle(
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        const _Code(
          'ConstrainedBox(maxHeight: 96) + WImageStyle(width: double.infinity, fit: BoxFit.fitWidth, alignment: Alignment.topCenter)',
        ),
        const SizedBox(height: 24),
        const _SectionTitle('资源路径：直接传完整路径'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.asset('assets/demo.png'),
            style: const WImageStyle(width: 120, height: 68),
          ),
        ),
        const _Code(
          "WImage.source(source: WImageSource.asset('assets/demo.png'))",
        ),
        const SizedBox(height: 24),
        const _SectionTitle('内存字节：WImageSource.provider(MemoryImage(...))'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.provider(MemoryImage(bytes)),
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('任意 provider：WImageSource.provider(...)'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.provider(provider),
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('内置错误 + 重试'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.source(
            source: WImageSource.network('https://example.invalid/retry.png'),
            style: const WImageStyle(width: 160, height: 90),
            options: const WImageLoadOptions(retryCount: 1),
            slots: WImageSlots(
              errorWidgetBuilder: (context, data, error, retry) =>
                  WImageErrorView(error: error, onRetry: retry),
            ),
          ),
        ),
        const _Code(
          'WImageSlots.errorWidgetBuilder: (c, d, error, retry) => WImageErrorView(error: error, onRetry: retry)',
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SelectableText(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
