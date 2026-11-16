import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' show QrScannerOverlayShape, QRView;
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

/// 模拟扫描到一个条码
Future<void> _emitBarcode(
  WidgetTester tester,
  String? code, {
  List<int>? rawBytes,
}) {
  return _emitPlatformCall(
    tester,
    MethodCall('onRecognizeQR', {
      'code': code,
      'type': 'QR_CODE',
      if (rawBytes != null) 'rawBytes': Uint8List.fromList(rawBytes),
    }),
  );
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

/// 编码一个成功回包
ByteData? _success([Object? value]) => const StandardMethodCodec().encodeSuccessEnvelope(value);

/// 创建控制器并在用例结束时释放
WQrController _newController() {
  final controller = WQrController();
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('WQrOverlayStyle — 纯 Dart', () {
    test('默认构造参数', () {
      const style = WQrOverlayStyle();
      expect(style.borderColor, Colors.red);
      expect(style.margin, EdgeInsets.zero);
      expect(style.borderWidth, 3.0);
      expect(style.overlayColor, const Color.fromRGBO(0, 0, 0, 0.5));
      expect(style.borderRadius, 0);
      expect(style.borderLength, 40);
      expect(style.cutOutWidth, 250);
      expect(style.cutOutHeight, 250);
      expect(style.cutOutBottomOffset, 0);
    });

    test('cutOutHeight 缺省时回退到 cutOutWidth', () {
      expect(const WQrOverlayStyle(cutOutWidth: 300).cutOutHeight, 300);
      expect(
        const WQrOverlayStyle(cutOutWidth: 300, cutOutHeight: 200).cutOutHeight,
        200,
      );
    });

    test('非法尺寸在 debug 下断言失败', () {
      expect(
        () => WQrOverlayStyle(borderWidth: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WQrOverlayStyle(borderLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WQrOverlayStyle(cutOutWidth: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WQrOverlayStyle(cutOutHeight: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('自定义扫描框与颜色', () {
      const style = WQrOverlayStyle(
        borderColor: Colors.blue,
        margin: EdgeInsets.all(8),
        borderWidth: 5,
        borderRadius: 10,
        borderLength: 60,
        cutOutWidth: 300,
        cutOutHeight: 200,
        cutOutBottomOffset: 20,
      );
      expect(style.borderColor, Colors.blue);
      expect(style.margin, const EdgeInsets.all(8));
      expect(style.borderWidth, 5);
      expect(style.borderRadius, 10);
      expect(style.borderLength, 60);
      expect(style.cutOutHeight, 200);
      expect(style.cutOutBottomOffset, 20);
    });
  });

  group('WQrController — 未挂载', () {
    test('相机方法与 restart 都抛 StateError', () async {
      final controller = _newController();

      expect(controller.isAttached, isFalse);
      expect(controller.cameraFacing, isNull);
      expect(() => controller.pauseCamera(), throwsStateError);
      expect(() => controller.resumeCamera(), throwsStateError);
      expect(() => controller.flipCamera(), throwsStateError);
      expect(() => controller.toggleFlash(), throwsStateError);
      expect(() => controller.getFlashStatus(), throwsStateError);
      await expectLater(controller.restart(), throwsStateError);
    });
  });

  group('WQrView — 构造 & 渲染（Tier 1）', () {
    testWidgets('默认绘制扫描框', (tester) async {
      final controller = _newController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WQrView(controller: controller)),
        ),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      final overlay = qrView.overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.red);
      expect(overlay.borderWidth, 3);
      expect(overlay.cutOutWidth, 250);
      expect(qrView.overlayMargin, EdgeInsets.zero);
      expect(qrView.cameraFacing, CameraFacing.back);
      expect(qrView.formatsAllowed, isEmpty);
    });

    testWidgets('style 生效：颜色 / 外边距 / 几何', (tester) async {
      final controller = _newController();
      const style = WQrOverlayStyle(
        borderColor: Colors.blue,
        margin: EdgeInsets.all(12),
        borderWidth: 8,
        borderRadius: 6,
        borderLength: 30,
        cutOutWidth: 240,
        cutOutHeight: 200,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(controller: controller, style: style),
          ),
        ),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      final overlay = qrView.overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.blue);
      expect(overlay.borderWidth, 8);
      expect(overlay.borderRadius, 6);
      expect(overlay.cutOutWidth, 240);
      expect(overlay.cutOutHeight, 200);
      expect(qrView.overlayMargin, const EdgeInsets.all(12));
    });

    testWidgets('style 为 null 时不绘制扫描框', (tester) async {
      final controller = _newController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WQrView(controller: controller, style: null)),
        ),
      );

      expect(tester.widget<QRView>(find.byType(QRView)).overlay, isNull);
    });
  });

  group('WQrView — 平台集成测试（Tier 3 MethodChannel mock）', () {
    final platformCalls = <String>[];
    var failPauseCamera = false;

    setUp(() {
      platformCalls.clear();
      failPauseCamera = false;
      _activeViewChannel = null;

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
          switch (method) {
            case 'flipCamera':
              return Future<ByteData?>.value(
                _success(CameraFacing.front.index),
              );
            case 'getFlashInfo':
              return Future<ByteData?>.value(_success(true));
            case 'toggleFlash':
              return Future<ByteData?>.value(_success(true));
            default:
              return Future<ByteData?>.value(_success());
          }
        }
        if (handler != null) {
          return handler(message);
        }
        return null;
      };

      // 保证每个用例都从「前台」状态开始；放在 mock 之后，避免上一个用例残留的
      // 平台视图 observer 在无 handler 时抛 MissingPluginException。
      TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
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
      WQrController? controller,
      Key? key,
      void Function(WQrScanResult result)? onScanned,
      void Function(WQrController controller)? onControllerReady,
      void Function(Object error, StackTrace stackTrace)? onError,
      VoidCallback? onPermissionDenied,
      WQrOverlayStyle? style = const WQrOverlayStyle(),
      bool scanOnce = true,
      Duration scanThrottle = Duration.zero,
      CameraFacing cameraFacing = CameraFacing.back,
      List<BarcodeFormat> formatsAllowed = const <BarcodeFormat>[],
    }) async {
      final target = controller ?? _newController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(
              key: key,
              controller: target,
              style: style,
              onScanned: onScanned,
              onControllerReady: onControllerReady,
              onError: onError,
              onPermissionDenied: onPermissionDenied,
              scanOnce: scanOnce,
              scanThrottle: scanThrottle,
              cameraFacing: cameraFacing,
              formatsAllowed: formatsAllowed,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('onControllerReady 拿到同一实例，相机就绪', (tester) async {
      final controller = _newController();
      WQrController? ready;

      await pumpQrView(
        tester,
        controller: controller,
        onControllerReady: (c) => ready = c,
      );

      expect(ready, isNotNull);
      expect(identical(ready, controller), isTrue);
      expect(controller.isAttached, isTrue);
      expect(controller.cameraFacing, CameraFacing.back);
      expect(controller.scannedDataStream.isBroadcast, isTrue);
    });

    testWidgets('默认单次：回调一次、结果结构化并暂停相机', (tester) async {
      final results = <WQrScanResult>[];
      await pumpQrView(tester, onScanned: results.add);

      await _emitBarcode(tester, 'hello', rawBytes: [1, 2, 3]);
      await _emitBarcode(tester, 'again');

      final result = results.single;
      expect(result.code, 'hello');
      expect(result.format, BarcodeFormat.qrcode);
      expect(result.rawBytes, [1, 2, 3]);
      expect(result.toString(), contains('hello'));
      expect(platformCalls.where((call) => call == 'pauseCamera').length, 1);
    });

    testWidgets('scanOnce 为 false：持续回调且不暂停相机', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'first');
      await _emitBarcode(tester, 'second');

      expect(scanned, ['first', 'second']);
      expect(platformCalls, isNot(contains('pauseCamera')));
    });

    testWidgets('scanOnce 从 true 切到 false：恢复相机并继续回调', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      platformCalls.clear();
      await pumpQrView(
        tester,
        controller: controller,
        scanOnce: false,
        onScanned: (result) => scanned.add(result.code),
      );
      await tester.pump();
      expect(platformCalls, contains('resumeCamera'));

      await _emitBarcode(tester, 'second');
      await _emitBarcode(tester, 'third');
      expect(scanned, ['first', 'second', 'third']);
    });

    testWidgets('空内容与 null 内容都忽略', (tester) async {
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (result) => scanned.add(result.code));

      await _emitBarcode(tester, '');
      await _emitBarcode(tester, null);

      expect(scanned, isEmpty);
      expect(platformCalls, isNot(contains('pauseCamera')));
    });

    testWidgets('不传 onScanned 也在首码后暂停，广播流照常推送', (tester) async {
      final controller = _newController();
      final codes = <String?>[];
      controller.scannedDataStream.listen((barcode) => codes.add(barcode.code));

      await pumpQrView(tester, controller: controller);

      await _emitBarcode(tester, 'one');
      await _emitBarcode(tester, 'two');

      expect(codes, ['one', 'two']);
      expect(platformCalls.where((call) => call == 'pauseCamera').length, 1);
    });

    testWidgets('restart 后可再次扫码', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await controller.restart();
      await tester.pump();

      await _emitBarcode(tester, 'second');
      expect(scanned, ['first', 'second']);
      expect(platformCalls, contains('resumeCamera'));
    });

    testWidgets('在 onScanned 内调用 restart 时暂停与恢复顺序正确', (tester) async {
      final controller = _newController();
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (_) => controller.restart(),
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

    testWidgets('广播流监听内 restart 不会被单次暂停覆盖', (tester) async {
      final controller = _newController();
      final codes = <String?>[];
      controller.scannedDataStream.listen((barcode) {
        codes.add(barcode.code);
        controller.restart();
      });
      await pumpQrView(tester, controller: controller, onScanned: (_) {});

      platformCalls.clear();
      await _emitBarcode(tester, 'first');
      await tester.pump();

      expect(codes, ['first']);
      expect(platformCalls, contains('pauseCamera'));
      expect(platformCalls.last, 'resumeCamera');
    });

    testWidgets('广播流订阅跨平台视图重建保持不变', (tester) async {
      final controller = _newController();
      final codes = <String?>[];
      controller.scannedDataStream.listen((barcode) => codes.add(barcode.code));
      await pumpQrView(tester, controller: controller);

      await _emitBarcode(tester, 'before');
      expect(codes, ['before']);

      await pumpQrView(
        tester,
        controller: controller,
        formatsAllowed: const <BarcodeFormat>[BarcodeFormat.qrcode],
      );
      await _emitBarcode(tester, 'after');
      expect(codes, ['before', 'after']);
    });

    testWidgets('广播流支持多监听，且与 onScanned 共存', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (result) => scanned.add(result.code),
      );

      final first = <String>[];
      final second = <String>[];
      controller.scannedDataStream.listen((b) => first.add(b.code ?? ''));
      controller.scannedDataStream.listen((b) => second.add(b.code ?? ''));

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

    testWidgets('无权限回调只上报一次，重新授权后可再次上报', (tester) async {
      var deniedCount = 0;
      await pumpQrView(
        tester,
        onScanned: (_) {},
        onPermissionDenied: () => deniedCount++,
      );

      await _emitPlatformCall(
        tester,
        const MethodCall('onPermissionSet', false),
      );
      await _emitPlatformCall(
        tester,
        const MethodCall('onPermissionSet', false),
      );
      expect(deniedCount, 1);

      await _emitPlatformCall(tester, const MethodCall('onPermissionSet', true));
      await _emitPlatformCall(
        tester,
        const MethodCall('onPermissionSet', false),
      );
      expect(deniedCount, 2);
    });

    testWidgets('应用进入后台暂停相机，回到前台后恢复', (tester) async {
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
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
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
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

    testWidgets('restart 在后台不恢复相机，回到前台后才恢复', (tester) async {
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      final controller = _newController();
      await pumpQrView(tester, controller: controller, onScanned: (_) {});

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      platformCalls.clear();

      await controller.restart();
      await tester.pump();
      expect(platformCalls, isNot(contains('resumeCamera')));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(platformCalls, contains('resumeCamera'));
    });

    testWidgets('onError 自身抛异常会被忽略', (tester) async {
      await pumpQrView(
        tester,
        onScanned: (_) => throw StateError('callback failed'),
        onError: (_, _) => throw StateError('handler failed'),
      );

      await _emitBarcode(tester, 'boom');

      expect(tester.takeException(), isNull);
    });

    testWidgets('cameraFacing 变化会重建平台视图并重置扫描状态', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (r) => scanned.add(r.code),
      );
      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await pumpQrView(
        tester,
        controller: controller,
        cameraFacing: CameraFacing.front,
        onScanned: (r) => scanned.add(r.code),
      );
      await _emitBarcode(tester, 'first');

      expect(scanned, ['first', 'first']);
      expect(controller.cameraFacing, CameraFacing.front);
      expect(
        tester.widget<QRView>(find.byType(QRView)).cameraFacing,
        CameraFacing.front,
      );
    });

    testWidgets('formatsAllowed 变化会重建平台视图并重置扫描状态', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (r) => scanned.add(r.code),
      );
      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await pumpQrView(
        tester,
        controller: controller,
        formatsAllowed: const <BarcodeFormat>[BarcodeFormat.qrcode],
        onScanned: (r) => scanned.add(r.code),
      );
      await _emitBarcode(tester, 'first');

      expect(scanned, ['first', 'first']);
      expect(
        tester.widget<QRView>(find.byType(QRView)).formatsAllowed,
        [BarcodeFormat.qrcode],
      );
    });

    testWidgets('替换 controller 时新控制器接管、旧控制器解绑', (tester) async {
      final first = _newController();
      final second = _newController();
      final scanned = <String>[];

      await pumpQrView(
        tester,
        controller: first,
        onScanned: (r) => scanned.add(r.code),
      );
      expect(first.isAttached, isTrue);

      await pumpQrView(
        tester,
        controller: second,
        onScanned: (r) => scanned.add(r.code),
      );
      final oldCodes = <String?>[];
      first.scannedDataStream.listen((barcode) => oldCodes.add(barcode.code));

      expect(first.isAttached, isFalse);
      expect(second.isAttached, isTrue);
      expect(() => first.pauseCamera(), throwsStateError);

      await _emitBarcode(tester, 'second');
      expect(scanned, ['second']);
      expect(oldCodes, isEmpty);
    });

    testWidgets('scanThrottle 内相同内容只回调一次', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        scanThrottle: const Duration(seconds: 5),
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'other');
      await _emitBarcode(tester, 'other');

      expect(scanned, ['same', 'other']);
    });

    testWidgets('scanThrottle 为 0 时关闭节流', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'same');

      expect(scanned, ['same', 'same']);
    });

    testWidgets('onScanned 抛异常时通过 onError 上报，并回滚单次锁定', (tester) async {
      final errors = <Object>[];
      var calls = 0;
      await pumpQrView(
        tester,
        onScanned: (_) {
          calls++;
          throw StateError('callback failed');
        },
        onError: (error, _) => errors.add(error),
      );

      await _emitBarcode(tester, 'boom');

      expect(calls, 1);
      expect(errors.single, isA<StateError>());
      // 回滚：恢复相机，下一次扫码仍可回调
      expect(platformCalls, contains('resumeCamera'));
      await _emitBarcode(tester, 'retry');
      expect(calls, 2);
    });

    testWidgets('onControllerReady 抛异常时通过 onError 上报', (tester) async {
      final errors = <Object>[];
      await pumpQrView(
        tester,
        onControllerReady: (_) => throw StateError('callback failed'),
        onError: (error, _) => errors.add(error),
      );

      expect(errors.single, isA<StateError>());
    });

    testWidgets('控制器相机方法转发到平台', (tester) async {
      final controller = _newController();
      await pumpQrView(tester, controller: controller, onScanned: (_) {});

      expect(controller.isAttached, isTrue);
      await controller.pauseCamera();
      await controller.resumeCamera();
      final facing = await controller.flipCamera();
      expect(facing, CameraFacing.front);
      expect(controller.cameraFacing, CameraFacing.front);
      expect(await controller.getFlashStatus(), isTrue);
      await controller.toggleFlash();

      expect(
        platformCalls,
        containsAll(<String>[
          'pauseCamera',
          'resumeCamera',
          'flipCamera',
          'getFlashInfo',
          'toggleFlash',
        ]),
      );
    });

    testWidgets('dispose 后不再回调，也不抛异常', (tester) async {
      final controller = _newController();
      final scanned = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onScanned: (r) => scanned.add(r.code),
      );
      final staleChannel = _activeViewChannel;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('done'))),
      );
      await tester.pump();

      expect(controller.isAttached, isFalse);
      // 旧平台视图的通道即使还有事件，也不应再回调
      expect(staleChannel, isNotNull);
      final data = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onRecognizeQR', {'code': 'late', 'type': 'QR_CODE'}),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        staleChannel!,
        data,
        (_) {},
      );
      await tester.pump();

      expect(scanned, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
