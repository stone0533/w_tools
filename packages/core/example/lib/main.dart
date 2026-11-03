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
  late final WDebounce _debounced;
  late final WThrottle _throttled;

  String _emailResult = '输入邮箱后点击校验';
  String _cryptoResult = '点击生成哈希与加密结果';
  String _storageResult = '尚未读取 token';
  String _counterResult = '尚未读写计数';
  String _extraResult = '更多工具尚未运行';
  String _mapResult = '尚未排序 Map';
  String _objectResult = '尚未读写对象';
  String _debounceResult = '输入内容观察防抖';
  int _remaining = 0;
  int _debounceCount = 0;
  int _throttleCount = 0;
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
    _debounced = WDebounce(
      () {
        if (!mounted) return;
        setState(() {
          _debounceCount++;
          _debounceResult = '防抖触发：${_debounceController.text}';
        });
      },
      duration: const Duration(milliseconds: 300),
    );
    _throttled = WThrottle(
      () {
        if (!mounted) return;
        setState(() => _throttleCount++);
      },
      duration: const Duration(milliseconds: 500),
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
    _throttled.cancel();
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

  void _runRegex() {
    final match = WRegExp.firstEmailMatch(_emailController.text);
    setState(() {
      _extraResult = match == null ? 'regex: 无匹配' : 'regex: ${match.group(0)}';
    });
  }

  void _runBase64() {
    final source = _emailController.text.isEmpty ? 'w_tools_core' : _emailController.text;
    final encoded = WEncrypt.base64Encode(source);
    final decoded = WEncrypt.base64Decode(encoded);
    setState(() {
      _extraResult = 'base64: $encoded\ndecoded: $decoded';
    });
  }

  void _writeLog() {
    WLogger.i('w_tools_core example log');
    setState(() => _extraResult = 'WLogger.i 已写入控制台');
  }

  void _sortMap() {
    final sorted = <String, int>{'b': 2, 'c': 3, 'a': 1}.sortedByKeys();
    setState(() => _mapResult = 'sortedByKeys: $sorted');
  }

  Future<void> _saveObject() async {
    await WStorage.setObject('demo_object', {'name': 'w_tools', 'version': 2});
    if (!mounted) return;
    setState(() => _objectResult = '对象已保存');
  }

  void _readObject() {
    final value = WStorage.getObject<Map>('demo_object');
    setState(() => _objectResult = '对象：$value');
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
            const Text('更多工具', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: _runRegex, child: const Text('正则匹配')),
                OutlinedButton(onPressed: _runBase64, child: const Text('Base64 往返')),
                OutlinedButton(onPressed: _writeLog, child: const Text('写日志')),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              _extraResult,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: _sortMap, child: const Text('Map 排序')),
                OutlinedButton(
                  onPressed: _throttled.call,
                  child: Text('节流点击（$_throttleCount）'),
                ),
                OutlinedButton(
                  onPressed: _storageReady ? _saveObject : null,
                  child: const Text('保存对象'),
                ),
                OutlinedButton(
                  onPressed: _storageReady ? _readObject : null,
                  child: const Text('读取对象'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_mapResult),
            Text(_objectResult),
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
