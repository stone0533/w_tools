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
Future<void> _emitBarcode(WidgetTester tester, String? code) {
  return _emitPlatformCall(
    tester,
    MethodCall('onRecognizeQR', {'code': code, 'type': 'QR_CODE'}),
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

void main() {
  group('WQrOverlayStyle — 纯 Dart', () {
    test('默认构造参数', () {
      const style = WQrOverlayStyle();
      expect(style.isVisible, isTrue);
      expect(style.borderColor, Colors.red);
      expect(style.successColor, Colors.green);
      expect(style.margin, EdgeInsets.zero);
      expect(style.borderWidth, 3.0);
      expect(style.overlayColor, const Color.fromRGBO(0, 0, 0, 0.5));
      expect(style.borderRadius, 0);
      expect(style.borderLength, 40);
      expect(style.cutOutWidth, 250);
      expect(style.cutOutHeight, 250);
      expect(style.cutOutBottomOffset, 0);
    });

    test('自定义扫描框与颜色', () {
      const style = WQrOverlayStyle(
        isVisible: false,
        borderColor: Colors.blue,
        successColor: Colors.amber,
        margin: EdgeInsets.all(8),
        borderWidth: 5,
        borderRadius: 10,
        borderLength: 60,
        cutOutWidth: 300,
        cutOutHeight: 200,
        cutOutBottomOffset: 20,
      );
      expect(style.isVisible, isFalse);
      expect(style.borderColor, Colors.blue);
      expect(style.successColor, Colors.amber);
      expect(style.borderWidth, 5);
      expect(style.cutOutHeight, 200);
    });

    test('值相等与 hashCode', () {
      expect(
        const WQrOverlayStyle(borderWidth: 4),
        const WQrOverlayStyle(borderWidth: 4),
      );
      expect(
        const WQrOverlayStyle(borderWidth: 4).hashCode,
        const WQrOverlayStyle(borderWidth: 4).hashCode,
      );
      expect(
        const WQrOverlayStyle(borderWidth: 4),
        isNot(const WQrOverlayStyle(borderWidth: 5)),
      );
      expect(
        const WQrOverlayStyle(isVisible: false),
        isNot(const WQrOverlayStyle()),
      );
    });

    test('非法尺寸在 debug 下断言失败', () {
      expect(
        () => WQrOverlayStyle(cutOutWidth: 60), // borderLength 40 > 30 + 6
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WQrOverlayStyle(cutOutWidth: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WQrOverlayStyle(borderWidth: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('WQrView 所有回调都可省略', () {
    expect(const WQrView(), isA<WQrView>());
    expect(const WQrView(scanOnce: true), isA<WQrView>());
    // 只给 onControllerReady 也必须能构造（旧版这里会断言失败）
    expect(WQrView(onControllerReady: (_) {}), isA<WQrView>());
  });

  test('未挂载的 WQrController：相机方法抛 StateError，restart 是 no-op', () async {
    final controller = WQrController();
    addTearDown(controller.dispose);

    expect(controller.isAttached, isFalse);
    expect(controller.hasPermissions, isFalse);
    expect(controller.cameraFacing, isNull);
    expect(() => controller.pauseCamera(), throwsStateError);
    expect(() => controller.toggleFlash(), throwsStateError);
    await expectLater(controller.restart(), completes);
  });

  group('WQrView — 构造 & 渲染（Tier 1）', () {
    testWidgets('默认绘制扫描框', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WQrView())),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      final overlay = qrView.overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.red);
      expect(qrView.overlayMargin, EdgeInsets.zero);
      expect(qrView.cameraFacing, CameraFacing.back);
      expect(qrView.formatsAllowed, isEmpty);
    });

    testWidgets('style 生效：颜色 / 外边距 / 是否显示', (tester) async {
      const style = WQrOverlayStyle(
        borderColor: Colors.blue,
        successColor: Colors.amber,
        margin: EdgeInsets.all(12),
        borderWidth: 8,
        cutOutWidth: 240,
        cutOutHeight: 240,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WQrView(style: style)),
        ),
      );

      final qrView = tester.widget<QRView>(find.byType(QRView));
      final overlay = qrView.overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.blue);
      expect(overlay.borderWidth, 8);
      expect(overlay.cutOutWidth, 240);
      expect(qrView.overlayMargin, const EdgeInsets.all(12));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WQrView(style: WQrOverlayStyle(isVisible: false)),
          ),
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
          switch (method) {
            case 'getCameraInfo':
            case 'flipCamera':
              return Future<ByteData?>.value(
                _success(CameraFacing.front.index),
              );
            case 'getFlashInfo':
              return Future<ByteData?>.value(_success(true));
            case 'toggleFlash':
              return Future<ByteData?>.value(_success(true));
            case 'getSystemFeatures':
              return Future<ByteData?>.value(
                _success(<String, dynamic>{
                  'hasFlash': true,
                  'hasBackCamera': true,
                  'hasFrontCamera': true,
                }),
              );
            default:
              return Future<ByteData?>.value(_success());
          }
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
      WQrController? controller,
      Key? key,
      void Function(WQrScanResult result)? onScanned,
      void Function(WQrController controller)? onControllerReady,
      void Function(Object error, StackTrace stackTrace)? onError,
      VoidCallback? onPermissionDenied,
      WQrOverlayStyle style = const WQrOverlayStyle(),
      bool scanOnce = true,
      Duration scanInterval = Duration.zero,
      CameraFacing cameraFacing = CameraFacing.back,
      List<BarcodeFormat> formatsAllowed = const <BarcodeFormat>[],
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WQrView(
              key: key,
              controller: controller,
              style: style,
              onScanned: onScanned,
              onControllerReady: onControllerReady,
              onError: onError,
              onPermissionDenied: onPermissionDenied,
              scanOnce: scanOnce,
              scanInterval: scanInterval,
              cameraFacing: cameraFacing,
              formatsAllowed: formatsAllowed,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('传入 controller 时 onControllerReady 拿到同一实例', (tester) async {
      final controller = WQrController();
      addTearDown(controller.dispose);
      WQrController? ready;

      await pumpQrView(
        tester,
        controller: controller,
        onControllerReady: (c) => ready = c,
      );

      expect(ready, isNotNull);
      expect(identical(ready, controller), isTrue);
      expect(controller.scannedDataStream.isBroadcast, isTrue);
    });

    testWidgets('默认配置：扫码触发 onScanned 并暂停相机，且只触发一次', (tester) async {
      final scanned = <WQrScanResult>[];
      await pumpQrView(tester, onScanned: scanned.add);

      await _emitBarcode(tester, 'hello');

      expect(scanned.single.code, 'hello');
      expect(scanned.single.format, BarcodeFormat.qrcode);
      expect(scanned.single.timestamp, isA<DateTime>());
      expect(platformCalls, contains('pauseCamera'));

      // 扫描一次模式下，后续条码不再回调
      await _emitBarcode(tester, 'world');
      expect(scanned, hasLength(1));
    });

    testWidgets('单次扫码成功后边框切 successColor', (tester) async {
      const style = WQrOverlayStyle(
        borderColor: Colors.blue,
        successColor: Colors.amber,
      );
      await pumpQrView(tester, style: style, onScanned: (_) {});

      var overlay = tester.widget<QRView>(find.byType(QRView)).overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.blue);

      await _emitBarcode(tester, 'ok');

      overlay = tester.widget<QRView>(find.byType(QRView)).overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.amber);
    });

    testWidgets('scanOnce 为 false：持续回调且不暂停相机、不高亮', (tester) async {
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
      final overlay = tester.widget<QRView>(find.byType(QRView)).overlay as QrScannerOverlayShape;
      expect(overlay.borderColor, Colors.red);
    });

    testWidgets('空内容与 null 内容都忽略', (tester) async {
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (result) => scanned.add(result.code));

      await _emitBarcode(tester, '');
      await _emitBarcode(tester, null);

      expect(scanned, isEmpty);
      expect(platformCalls, isNot(contains('pauseCamera')));
    });

    testWidgets('不传 onScanned 时不会自动暂停相机，流仍持续推送', (tester) async {
      final controller = WQrController();
      addTearDown(controller.dispose);
      final codes = <String>[];
      await pumpQrView(
        tester,
        controller: controller,
        onControllerReady: (c) {
          c.scannedDataStream.listen((barcode) {
            final code = barcode.code;
            if (code != null) codes.add(code);
          });
        },
      );

      await _emitBarcode(tester, 'one');
      await _emitBarcode(tester, 'two');

      expect(codes, ['one', 'two']);
      expect(platformCalls, isNot(contains('pauseCamera')));
      expect(controller.hasPermissions, isFalse);
    });

    testWidgets('restart 后可再次扫码', (tester) async {
      final controller = WQrController();
      addTearDown(controller.dispose);
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
      final controller = WQrController();
      addTearDown(controller.dispose);
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

    testWidgets('广播流支持多监听，且与 onScanned 共存', (tester) async {
      final controller = WQrController();
      addTearDown(controller.dispose);
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
      final controller = WQrController();
      addTearDown(controller.dispose);
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
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (r) => scanned.add(r.code));
      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await pumpQrView(
        tester,
        cameraFacing: CameraFacing.front,
        onScanned: (r) => scanned.add(r.code),
      );
      await _emitBarcode(tester, 'first');

      expect(scanned, ['first', 'first']);
      expect(
        tester.widget<QRView>(find.byType(QRView)).cameraFacing,
        CameraFacing.front,
      );
    });

    testWidgets('formatsAllowed 变化会重建平台视图并重置扫描状态', (tester) async {
      final scanned = <String>[];
      await pumpQrView(tester, onScanned: (r) => scanned.add(r.code));
      await _emitBarcode(tester, 'first');
      expect(scanned, ['first']);

      await pumpQrView(
        tester,
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

    testWidgets('scanInterval 内相同内容只回调一次', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        scanInterval: const Duration(seconds: 5),
        onScanned: (result) => scanned.add(result.code),
      );

      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'same');
      await _emitBarcode(tester, 'other');
      await _emitBarcode(tester, 'other');

      expect(scanned, ['same', 'other']);
    });

    testWidgets('scanInterval 为 0 时关闭去重', (tester) async {
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

    testWidgets('大量不同条码不会因去重表容量被误判', (tester) async {
      final scanned = <String>[];
      await pumpQrView(
        tester,
        scanOnce: false,
        scanInterval: const Duration(seconds: 5),
        onScanned: (result) => scanned.add(result.code),
      );

      for (var index = 0; index < 80; index++) {
        await _emitBarcode(tester, 'code-$index');
      }

      expect(scanned, hasLength(80));
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
      // setInvert 只在 Android 上转发，这里临时覆盖平台并在用例结束前还原
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final controller = WQrController();
        addTearDown(controller.dispose);
        await pumpQrView(tester, controller: controller, onScanned: (_) {});

        expect(controller.isAttached, isTrue);
        await controller.pauseCamera();
        await controller.resumeCamera();
        // 插件的 stopCamera 只在 iOS 生效（其他平台 no-op），这里只验证不抛
        await controller.stopCamera();
        final facing = await controller.flipCamera();
        expect(facing, CameraFacing.front);
        expect(controller.cameraFacing, CameraFacing.front);
        expect(await controller.getCameraInfo(), CameraFacing.front);
        expect(await controller.getFlashStatus(), isTrue);
        await controller.toggleFlash();
        final features = await controller.getSystemFeatures();
        expect(features.hasFlash, isTrue);
        await controller.setInvert(true);

        expect(
          platformCalls,
          containsAll(<String>[
            'pauseCamera',
            'resumeCamera',
            'flipCamera',
            'getCameraInfo',
            'getFlashInfo',
            'toggleFlash',
            'getSystemFeatures',
            'invertScan',
          ]),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('dispose 后不再回调，也不抛异常', (tester) async {
      final controller = WQrController();
      addTearDown(controller.dispose);
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
