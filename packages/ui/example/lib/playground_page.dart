import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

enum _Source { asset, network }

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  _Source _source = _Source.asset;
  double _width = 320;
  double _height = 180;
  double? _aspectRatio;
  BoxFit _fit = BoxFit.cover;
  int? _memCache = 240;
  double _radius = 12;
  int _retryCount = 0;
  bool _customPlaceholder = true;

  WImageStyle get _style => WImageStyle(
        width: _aspectRatio == null ? _width : null,
        height: _aspectRatio == null ? _height : null,
        aspectRatio: _aspectRatio,
        fit: _fit,
        memCacheWidth: _memCache,
        memCacheHeight: _memCache,
        borderRadius: BorderRadius.circular(_radius),
        retryCount: _retryCount,
        retryDelay: 500,
        placeholder: _customPlaceholder ? const _Placeholder() : null,
        errorWidget: const _ErrorBox(),
      );

  Widget _preview() {
    return switch (_source) {
      _Source.asset => WImage.asset(
          'assets/demo.png',
          prefix: false,
          style: _style,
        ),
      _Source.network => WImage.network(
          'https://picsum.photos/seed/wtools-playground/640/360',
          style: _style,
        ),
    };
  }

  String _snippet() {
    final buffer = StringBuffer('WImage.');
    if (_source == _Source.network) {
      buffer.writeln("network('https://…',");
    } else {
      buffer.writeln("asset('assets/demo.png', prefix: false,");
    }
    buffer.writeln('  style: WImageStyle(');
    if (_aspectRatio == null) {
      buffer.writeln('    width: ${_width.toStringAsFixed(0)},');
      buffer.writeln('    height: ${_height.toStringAsFixed(0)},');
    } else {
      buffer.writeln('    aspectRatio: ${_aspectRatio!.toStringAsFixed(2)},');
    }
    buffer.writeln('    fit: BoxFit.${_fit.name},');
    buffer.writeln('    memCacheWidth: $_memCache,');
    buffer.writeln('    memCacheHeight: $_memCache,');
    buffer.writeln(
      '    borderRadius: BorderRadius.circular(${_radius.toStringAsFixed(0)}),',
    );
    buffer.writeln('    retryCount: $_retryCount,');
    if (_customPlaceholder) buffer.writeln('    placeholder: const _Placeholder(),');
    buffer.writeln('  ),');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: _preview()),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_Source>(
          segments: const [
            ButtonSegment(value: _Source.asset, label: Text('asset')),
            ButtonSegment(value: _Source.network, label: Text('network')),
          ],
          selected: {_source},
          onSelectionChanged: (value) => setState(() => _source = value.first),
        ),
        const SizedBox(height: 16),
        _SliderTile(
          label: 'width',
          value: _width,
          min: 80,
          max: 400,
          onChanged: _aspectRatio == null ? (value) => setState(() => _width = value) : null,
        ),
        _SliderTile(
          label: 'height',
          value: _height,
          min: 80,
          max: 400,
          onChanged: _aspectRatio == null ? (value) => setState(() => _height = value) : null,
        ),
        _SliderTile(
          label: 'borderRadius',
          value: _radius,
          min: 0,
          max: 48,
          onChanged: (value) => setState(() => _radius = value),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double?>(
          initialValue: _aspectRatio,
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
          onChanged: (value) => setState(() => _aspectRatio = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BoxFit>(
          initialValue: _fit,
          decoration: const InputDecoration(
            labelText: 'fit',
            border: OutlineInputBorder(),
          ),
          items: BoxFit.values
              .map((fit) => DropdownMenuItem(value: fit, child: Text(fit.name)))
              .toList(),
          onChanged: (value) => setState(() => _fit = value ?? BoxFit.cover),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: _memCache,
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
          onChanged: (value) => setState(() => _memCache = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _retryCount,
          decoration: const InputDecoration(
            labelText: 'retryCount',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text('0')),
            DropdownMenuItem(value: 1, child: Text('1')),
            DropdownMenuItem(value: 3, child: Text('3')),
          ],
          onChanged: (value) => setState(() => _retryCount = value ?? 0),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('自定义 placeholder'),
          subtitle: const Text('关闭后使用 WImageDefaultsScope 的默认占位符'),
          value: _customPlaceholder,
          onChanged: (value) => setState(() => _customPlaceholder = value),
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

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8EAF6),
      child: Center(child: Icon(Icons.image_outlined)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFEBEE),
      child: Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
