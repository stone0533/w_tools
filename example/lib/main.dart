import 'package:flutter/material.dart';
import 'package:w_tools/w.dart';

void main() {
  runApp(const AggregateExampleApp());
}

class AggregateExampleApp extends StatelessWidget {
  const AggregateExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools 聚合包示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6366F1),
        useMaterial3: true,
      ),
      home: const AggregateExamplePage(),
    );
  }
}

class AggregateExamplePage extends StatefulWidget {
  const AggregateExamplePage({super.key});

  @override
  State<AggregateExamplePage> createState() => _AggregateExamplePageState();
}

class _AggregateExamplePageState extends State<AggregateExamplePage> {
  final _form = WFormController();
  late final WAsyncController<String> _async;
  String? _result;

  @override
  void initState() {
    super.initState();
    _async = WAsyncController<String>(_loadAsync);
    _async.load();
  }

  @override
  void dispose() {
    _async.dispose();
    super.dispose();
  }

  Future<String> _loadAsync() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return '聚合入口的异步结果';
  }

  void _submit() {
    if (!_form.validate()) return;
    final values = _form.value;
    const cityLabels = {'HK': '香港', 'SZ': '深圳', 'SH': '上海'};
    final city = values['city'] as String?;
    setState(() {
      _result = '${values['nickname']} / ${cityLabels[city] ?? city}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('w_tools 聚合包')),
      body: WForm(
        controller: _form,
        borderConfig: WFormBorderConfig.standard(radius: 12),
        fieldStyle: const WFormFieldStyle(
          height: 52,
          containerPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '一个页面只 import package:w_tools/w.dart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '聚合包适合快速体验；生产项目建议按需依赖子包。',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            WFormTextField(
              name: 'nickname',
              label: '昵称',
              message: '请输入昵称',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入昵称';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const WFormDropdown<String>(
              name: 'city',
              label: '城市',
              initialValue: 'HK',
              items: {
                'HK': '香港',
                'SZ': '深圳',
                'SH': '上海',
              },
            ),
            const SizedBox(height: 24),
            WButton(
              label: '提交',
              onTap: _submit,
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('提交结果'),
                  subtitle: Text(_result!),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              '异步区块',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: WAsyncView<String>(
                state: _async.state,
                onRetry: _async.load,
                readyBuilder: (context, value) => Center(
                  child: Text(value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
