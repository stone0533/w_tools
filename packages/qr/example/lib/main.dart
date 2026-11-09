import 'dart:async';

import 'package:flutter/material.dart';
import 'package:w_tools_qr/w_tools_qr.dart';

void main() {
  runApp(const QrExampleApp());
}

class QrExampleApp extends StatelessWidget {
  const QrExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_qr 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8B5CF6),
        useMaterial3: true,
      ),
      home: const QrScannerPage(),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  /// 控制器由页面创建并持有，跨平台视图重建保持不变
  final WQrController _controller = WQrController();

  StreamSubscription<Barcode>? _streamSubscription;
  String? _result;
  int _streamCount = 0;
  bool _torchOn = false;
  bool _continuous = false;
  bool _showOverlay = true;
  bool _qrOnly = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    // 广播流与控制器同生命周期：只需订阅一次
    _streamSubscription = _controller.scannedDataStream.listen((barcode) {
      final code = barcode.code;
      if (code == null || code.isEmpty || !mounted) return;
      setState(() => _streamCount++);
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onScanned(WQrScanResult result) {
    setState(() => _result = result.code);
  }

  Future<void> _restart() async {
    setState(() => _result = null);
    await _controller.restart();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleFlash();
      final status = await _controller.getFlashStatus();
      if (mounted) setState(() => _torchOn = status ?? false);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  Future<void> _flip() async {
    try {
      await _controller.flipCamera();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  void _report(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('相机操作失败：$error')),
    );
  }

  void _onPermissionDenied() {
    if (!mounted) return;
    setState(() => _permissionDenied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('二维码扫描'),
        actions: [
          IconButton(
            tooltip: '切换闪光灯',
            onPressed: _toggleTorch,
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: '翻转摄像头',
            onPressed: _flip,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WQrView(
              controller: _controller,
              onScanned: _onScanned,
              onPermissionDenied: _onPermissionDenied,
              onError: _report,
              scanOnce: !_continuous,
              scanInterval: const Duration(seconds: 1),
              formatsAllowed: _qrOnly
                  ? const <BarcodeFormat>[BarcodeFormat.qrcode]
                  : const <BarcodeFormat>[],
              style: WQrOverlayStyle(
                isVisible: _showOverlay,
                borderWidth: 4,
                cutOutWidth: 240,
                cutOutHeight: 240,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FilterChip(
                      label: const Text('连续扫描'),
                      selected: _continuous,
                      onSelected: (value) => setState(() => _continuous = value),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('扫描框'),
                      selected: _showOverlay,
                      onSelected: (value) => setState(() => _showOverlay = value),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('仅二维码'),
                      selected: _qrOnly,
                      onSelected: (value) => setState(() => _qrOnly = value),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '切换「仅二维码」会重启相机（平台视图重建），扫描状态随之重置',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            top: 76,
            left: 12,
            right: 12,
            child: Text(
              '广播流扫描次数：$_streamCount',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_result != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 32,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '扫描结果',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _restart,
                        child: const Text('继续扫描'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_permissionDenied)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_outlined, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            '需要相机权限',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '请在系统设置中允许相机权限后返回本页',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => _permissionDenied = false),
                            child: const Text('我已授权'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
