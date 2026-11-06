import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

import 'demo_widgets.dart';

/// 组件页的图片 / 保活 sections。
List<Widget> buildComponentsImageSections({
  required WImageController imageController,
}) {
  return [
    const DemoSectionTitle('WImageController 手动重试'),
    WImage.source(
        source: WImageSource.network('https://example.invalid/controller.png'),
        controller: imageController,
        style: const WImageStyle(width: 160, height: 90),
        slots: const WImageSlots(showRetryButton: true)),
    TextButton(
      onPressed: imageController.retry,
      child: const Text('controller.retry()'),
    ),
    const SizedBox(height: 24),
    const DemoSectionTitle('WKeepAliveWrapper 列表保活'),
    SizedBox(
      height: 96,
      child: WListView(
        scrollDirection: Axis.horizontal,
        sliver: WListViewSliver.list(
          itemCount: 8,
          itemExtent: 96,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WKeepAliveWrapper(
              child: _CounterTile(index: index),
            ),
          ),
        ),
      ),
    ),
  ];
}

class _CounterTile extends StatefulWidget {
  const _CounterTile({required this.index});

  final int index;

  @override
  State<_CounterTile> createState() => _CounterTileState();
}

class _CounterTileState extends State<_CounterTile> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _count++),
        child: Center(
          child: Text(
            '#${widget.index}\n$_count',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
