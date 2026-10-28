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
        const _SectionTitle('头像：WImage.avatar'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.avatar(
            'assets/demo.png',
            type: WImageType.asset,
            size: 72,
          ),
        ),
        const _Code("WImage.avatar('assets/demo.png', type: WImageType.asset, size: 72)"),
        const SizedBox(height: 24),
        const _SectionTitle('缩略图：WImage.thumbnail'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.thumbnail(
            'assets/demo.png',
            type: WImageType.asset,
            width: 96,
            cacheSize: 288,
          ),
        ),
        const _Code('WImage.thumbnail(..., width: 96, cacheSize: 288)'),
        const SizedBox(height: 24),
        const _SectionTitle('封面：WImage.cover'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.cover(
            'assets/demo.png',
            type: WImageType.asset,
            aspectRatio: 16 / 9,
            radius: 12,
          ),
        ),
        const _Code('WImage.cover(..., aspectRatio: 16 / 9, radius: 12)'),
        const SizedBox(height: 24),
        const _SectionTitle('自动拼接资源路径：WImage.assetImage'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.assetImage(
            'demo.png',
            style: const WImageStyle(width: 120, height: 68),
          ),
        ),
        const _Code("WAssets.imagePath = 'assets/' 后：WImage.assetImage('demo.png')"),
        const SizedBox(height: 24),
        const _SectionTitle('内存字节：WImage.memory'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.memory(
            bytes,
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('任意 provider：WImage.provider'),
        const SizedBox(height: 8),
        _Card(
          child: WImage.provider(
            provider,
            style: const WImageStyle(width: 64, height: 64),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('内置错误 + 重试'),
        const SizedBox(height: 8),
        _Card(
          child: WImage(
            data: 'https://example.invalid/retry.png',
            style: const WImageStyle(
              width: 160,
              height: 90,
              showRetryButton: true,
              retryCount: 1,
            ),
          ),
        ),
        const _Code('WImageStyle(showRetryButton: true, retryCount: 1)'),
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
