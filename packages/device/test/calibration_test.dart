import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/w_tools_device.dart';

void main() {
  group('DeviceHub.parseWindow', () {
    test('解析 osascript 输出', () {
      final w = DeviceHub.parseWindow('4198, 101, 872, 1084\n');
      expect(w, isNotNull);
      expect(w!.x, 4198);
      expect(w.y, 101);
      expect(w.width, 872);
      expect(w.height, 1084);
    });

    test('格式不对返回 null', () {
      expect(DeviceHub.parseWindow('nope'), isNull);
      expect(DeviceHub.parseWindow('1, 2'), isNull);
    });
  });

  group('Simctl.parseDevices', () {
    test('解析 simctl --json', () {
      const json = '''
{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-4":[
  {"udid":"AAAA","name":"iPhone 17 Pro","state":"Booted"},
  {"udid":"BBBB","name":"iPhone 17","state":"Shutdown"}
]}}
''';
      final list = Simctl.parseDevices(json);
      expect(list.length, 2);
      expect(list.first.name, 'iPhone 17 Pro');
      expect(list.first.isBooted, isTrue);
      expect(list.first.runtimeLabel, 'iOS 26.4');
    });

    test('按 udid / 名称 / 模糊名解析', () {
      const a = SimDevice(udid: 'AAAA', name: 'iPhone 17 Pro', state: 'Booted', runtime: 'x');
      const b = SimDevice(udid: 'BBBB', name: 'iPad Air', state: 'Shutdown', runtime: 'x');
      expect(Simctl.resolve(const [a, b], 'BBBB')?.name, 'iPad Air');
      expect(Simctl.resolve(const [a, b], 'iPhone 17 Pro')?.udid, 'AAAA');
      expect(Simctl.resolve(const [a, b], 'ipad')?.udid, 'BBBB');
      expect(Simctl.resolve(const [a, b], null, bootedOnly: true)?.udid, 'AAAA');
    });
  });

  group('CalibrationStore.isFreshCalibration', () {
    const window = HubWindow(100, 50, 872, 1084);
    const rect = DRect(20, 100, 402, 874);

    Calibration cached({int width = 402, int height = 874}) => Calibration(
          window: window,
          deviceRect: rect,
          deviceWidth: width,
          deviceHeight: height,
          screenshotWidth: width * 3,
          screenshotHeight: height * 3,
          scale: 3,
        );

    test('窗口与设备尺寸都没变 → 命中', () {
      expect(
        CalibrationStore.isFreshCalibration(
          cached(),
          window,
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        isTrue,
      );
    });

    test('设备宽高变化（旋转 / 换机型）→ 失效', () {
      expect(
        CalibrationStore.isFreshCalibration(
          cached(),
          window,
          deviceWidth: 874,
          deviceHeight: 402,
        ),
        isFalse,
      );
      expect(
        CalibrationStore.isFreshCalibration(
          cached(),
          window,
          deviceHeight: 999,
        ),
        isFalse,
      );
    });

    test('--scale 变化导致逻辑分辨率变化 → 失效', () {
      // 同一张截图换了 scale，deviceWidth 会变，从而被判定失效
      expect(
        CalibrationStore.isFreshCalibration(
          cached(),
          window,
          deviceWidth: 134,
          deviceHeight: 291,
        ),
        isFalse,
      );
    });

    test('窗口移动 / 无缓存 → 失效', () {
      expect(CalibrationStore.isFreshCalibration(null, window), isFalse);
      expect(
        CalibrationStore.isFreshCalibration(
          cached(),
          const HubWindow(0, 0, 872, 1084),
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        isFalse,
      );
    });
  });

  group('CalibrationDetector', () {
    /// 造一张「白底 + 黑色机身块」的窗口图，块内是亮色屏幕。
    img.Image synthetic({
      required int width,
      required int height,
      required DRect bezel,
      required double inset,
    }) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      // 机身（黑）
      img.fillRect(
        image,
        x1: bezel.left.round(),
        y1: bezel.top.round(),
        x2: bezel.right.round(),
        y2: bezel.bottom.round(),
        color: img.ColorRgb8(10, 10, 10),
      );
      // 屏幕（亮）
      img.fillRect(
        image,
        x1: (bezel.left + inset).round(),
        y1: (bezel.top + inset).round(),
        x2: (bezel.right - inset).round(),
        y2: (bezel.bottom - inset).round(),
        color: img.ColorRgb8(240, 240, 240),
      );
      return image;
    }

    test('在合成图里找到设备屏幕矩形（1x）', () {
      const window = HubWindow(100, 50, 872, 1084);
      final image = synthetic(
        width: 872,
        height: 1084,
        bezel: const DRect(340, 80, 450, 950),
        inset: 14,
      );
      final cal = const CalibrationDetector().detect(
        image: image,
        window: window,
        scale: 1,
        deviceWidth: 402,
        deviceHeight: 874,
      );
      // 设备屏幕应接近机身内缩后的区域（允许几像素误差）
      expect(cal.deviceRect.left, closeTo(340, 25));
      expect(cal.deviceRect.top, closeTo(80, 25));
      expect(cal.deviceRect.width / cal.deviceRect.height, closeTo(402 / 874, 0.02));
    });

    test('映射：设备坐标 → 屏幕坐标（含窗口偏移）', () {
      const cal = Calibration(
        window: HubWindow(1000, 200, 872, 1084),
        deviceRect: DRect(300, 60, 430, 934),
        deviceWidth: 402,
        deviceHeight: 874,
      );
      final center = cal.toScreen(const DPoint(201, 437));
      expect(center.x, closeTo(1000 + 300 + 215, 0.5));
      expect(center.y, closeTo(200 + 60 + 467, 0.5));

      final topLeft = cal.toScreen(const DPoint(0, 0));
      expect(topLeft.x, closeTo(1300, 0.01));
      expect(topLeft.y, closeTo(260, 0.01));
    });

    test('JSON 保留截图尺寸与 scale，便于缓存复用', () {
      const cal = Calibration(
        window: HubWindow(100, 50, 872, 1084),
        deviceRect: DRect(300, 60, 430, 934),
        deviceWidth: 402,
        deviceHeight: 874,
        screenshotWidth: 1206,
        screenshotHeight: 2622,
        scale: 2,
      );
      final back = Calibration.fromJson(cal.toJson())!;
      expect(back.screenshotWidth, 1206);
      expect(back.screenshotHeight, 2622);
      expect(back.scale, 2);
    });

    test('窗口变了，缓存的标定应失效', () {
      const cal = Calibration(
        window: HubWindow(10, 20, 872, 1084),
        deviceRect: DRect(0, 0, 100, 200),
        deviceWidth: 400,
        deviceHeight: 800,
      );
      expect(cal.matches(const HubWindow(10, 20, 872, 1084)), isTrue);
      expect(cal.matches(const HubWindow(14, 20, 872, 1084)), isFalse);
      expect(cal.matches(const HubWindow(10, 20, 900, 1084)), isFalse);
    });
  });
}
