import 'package:flutter/material.dart';

import 'playground_config.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

Widget buildPlaygroundPreview({
  required PlaygroundConfig config,
  required WImageController controller,
  required ValueChanged<String> onStatus,
  required ValueChanged<WImageProgress> onProgress,
}) {
  return switch (config.isNetwork) {
    false => WImage.source(
      source: WImageSource.asset('assets/demo.png', prefix: false),
      style: _styleFor(config),
      options: _optionsFor(config),
      slots: _slotsFor(config),
      controller: controller,
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
      controller: controller,
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
  margin: config.withMargin ? const EdgeInsets.all(8) : null,
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
  errorWidgetBuilder: (context, data, error) => const _ErrorBox(),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
