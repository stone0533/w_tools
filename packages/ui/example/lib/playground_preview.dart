import 'package:flutter/material.dart';

import 'playground_config.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget buildPlaygroundPreview({
  required PlaygroundConfig config,
  required ValueChanged<String> onStatus,
  required ValueChanged<WImageProgress> onProgress,
}) {
  return switch (config.isNetwork) {
    false => WImage.source(
      source: WImageSource.asset('assets/demo.png'),
      style: _styleFor(config),
      options: _optionsFor(config),
      slots: _slotsFor(config),
      onLoadStatusChanged: (status) => onStatus(status.name),
      onProgress: (progress) => onProgress(progress),
    ),
    true => WImage.source(
      source: WImageSource.network(
        'https://picsum.photos/seed/wtools-playground/640/360',
        headers: const {'X-Demo': 'playground'},
        cacheKey: 'wtools-playground',
      ),
      style: _styleFor(config),
      options: _optionsFor(config),
      slots: _slotsFor(config),
      onLoadStatusChanged: (status) => onStatus(status.name),
      onProgress: (progress) => onProgress(progress),
    ),
  };
}

WImageStyle _styleFor(PlaygroundConfig config) => WImageStyle(
  width: config.aspectRatio == null ? config.width : null,
  height: config.aspectRatio == null ? config.height : null,
  aspectRatio: config.aspectRatio,
  fit: config.fit,
  borderRadius: BorderRadius.circular(config.radius),
  border: config.withBorder ? Border.all(color: const Color(0xFF4F46E5), width: 2) : null,
  boxShadow: config.withShadow ? WShadows.card : null,
  semanticLabel: 'playground image',
);

WImageLoadOptions _optionsFor(PlaygroundConfig config) => WImageLoadOptions(
  memCacheWidth: config.memCache,
  memCacheHeight: config.memCache,
  retryCount: config.retryCount,
  retryDelay: 500,
);

WImageSlots _slotsFor(PlaygroundConfig config) => WImageSlots(
  placeholderBuilder: config.customPlaceholder ? (context, data) => const _Placeholder() : null,
  errorWidgetBuilder: (context, data, error, retry) =>
      WImageErrorView(error: error, onRetry: retry),
);

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined)),
    );
  }
}
