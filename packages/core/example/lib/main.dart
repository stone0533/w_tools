import 'package:flutter/material.dart';
import 'package:w_tools_core/w_tools_core.dart';

void main() {
  runApp(const CoreExampleApp());
}

class CoreExampleApp extends StatelessWidget {
  const CoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_core 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF14B8A6),
        useMaterial3: true,
      ),
      home: const CoreDemoPage(),
    );
  }
}

class CoreDemoPage extends StatefulWidget {
  const CoreDemoPage({super.key});

  @override
  State<CoreDemoPage> createState() => _CoreDemoPageState();
}

class _CoreDemoPageState extends State<CoreDemoPage> {
  final _emailController = TextEditingController();
  final _debounceController = TextEditingController();
  final _tokenController = TextEditingController(text: 'demo-token');

  late final WCountdown _countdown;
  late final WCancellableAction _debounced;

  String _emailResult = '输入邮箱后点击校验';
  String _cryptoResult = '点击生成哈希与加密结果';
  String _storageResult = '尚未读取 token';
  String _counterResult = '尚未读写计数';
  String _debounceResult = '输入内容观察防抖';
  int _remaining = 0;
  int _debounceCount = 0;
  bool _storageReady = false;

  String? _key;
  String? _iv;

  @override
  void initState() {
    super.initState();
    _countdown = WCountdown(
      callback: (value) {
        if (mounted) setState(() => _remaining = value);
      },
      onComplete: (value) {
        if (mounted) setState(() => _remaining = value);
      },
    );
    _debounced = WUx().debounce(
      () {
        if (!mounted) return;
        setState(() {
          _debounceCount++;
          _debounceResult = '防抖触发：${_debounceController.text}';
        });
      },
      duration: 300,
    );
    _prepareStorage();
  }

  Future<void> _prepareStorage() async {
    await WStorage.init();
    if (!mounted) return;
    setState(() => _storageReady = true);
  }

  @override
  void dispose() {
    _debounced.cancel();
    _countdown.dispose();
    _emailController.dispose();
    _debounceController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    setState(() {
      _emailResult = WValidator.isValidEmail(email) ? '邮箱有效：$email' : '邮箱无效：$email';
    });
  }

  void _runCrypto() {
    final text = _emailController.text.isEmpty ? 'demo' : _emailController.text;
    final key = _key ??= WEncrypt.generateKey();
    final iv = _iv ??= WEncrypt.generateIv();
    final encrypted = WEncrypt.aesEncrypt(text, keyStr: key, ivStr: iv);
    final decrypted = WEncrypt.aesDecrypt(encrypted, keyStr: key);
    setState(() {
      _cryptoResult =
          'sha256: ${WHash.sha256(text)}\n'
          'encrypted: $encrypted\n'
          'decrypted: $decrypted';
    });
  }

  Future<void> _saveToken() async {
    await WToken.saveToken(_tokenController.text);
    if (!mounted) return;
    setState(() => _storageResult = '已保存 token');
  }

  void _readToken() {
    final token = WToken.getToken();
    setState(() => _storageResult = '读取 token：${token ?? 'null'}');
  }

  Future<void> _saveCounter() async {
    final current = WStorage.getInt('demo_counter', defaultValue: 0) ?? 0;
    final next = current + 1;
    await WStorage.setInt('demo_counter', next);
    if (!mounted) return;
    setState(() => _counterResult = '已保存计数：$next');
  }

  void _readCounter() {
    final value = WStorage.getInt('demo_counter');
    setState(() => _counterResult = '读取计数：${value ?? 'null'}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('w_tools_core 示例')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('平台：${WPlatform.platformType.name}'),
            Text(
              '平台值：${WPlatform.getPlatformValue(
                android: 'Android',
                ios: 'iOS',
                web: 'Web',
                desktop: 'Desktop',
                fallback: 'Other',
              )}',
            ),
            const SizedBox(height: 16),
            const Text('校验', style: TextStyle(fontWeight: FontWeight.w600)),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱 / 待处理文本',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: _validateEmail, child: const Text('校验邮箱')),
                OutlinedButton(onPressed: _runCrypto, child: const Text('哈希 + AES')),
              ],
            ),
            const SizedBox(height: 8),
            Text(_emailResult),
            const SizedBox(height: 8),
            SelectableText(
              _cryptoResult,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            const Divider(height: 32),
            const Text('存储', style: TextStyle(fontWeight: FontWeight.w600)),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _storageReady ? _saveToken : null,
                  child: const Text('保存 token'),
                ),
                OutlinedButton(
                  onPressed: _storageReady ? _readToken : null,
                  child: const Text('读取 token'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_storageResult),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _storageReady ? _saveCounter : null,
                  child: const Text('计数 +1'),
                ),
                OutlinedButton(
                  onPressed: _storageReady ? _readCounter : null,
                  child: const Text('读取计数'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_counterResult),
            const Divider(height: 32),
            const Text('防抖', style: TextStyle(fontWeight: FontWeight.w600)),
            TextField(
              controller: _debounceController,
              decoration: const InputDecoration(
                labelText: '输入内容',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _debounced(),
            ),
            const SizedBox(height: 8),
            Text('$_debounceResult（触发 $_debounceCount 次）'),
            const Divider(height: 32),
            const Text('倒计时', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('剩余：$_remaining 秒'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                _countdown.start(second: 5);
                setState(() => _remaining = _countdown.remainingSeconds);
              },
              child: const Text('开始 5 秒倒计时'),
            ),
          ],
        ),
      ),
    );
  }
}
