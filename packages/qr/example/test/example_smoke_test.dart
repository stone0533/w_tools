import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_tools_qr/w_tools_qr.dart';
import 'package:w_tools_qr_example/main.dart';

const _viewChannelPrefix = 'net.touchcapture.qr.flutterqrplus/qrview_';

String? _activeViewChannel;

Future<void> _emitBarcode(WidgetTester tester, String code) async {
  final channel = _activeViewChannel;
  if (channel == null) throw StateError('二维码平台视图尚未创建');
  final data = const StandardMethodCodec().encodeMethodCall(
    MethodCall('onRecognizeQR', {'code': code, 'type': 'QR_CODE'}),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel,
    data,
    (_) {},
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUp(() {
    _activeViewChannel = null;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter/platform_views'),
      (call) async => call.method == 'create' ? 1 : null,
    );
    messenger.allMessagesHandler = (channel, handler, message) {
      if (channel.startsWith(_viewChannelPrefix)) {
        _activeViewChannel = channel;
        return Future<ByteData?>.value(
          const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      if (handler != null) return handler(message);
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

  testWidgets('连续扫描与扫描框开关生效', (tester) async {
    await tester.pumpWidget(const QrExampleApp());
    await tester.pump();

    await tester.tap(find.text('连续扫描'));
    await tester.pump();
    expect(tester.widget<WQrView>(find.byType(WQrView)).scanOnce, isFalse);

    await tester.tap(find.text('扫描框'));
    await tester.pump();
    expect(tester.widget<WQrView>(find.byType(WQrView)).showOverlay, isFalse);
  });

  testWidgets('扫码后展示结果并支持继续扫描', (tester) async {
    await tester.pumpWidget(const QrExampleApp());
    await tester.pump();
    expect(find.text('二维码扫描'), findsOneWidget);

    await _emitBarcode(tester, 'https://example.com');
    expect(find.text('扫描结果'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);

    await tester.tap(find.text('继续扫描'));
    await tester.pump();
    expect(find.text('扫描结果'), findsNothing);
  });
}
