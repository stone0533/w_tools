import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:w_tools_device/src/calibration.dart';
import 'package:w_tools_device/src/device_hub.dart';
import 'package:w_tools_device/src/geometry.dart';

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

    test('Retina / 小数 / 负坐标 / 副屏都能解析', () {
      final retina = DeviceHub.parseWindow('-1512.5, 53, 872.5, 1084')!;
      expect(retina.x, -1512.5);
      expect(retina.width, 872.5);
      final offscreen = DeviceHub.parseWindow('4198, 101, 872, 1084')!;
      expect(offscreen.x, 4198);
    });
  });

  group('Calibration.toScreen（设备 point → 屏幕 point）', () {
    test('中心与左上角', () {
      const cal = Calibration(
        window: HubWindow(1000, 200, 872, 1084),
        deviceRect: DRect(300, 60, 430, 934),
        deviceWidth: 402,
        deviceHeight: 874,
      );
      final center = cal.toScreen(const DPoint(201, 437));
      expect(center.x, closeTo(300 + 215, 0.5));
      expect(center.y, closeTo(60 + 467, 0.5));

      final topLeft = cal.toScreen(const DPoint(0, 0));
      expect(topLeft.x, closeTo(300, 0.01));
      expect(topLeft.y, closeTo(60, 0.01));
    });

    test('回归 #145：deviceRect 是屏幕坐标，窗口原点只加一次', () {
      // detect 输出的 deviceRect 已含窗口原点；这里用真实屏幕坐标验证 toScreen。
      const cal = Calibration(
        window: HubWindow(40, 107, 872, 1004),
        deviceRect: DRect(435.392, 252.77265671641794, 333.216, 724.4546865671641),
        deviceWidth: 402,
        deviceHeight: 874,
      );
      final p = cal.toScreen(const DPoint(33, 248));
      expect(p.x, closeTo(462.746, 0.01));
      expect(p.y, closeTo(458.339, 0.01));
      expect(p.x, inInclusiveRange(cal.deviceRect.left, cal.deviceRect.right));
      expect(p.y, inInclusiveRange(cal.deviceRect.top, cal.deviceRect.bottom));
    });
  });

  group('DRect.scaled', () {
    test('point → px：四边与尺寸同比例', () {
      const region = DRect(0, 35, 402, 70);
      final px = region.scaled(3);
      expect(px.left, 0);
      expect(px.top, 105);
      expect(px.width, 1206);
      expect(px.height, 210);
    });
  });

  group('Calibration.toJson（唯一一份序列化）', () {
    test('两套 scale 分开命名，deviceRect 为屏幕坐标', () {
      const cal = Calibration(
        window: HubWindow(100, 50, 872, 1084),
        deviceRect: DRect(300, 60, 430, 934),
        deviceWidth: 402,
        deviceHeight: 874,
        screenshotWidth: 1206,
        screenshotHeight: 2622,
        scale: 2,
        windowTitle: 'iPhone 17 Pro – iOS 26.5',
      );
      final json = cal.toJson();
      expect(json['coordinateSpace'], 'screen');
      expect(json['calibrationVersion'], 2);
      expect((json['window'] as Map)['scale'], 2);
      expect((json['screenshot'] as Map)['scale'], 3);
      expect((json['screenshot'] as Map)['windowScale'], 2);
      expect((json['device'] as Map)['width'], 402);
      expect(json['deviceRect'] as Map, containsPair('w', 430));
      expect(json['windowTitle'], 'iPhone 17 Pro – iOS 26.5');
    });

    test('deviceScale 优先于截图宽高反推（非整除宽度也不偏）', () {
      const cal = Calibration(
        window: HubWindow(0, 0, 1, 1),
        deviceRect: DRect(0, 0, 1, 1),
        deviceWidth: 402,
        deviceHeight: 874,
        screenshotWidth: 1207,
        screenshotHeight: 2622,
        deviceScale: 3,
      );
      expect(cal.screenshotScale, 3);
    });

    test('deviceWidth 为 0 时 screenshotScale 不除零', () {
      const cal = Calibration(
        window: HubWindow(0, 0, 1, 1),
        deviceRect: DRect(0, 0, 1, 1),
        deviceWidth: 0,
        deviceHeight: 0,
        screenshotWidth: 100,
      );
      expect(cal.screenshotScale, 0);
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
      img.fillRect(
        image,
        x1: bezel.left.round(),
        y1: bezel.top.round(),
        x2: bezel.right.round(),
        y2: bezel.bottom.round(),
        color: img.ColorRgb8(10, 10, 10),
      );
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

    test('在合成图里找到设备屏幕矩形（1x），并换算到屏幕坐标', () {
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
      // bbox 是窗口内 (340,80)；加回窗口原点 (100,50) 才是屏幕坐标。
      expect(cal.deviceRect.left, closeTo(340 + window.x, 25));
      expect(cal.deviceRect.top, closeTo(80 + window.y, 25));
      expect(cal.deviceRect.width / cal.deviceRect.height, closeTo(402 / 874, 0.02));
      // 设备矩形必须落在窗口内，点击结果必须落在设备矩形内。
      expect(cal.deviceRect.left, greaterThanOrEqualTo(window.x));
      expect(cal.deviceRect.top, greaterThanOrEqualTo(window.y));
      expect(cal.deviceRect.right, lessThanOrEqualTo(window.x + window.width));
      expect(cal.deviceRect.bottom, lessThanOrEqualTo(window.y + window.height));
      final center = cal.toScreen(const DPoint(201, 437));
      expect(center.x, inInclusiveRange(cal.deviceRect.left, cal.deviceRect.right));
      expect(center.y, inInclusiveRange(cal.deviceRect.top, cal.deviceRect.bottom));
    });

    test('设备预览只露出半截 → 报错并提示两种可能（遮挡 / 窗口里选错设备）', () {
      const window = HubWindow(0, 0, 872, 1084);
      final image = synthetic(
        width: 872,
        height: 600,
        bezel: const DRect(340, 60, 400, 400),
        inset: 10,
      );
      expect(
        () => const CalibrationDetector().detect(
          image: image,
          window: window,
          scale: 1,
          deviceWidth: 402,
          deviceHeight: 874,
          windowTitle: 'iPhone 17 – iOS 26.2',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('遮挡'), contains('已关机'), contains('iPhone 17 – iOS 26.2')),
          ),
        ),
      );
    });

    test('横屏预览但设备截图竖屏 → 明确报“横屏不支持”', () {
      final image = img.Image(width: 1084, height: 872);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(image, x1: 40, y1: 186, x2: 1040, y2: 686, color: img.ColorRgb8(8, 8, 8));
      img.fillRect(image, x1: 60, y1: 200, x2: 1020, y2: 672, color: img.ColorRgb8(235, 235, 235));
      expect(
        () => const CalibrationDetector().detect(
          image: image,
          window: const HubWindow(0, 0, 1084, 872),
          scale: 1,
          deviceWidth: 402,
          deviceHeight: 874,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('横屏'), contains('Portrait')),
          ),
        ),
      );
    });

    test('深色画面（屏幕内容也接近黑色）仍按机身外框标定', () {
      final image = img.Image(width: 872, height: 1084);
      img.fill(image, color: img.ColorRgb8(250, 250, 250));
      img.fillRect(image, x1: 340, y1: 60, x2: 780, y2: 1030, color: img.ColorRgb8(8, 8, 8));
      img.fillRect(image, x1: 350, y1: 70, x2: 770, y2: 1020, color: img.ColorRgb8(30, 30, 30));
      final cal = const CalibrationDetector().detect(
        image: image,
        window: const HubWindow(0, 0, 872, 1084),
        scale: 1,
        deviceWidth: 402,
        deviceHeight: 874,
      );
      expect(cal.deviceRect.width / cal.deviceRect.height, closeTo(402 / 874, 0.02));
      expect(cal.deviceRect.left, closeTo(340, 25));
    });

    test('找不到机身 → 提示权限 / 模拟器', () {
      final blank = img.Image(width: 872, height: 1084);
      img.fill(blank, color: img.ColorRgb8(250, 250, 250));
      expect(
        () => const CalibrationDetector().detect(
          image: blank,
          window: const HubWindow(0, 0, 872, 1084),
          scale: 1,
          deviceWidth: 402,
          deviceHeight: 874,
          windowTitle: 'iPhone 17 Pro – iOS 26.5',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('屏幕录制'), contains('iPhone 17 Pro – iOS 26.5')),
          ),
        ),
      );
    });
  });
}
