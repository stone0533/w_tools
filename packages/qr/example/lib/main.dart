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
  final _qrKey = GlobalKey<WQrViewState>();
  WQrController? _controller;
  StreamSubscription<Barcode>? _streamSubscription;
  String? _result;
  int _streamCount = 0;
  bool _torchOn = false;
  bool _continuous = false;
  bool _showOverlay = true;
  bool _qrOnly = true;

  void _onScanned(Barcode barcode) {
    setState(() => _result = barcode.code);
  }

  Future<void> _restart() async {
    setState(() => _result = null);
    await _qrKey.currentState?.restartScan();
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.toggleFlash();
      final status = await controller.getFlashStatus();
      if (mounted) setState(() => _torchOn = status ?? false);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  Future<void> _flip() async {
    try {
      await _controller?.flipCamera();
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
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
              key: _qrKey,
              onScanned: _onScanned,
              onQRViewCreated: (controller) {
                _controller = controller;
                _streamSubscription?.cancel();
                _streamSubscription = controller.scannedDataStream.listen(
                  (barcode) {
                    final code = barcode.code;
                    if (code == null || code.isEmpty || !mounted) return;
                    setState(() => _streamCount++);
                  },
                );
              },
              onError: _report,
              scanOnce: !_continuous,
              scanInterval: const Duration(seconds: 1),
              showOverlay: _showOverlay,
              formatsAllowed: _qrOnly
                  ? const <BarcodeFormat>[BarcodeFormat.qrcode]
                  : const <BarcodeFormat>[],
              noPermissionCallback: () {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('需要相机权限才能扫码')),
                );
              },
              overlay: const WQrViewOverlayShape(
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
            child: Row(
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
          ),
          Positioned(
            top: 60,
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
        ],
      ),
    );
  }
}
