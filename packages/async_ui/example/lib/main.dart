import 'package:flutter/material.dart';
import 'package:w_tools_async/w_tools_async.dart';
import 'package:w_tools_async_ui/w_tools_async_ui.dart';

void main() => runApp(const AsyncUiExampleApp());

class AsyncUiExampleApp extends StatelessWidget {
  const AsyncUiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('w_tools_async_ui')),
        body: const _ExamplePage(),
      ),
    );
  }
}

class _ExamplePage extends StatefulWidget {
  const _ExamplePage();

  @override
  State<_ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<_ExamplePage> {
  late final WAsyncController<String> _text = WAsyncController<String>(
    (_) async => 'Hello async_ui',
  );
  late final WAsyncPagedController<int> _numbers = WAsyncPagedController<int>(
    (page, _) async => WAsyncPage<int>(
      items: List<int>.generate(10, (index) => (page - 1) * 10 + index),
      hasMore: page < 3,
    ),
  );
  late final WAsyncPagedController<int> _sliverNumbers = WAsyncPagedController<int>(
    (page, _) async => WAsyncPage<int>(
      items: List<int>.generate(3, (index) => (page - 1) * 3 + index),
      hasMore: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    _text.load();
    _numbers.refresh();
    _sliverNumbers.refresh();
  }

  @override
  void dispose() {
    _text.dispose();
    _numbers.dispose();
    _sliverNumbers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WAsyncSection<String>(
          controller: _text,
          builder: (context, data) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(data),
          ),
        ),
        Expanded(
          child: WAsyncPagedList<int>(
            controller: _numbers,
            itemBuilder: (context, value) => ListTile(title: Text('Item $value')),
          ),
        ),
        SizedBox(
          height: 160,
          child: CustomScrollView(
            slivers: [
              WAsyncPagedSliver<int>(
                controller: _sliverNumbers,
                itemBuilder: (context, value) => ListTile(title: Text('Sliver $value')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
