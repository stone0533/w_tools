import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:w_tools_map/w_tools_map.dart';

class _Shop implements WMapItem {
  _Shop(this.id, this.name, this.latitude, this.longitude);

  @override
  final String? id;

  @override
  final String? name;

  @override
  final double? latitude;

  @override
  final double? longitude;
}

class _NotItem {
  const _NotItem();
}

void main() {
  test('T 未实现 WMapItem 且没传 mapper → 可读的 ArgumentError', () {
    expect(
      () => WMapZone<_NotItem>(maps: const []),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'message',
          allOf(contains('未实现 WMapItem'), contains('WMapItemMapper')),
        ),
      ),
    );
  });

  test('空数据时使用 initialCamera，而不是 (0,0)', () {
    const camera = CameraPosition(target: LatLng(3, 4), zoom: 7);
    final zone = WMapZone<_Shop>(maps: const [], initialCamera: camera);

    expect(zone.cameraPosition, isNotNull);
    expect(zone.cameraPosition!.target.latitude, 3);
    expect(zone.cameraPosition!.target.longitude, 4);
    expect(zone.cameraPosition!.zoom, 7);
  });

  test('经纬度缺失的条目被跳过，不落到 (0,0)', () {
    final zone = WMapZone<_Shop>(
      maps: [
        _Shop('bad', '缺失坐标', null, null),
        _Shop('good', '正常门店', 1.5, 2.5),
      ],
    );

    expect(zone.markers.length, 1);
    expect(zone.markers.single.markerId.value, 'good');
    expect(zone.cameraPosition!.target.latitude, 1.5);
    expect(zone.cameraPosition!.target.longitude, 2.5);
  });

  test('自定义 mapper 不传 isValid 时全部渲染（保持旧行为）', () {
    final zone = WMapZone<_Shop>(
      maps: [_Shop('bad', '缺失坐标', null, null)],
      mapper: WMapItemMapper<_Shop>(
        id: (item) => item.id!,
        position: (item) => (latitude: 9, longitude: 9),
      ),
    );

    expect(zone.markers.length, 1);
    expect(zone.cameraPosition!.target.latitude, 9);
  });
}
