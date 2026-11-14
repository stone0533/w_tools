import 'package:flutter/material.dart';

import 'playground_config.dart';

/// Playground 的控制面板：只读 config，通过 onChanged 回传新快照。
class PlaygroundControls extends StatelessWidget {
  const PlaygroundControls({
    super.key,
    required this.config,
    required this.onChanged,
    required this.status,
    required this.progress,
  });

  final PlaygroundConfig config;
  final ValueChanged<PlaygroundConfig> onChanged;
  final String? status;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('asset')),
            ButtonSegment(value: true, label: Text('network')),
          ],
          selected: {config.isNetwork},
          onSelectionChanged: (value) => onChanged(config.copyWith(isNetwork: value.first)),
        ),
        const SizedBox(height: 16),
        _SliderTile(
          label: 'width',
          value: config.width,
          min: 80,
          max: 400,
          onChanged: config.aspectRatio == null
              ? (value) => onChanged(config.copyWith(width: value))
              : null,
        ),
        _SliderTile(
          label: 'height',
          value: config.height,
          min: 80,
          max: 400,
          onChanged: config.aspectRatio == null
              ? (value) => onChanged(config.copyWith(height: value))
              : null,
        ),
        _SliderTile(
          label: 'borderRadius',
          value: config.radius,
          min: 0,
          max: 48,
          onChanged: (value) => onChanged(config.copyWith(radius: value)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double?>(
          key: ValueKey(config.aspectRatio),
          initialValue: config.aspectRatio,
          decoration: const InputDecoration(
            labelText: 'aspectRatio',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('off（使用 width/height）')),
            DropdownMenuItem(value: 1, child: Text('1 : 1')),
            DropdownMenuItem(value: 16 / 9, child: Text('16 : 9')),
            DropdownMenuItem(value: 4 / 3, child: Text('4 : 3')),
          ],
          onChanged: (value) => onChanged(config.copyWith(aspectRatio: value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BoxFit>(
          key: ValueKey(config.fit),
          initialValue: config.fit,
          decoration: const InputDecoration(
            labelText: 'fit',
            border: OutlineInputBorder(),
          ),
          items: BoxFit.values
              .map((fit) => DropdownMenuItem(value: fit, child: Text(fit.name)))
              .toList(),
          onChanged: (value) => onChanged(config.copyWith(fit: value ?? BoxFit.cover)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          key: ValueKey(config.memCache),
          initialValue: config.memCache,
          decoration: const InputDecoration(
            labelText: 'memCacheWidth / memCacheHeight',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('off')),
            DropdownMenuItem(value: 240, child: Text('240')),
            DropdownMenuItem(value: 480, child: Text('480')),
            DropdownMenuItem(value: 960, child: Text('960')),
          ],
          onChanged: (value) => onChanged(config.copyWith(memCache: value)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey(config.retryCount),
          initialValue: config.retryCount,
          decoration: const InputDecoration(
            labelText: 'retryCount',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text('0')),
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 3, child: Text('3')),
          ],
          onChanged: (value) => onChanged(config.copyWith(retryCount: value ?? 0)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('自定义 placeholder'),
          subtitle: const Text('关闭后使用 WImageTheme 的默认占位符'),
          value: config.customPlaceholder,
          onChanged: (value) => onChanged(config.copyWith(customPlaceholder: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('WImageStyle.border'),
          value: config.withBorder,
          onChanged: (value) => onChanged(config.copyWith(withBorder: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('WImageStyle.boxShadow'),
          value: config.withShadow,
          onChanged: (value) => onChanged(config.copyWith(withShadow: value)),
        ),
        const SizedBox(height: 8),
        Text(
          'status: ${status ?? '-'} · progress: ${progress?.toStringAsFixed(2) ?? '-'}',
        ),
      ],
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(value.toStringAsFixed(0), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
