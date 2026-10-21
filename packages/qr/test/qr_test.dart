import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' show QRView;
import 'package:w_tools_qr/w_tools_qr.dart';

/// 平台视图创建后，插件使用的二维码通道名前缀（实际 id 由测试框架分配）
const _viewChannelPrefix = 'net.touchcapture.qr.flutterqrplus/qrview_';

/// 当前测试中二维码平台视图的真实通道名
String? _activeViewChannel;

/// 模拟平台向 Dart 侧发送方法调用
Future<void> _emitPlatformCall(WidgetTester tester, MethodCall call) async {
  final channel = _activeViewChannel;
  if (channel == null) {
    throw StateError('二维码平台视图通道尚未创建');
  }
  final data = const StandardMethodCodec().encodeMethodCall(call);
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel,
    data,
    (_) {},
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

/// 从平台消息中解析方法名
String? _decodeMethodName(ByteData? message) {
  if (message == null) return null;
  try {
    return const StandardMethodCodec().decodeMethodCall(message).method;
  } catch (_) {
    return null;
  }
}

/// 模拟扫描到一个条码
Future<void> _emitBarcode(WidgetTester tester, String code) {
  return _emitPlatformCall(
    tester,
    MethodCall('onRecognizeQR', {'code': code, 'type': 'QR_CODE'}),
  );
}

void main() {
  group('WQrViewOverlayShape — 纯 Dart', () {
    test('默认构造参数', () {
      const overlay = WQrViewOverlayShape();
      expect(overlay.borderWidth, 3.0);
      expect(overlay.overlayColor, const Color.fromRGBO(0, 0, 0, 0.5));
      expect(overlay.borderRadius, 0);
      expect(overlay.borderLength, 40);
      expect(overlay.cutOutWidth, 250);
      expect(overlay.cutOutBottomOffset, 0);
      expect(overlay.cutOutHeight, 250);
    });

    test('自定义 cutOutHeight', () {
      const overlay = WQrViewOverlayShape(cutOutWidth: 200, cutOutHeight: 150);
      expect(overlay.cutOutWidth, 200);
      expect(overlay.cutOutHeight, 150);
    });

    test('全自定义参数', () {
      const overlay = WQrViewOverlayShape(
        borderWidth: 5,
        overlayColor: Colors.amber,
        borderRadius: 10,
        borderLength: 60,
        cutOutWidth: 300,
        cutOutHeight: 200,
        cutOutBottomOffset: 20,
      );
      expect(overlay.borderWidth, 5);
      expect(overlay.overlayColor, Colors.amber);
      expect(overlay.borderRadius, 10);
      expect(overlay.borderLength, 60);
      expect(overlay.cutOutWidth, 300);
      expect(overlay.cutOutHeight, 200);
      expect(overlay.cutOutBottomOffset, 20);
    });
  });

  group('WQrView — 构造 & 渲染（Tier 1）', () {
    testWidgets('默认构造 — onScanned 必填 + 默认参数', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(onScanned: (_) {}),
          ),
        ),
      );
      expect(find.byType(WQrView), findsOneWidget);
      final wqr = tester.widget<WQrView>(find.byType(WQrView));
      expect(wqr.borderColor, Colors.red);
      expect(wqr.checkedBorderColor, Colors.green);
      expect(wqr.showOverlay, isTrue);
      expect(wqr.scanOnce, isTrue);
      expect(wqr.cameraFacing, CameraFacing.back);
      expect(wqr.formatsAllowed, isEmpty);
      expect(wqr.overlayMargin, EdgeInsets.zero);
    });

    testWidgets('自定义 borderColor / checkedBorderColor / overlay', (tester) async {
      const overlay = WQrViewOverlayShape(borderWidth: 8);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(
              borderColor: Colors.blue,
              checkedBorderColor: Colors.green,
              overlay: overlay,
              onScanned: (_) {},
            ),
          ),
        ),
      );
      final wqr = tester.widget<WQrView>(find.byType(WQrView));
      expect(wqr.borderColor, Colors.blue);
      expect(wqr.checkedBorderColor, Colors.green);
      expect(wqr.overlay!.borderWidth, 8);
    });

    testWidgets('noPermissionCallback 参数传递', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(
              onScanned: (_) {},
              noPermissionCallback: () {},
            ),
          ),
        ),
      );
      final wqr = tester.widget<WQrView>(find.byType(WQrView));
      expect(wqr.noPermissionCallback, isNotNull);
    });

    testWidgets('默认绘制扫描框', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WQrView(onScanned: (_) {})),
        ),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      expect(qrView.overlay, isNotNull);
    });

    testWidgets('showOverlay 为 false 时全屏扫描', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(onScanned: (_) {}, showOverlay: false),
          ),
        ),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      expect(qrView.overlay, isNull);
    });
  });

  group('WQrView — 平台集成测试（Tier 3 MethodChannel mock）', () {
    final platformCalls = <String>[];
    var failPauseCamera = false;

    setUp(() {
      platformCalls.clear();
      failPauseCamera = false;
      _activeViewChannel = null;
      // 保证每个用例都从「前台」状态开始
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      // mock platform_views（真实 viewId 由测试框架分配）
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter/platform_views'),
        (call) async => call.method == 'create' ? 1 : null,
      );
      // 记录二维码通道的出站调用，同时捕获真实通道名
      messenger.allMessagesHandler = (channel, handler, message) {
        if (channel.startsWith(_viewChannelPrefix)) {
          _activeViewChannel = channel;
          final method = _decodeMethodName(message);
          if (method != null) {
            platformCalls.add(method);
          }
          if (method == 'pauseCamera' && failPauseCamera) {
            return Future<ByteData?>.value(
              const StandardMethodCodec().encodeErrorEnvelope(
                code: 'camera_error',
                message: 'simulated',
              ),
            );
          }
          return Future<ByteData?>.value(
            const StandardMethodCodec().encodeSuccessEnvelope(null),
          );
        }
        if (handler != null) {
          return handler(message);
        }
        return null;
      };
    });

    tearDown(() {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.allMessagesHandler = null;
      messenger.setMockMethodCallHandler(
        const MethodChannel('flutter/platform_views'),
        null,
      );
      _activeViewChannel = null;
    });

    Future<void> pumpQrView(
      WidgetTester tester, {
      Key? key,
      required void Function(Barcode) onScanned,
      void Function(WQrController)? onQRViewCreated,
      void Function(Object error, StackTrace stackTrace)? onError,
      bool scanOnce = true,
      Duration scanInterval = Duration.zero,
      bool showOverlay = true,
      CameraFacing cameraFacing = CameraFacing.back,
      List<BarcodeFormat> formatsAllowed = const <BarcodeFormat>[],
      VoidCallback? noPermissionCallback,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(
              key: key,
              onScanned: onScanned,
              onQRViewCreated: onQRViewCreated,
              onError: onError,
              scanOnce: scanOnce,
              scanInterval: scanInterval,
              showOverlay: showOverlay,
              cameraFacing: cameraFacing,
              formatsAllowed: formatsAllowed,
              noPermissionCallback: noPermissionCallback,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('onQRViewCreated 回调被触发 — controller 创建成功', (tester) async {
      WQrController? capturedController;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        onQRViewCreated: (ctrl) => capturedController = ctrl,
      );
      expect(capturedController, isNotNull);
    });

    testWidgets('controller 创建后 scannedDataStream 是可用的广播流', (tester) async {
      WQrController? capturedController;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        onQRViewCreated: (ctrl) => capturedController = ctrl,
      );
      expect(capturedController, isNotNull);
      expect(capturedController!.scannedDataStream, isA<Stream<Barcode>>());
      expect(capturedController!.scannedDataStream.isBroadcast, isTrue);
    });

    testWidgets('默认配置：扫码触发 onScanned 并暂停相机，且只触发一次', (tester) async {
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (data) => scanned.add(data.code ?? ''));

      await _emitBarcode(tester, 'hello');

      expect(scanned, ['hello']);
      expect(platformCalls, contains('pauseCamera'));

      // 扫描一次模式下，后续条码不再回调
      await _emitBarcode(tester, 'world');
      expect(scanned, ['hello']);
    });

    testWidgets('scanOnce 为 false：持续回调且不暂停相机', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        onScanned: (data) => scanned.add(data.code ?? ''),
      );

      await _emitBarcode(tester, 'first');
      await _emitBarcode(tester, 'second');

      expect(scanned, ['first', 'second']);
      expect(platformCalls, isNot(contains('pauseCamera')));
    });

    testWidgets('restartScan 后可再次扫码', (tester) async {
      final stateKey = GlobalKey<WQrViewState>();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        key: stateKey,
        onScanned: (data) => scanned.add(data.code ?? ''),
      );

      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await stateKey.currentState!.restartScan();
      await tester.pump();

      await _emitBarcode(tester, 'second');
      expect(scanned, ['first', 'second']);
      expect(platformCalls, contains('resumeCamera'));
    });

    testWidgets('广播流支持多监听，且与 onScanned 共存', (tester) async {
      WQrController? controller;
      final scanned = <String>[];
      await pumpQrView(
        tester,
        onScanned: (data) => scanned.add(data.code ?? ''),
        onQRViewCreated: (ctrl) => controller = ctrl,
      );

      final first = <String>[];
      final second = <String>[];
      controller!.scannedDataStream.listen((b) => first.add(b.code ?? ''));
      controller!.scannedDataStream.listen((b) => second.add(b.code ?? ''));

      await _emitBarcode(tester, 'multi');

      expect(scanned, ['multi']);
      expect(first, ['multi']);
      expect(second, ['multi']);
    });

    testWidgets('相机操作失败时通过 onError 上报', (tester) async {
      Object? reported;
      failPauseCamera = true;

      await pumpQrView(
        tester,
        onScanned: (_) {},
        onError: (error, _) => reported = error,
      );
      await _emitBarcode(tester, 'boom');
      await tester.pump();

      expect(reported, isA<CameraException>());
    });

    testWidgets('无相机权限时触发 noPermissionCallback', (tester) async {
      var deniedCount = 0;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        noPermissionCallback: () => deniedCount++,
      );

      await _emitPlatformCall(tester, const MethodCall('onPermissionSet', false));

      expect(deniedCount, 1);
    });

    testWidgets('应用进入后台暂停相机，回到前台后恢复', (tester) async {
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
      await pumpQrView(tester, onScanned: (_) {});

      platformCalls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(platformCalls, contains('pauseCamera'));

      platformCalls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(platformCalls, contains('resumeCamera'));
    });

    testWidgets('单次扫码完成后回到前台不会自动恢复相机', (tester) async {
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
      await pumpQrView(tester, onScanned: (_) {});
      await _emitBarcode(tester, 'done');

      platformCalls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(platformCalls, isNot(contains('resumeCamera')));
    });

    testWidgets('在 onScanned 内调用 restartScan 时暂停与恢复顺序正确', (tester) async {
      final stateKey = GlobalKey<WQrViewState>();
      await pumpQrView(
        tester,
        key: stateKey,
        onScanned: (_) {
          stateKey.currentState!.restartScan();
        },
      );

      platformCalls.clear();
      await _emitBarcode(tester, 'first');

      final pauseIndex = platformCalls.indexOf('pauseCamera');
      final resumeIndex = platformCalls.indexOf('resumeCamera');
      expect(pauseIndex, isNonNegative);
      expect(resumeIndex, greaterThan(pauseIndex));

      await _emitBarcode(tester, 'second');
      expect(platformCalls.where((call) => call == 'pauseCamera').length, 2);
    });

    testWidgets('cameraFacing 变化会重建平台视图并重置扫描状态', (tester) async {
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (data) => scanned.add(data.code ?? ''));
      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await pumpQrView(
        tester,
        cameraFacing: CameraFacing.front,
        onScanned: (data) => scanned.add(data.code ?? ''),
      );
      await _emitBarcode(tester, 'first');

      expect(scanned, ['first', 'first']);
    });

    testWidgets('scanInterval 内相同内容只回调一次', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        scanInterval: const Duration(seconds: 5),
        onScanned: (data) => scanned.add(data.code ?? ''),
      );

      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'other');
      await _emitBarcode(tester, 'other');

      expect(scanned, ['same', 'other']);
    });

    testWidgets('onScanned 抛异常时通过 onError 上报', (tester) async {
      Object? reported;
      await pumpQrView(
        tester,
        onScanned: (_) => throw StateError('callback failed'),
        onError: (error, _) => reported = error,
      );

      await _emitBarcode(tester, 'boom');

      expect(reported, isA<StateError>());
    });

    testWidgets('onQRViewCreated 抛异常时通过 onError 上报', (tester) async {
      Object? reported;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        onQRViewCreated: (_) => throw StateError('callback failed'),
        onError: (error, _) => reported = error,
      );

      expect(reported, isA<StateError>());
    });

    testWidgets('WQrView dispose 正常释放订阅', (tester) async {
      WQrController? capturedController;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        onQRViewCreated: (ctrl) => capturedController = ctrl,
      );
      expect(capturedController, isNotNull);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('done'))));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('WQrView 无 onQRViewCreated → 正常渲染不崩', (tester) async {
      await pumpQrView(tester, onScanned: (_) {});
      expect(find.byType(WQrView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
