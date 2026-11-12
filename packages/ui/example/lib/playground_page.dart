// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'playground_config.dart';
import 'playground_controls.dart';
import 'playground_preview.dart';
import 'playground_snippet.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  PlaygroundConfig _config = const PlaygroundConfig();
  String? _status;
  double? _progress;
  final WImageController _controller = WImageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _snippet() => buildPlaygroundSnippet(
    isNetwork: _config.isNetwork,
    width: _config.width,
    height: _config.height,
    aspectRatio: _config.aspectRatio,
    fitName: _config.fit.name,
    memCache: _config.memCache,
    radius: _config.radius,
    withBorder: _config.withBorder,
    withShadow: _config.withShadow,
    withMargin: _config.withMargin,
    customPlaceholder: _config.customPlaceholder,
    retryCount: _config.retryCount,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: buildPlaygroundPreview(
                config: _config,
                controller: _controller,
                onStatus: (status) => setState(() => _status = status),
                onProgress: (progress) => setState(() => _progress = progress.fraction),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PlaygroundControls(
          config: _config,
          onChanged: (next) => setState(() => _config = next),
          onRetry: _controller.retry,
          status: _status,
          progress: _progress,
        ),
        const SizedBox(height: 8),
        Text('当前代码', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            _snippet(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
