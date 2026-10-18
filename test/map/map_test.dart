import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:w_tools_map/w_tools_map.dart';

/// WMapItem 具体实现（测试用）
class _TestMapItem implements WMapItem {
  @override
  final String? id;
  @override
  final String? name;
  @override
  final double? latitude;
  @override
  final double? longitude;

  const _TestMapItem({this.id, this.name, this.latitude, this.longitude});
}

void main() {
  group('WMapItem — 抽象类实现', () {
    test('concrete class 正常构造 + getter 访问', () {
      const item = _TestMapItem(
        id: 'p1',
        name: '上海虹桥站',
        latitude: 31.1979,
        longitude: 121.3239,
      );
      expect(item.id, 'p1');
      expect(item.name, '上海虹桥站');
      expect(item.latitude, 31.1979);
      expect(item.longitude, 121.3239);
    });

    test('all null → 兜底逻辑可用', () {
      const item = _TestMapItem();
      expect(item.id, isNull);
      expect(item.name, isNull);
      expect(item.latitude, isNull);
      expect(item.longitude, isNull);
    });
  });

  group('WMapConfig<T> — 纯 Dart', () {
    test('默认构造参数', () {
      const cfg = WMapConfig<_TestMapItem>();
      expect(cfg.selectZoom, 12);
      expect(cfg.closeZoom, 11);
      expect(cfg.selectLatOffset, 0.0);
      expect(cfg.onItemSelected, isNull);
      expect(cfg.onItemClosed, isNull);
    });

    test('自定义参数', () {
      void onSelect(_TestMapItem item) {}
      void onClose(_TestMapItem item) {}
      final cfg = WMapConfig<_TestMapItem>(
        selectZoom: 18,
        closeZoom: 5,
        selectLatOffset: 0.001,
        onItemSelected: onSelect,
        onItemClosed: onClose,
      );
      expect(cfg.selectZoom, 18);
      expect(cfg.closeZoom, 5);
      expect(cfg.selectLatOffset, 0.001);
      expect(cfg.onItemSelected, same(onSelect));
      expect(cfg.onItemClosed, same(onClose));
    });

    test('build() 返回 WMap<T>', () {
      const cfg = WMapConfig<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>();
      final wMap = cfg.build(zone: zone);
      expect(wMap, isA<WMap<_TestMapItem>>());
    });
  });

  group('WMapZone<T> — 纯 Dart', () {
    test('空 maps → markers 为空, cameraPosition null', () {
      final zone = WMapZone<_TestMapItem>();
      expect(zone.markers, isEmpty);
      expect(zone.cameraPosition, isNull);
      expect(zone.defaultZoom, 11);
    });

    test('有 maps → 生成 Marker，cameraPosition 指向第一个', () {
      const items = <_TestMapItem>[
        _TestMapItem(id: 'a', name: 'A', latitude: 31.0, longitude: 121.0),
        _TestMapItem(id: 'b', name: 'B', latitude: 32.0, longitude: 122.0),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items);

      expect(zone.markers.length, 2);
      // cameraPosition 取第一个
      expect(zone.cameraPosition, isNotNull);
      expect(zone.cameraPosition!.target.latitude, 31.0);
      expect(zone.cameraPosition!.target.longitude, 121.0);
      expect(zone.cameraPosition!.zoom, 11); // defaultZoom
    });

    test('markerId 生成优先级: id > name > hashCode', () {
      const a = _TestMapItem(id: 'myId', name: 'N', latitude: 0, longitude: 0);
      const b = _TestMapItem(id: null, name: 'myName', latitude: 0, longitude: 0);
      const c = _TestMapItem(id: null, name: null, latitude: 0, longitude: 0);
      final zone = WMapZone<_TestMapItem>(maps: [a, b, c]);

      final markerIds = zone.markers.map((m) => m.markerId.value).toList();
      expect(markerIds, contains('myId'));
      expect(markerIds, contains('myName'));
      // c 用 hashCode.toString()，不可预测，只验证有 3 个
      expect(markerIds.length, 3);
    });

    test('null lat/lng → Marker position (0.0, 0.0)', () {
      const item = _TestMapItem(id: 'nolate', latitude: null, longitude: null);
      final zone = WMapZone<_TestMapItem>(maps: [item]);
      final marker = zone.markers.first;
      expect(marker.position.latitude, 0.0);
      expect(marker.position.longitude, 0.0);
      expect(zone.cameraPosition!.target.latitude, 0.0);
    });

    test('icon 为 null → Marker.icon = BitmapDescriptor.defaultMarker', () {
      const items = <_TestMapItem>[
        _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items);
      final marker = zone.markers.first;
      expect(marker.icon, BitmapDescriptor.defaultMarker);
    });

    test('zoneId / name 字段可赋值', () {
      final zone = WMapZone<_TestMapItem>(zoneId: 'z1', name: '虹桥区域');
      expect(zone.zoneId, 'z1');
      expect(zone.name, '虹桥区域');
    });

    test('defaultZoom 自定义', () {
      const items = [
        _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items, defaultZoom: 15);
      expect(zone.defaultZoom, 15);
      expect(zone.cameraPosition!.zoom, 15);
    });

    test('update() — 更换 maps → 重新 initMap', () {
      const items1 = [
        _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
      ];
      const items2 = [
        _TestMapItem(id: 'b', name: 'B', latitude: 10, longitude: 20),
        _TestMapItem(id: 'c', name: 'C', latitude: 30, longitude: 40),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items1);
      expect(zone.markers.length, 1);

      zone.update(items2);
      expect(zone.markers.length, 2);
      expect(zone.maps, items2);
      expect(zone.cameraPosition!.target.latitude, 10);
    });

    test('update(null) → maps 清空 → markers 清空, cameraPosition null', () {
      const items = [
        _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items);
      expect(zone.markers, isNotEmpty);

      zone.update(null);
      expect(zone.markers, isEmpty);
      expect(zone.maps, isNull);
      expect(zone.cameraPosition, isNull);
    });

    test('onDataUpdated 在 initMap 时触发', () {
      var called = 0;
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)],
      );
      zone.onDataUpdated = () {
        called++;
      };
      // 构造函数已调 initMap，此时 onDataUpdated 还未赋值
      // update → initMap → 触发
      zone.update(const [_TestMapItem(id: 'b', name: 'B', latitude: 3, longitude: 4)]);
      expect(called, 1);

      // 手动 initMap 也触发
      zone.initMap();
      expect(called, 2);
    });
  });

  group('WMapZone MarkerTapListener — 纯 Dart', () {
    test('addMarkerTapListener + Marker.onTap → listener 被触发', () {
      final tapped = <_TestMapItem>[];
      const items = [
        _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
        _TestMapItem(id: 'b', name: 'B', latitude: 3, longitude: 4),
      ];
      final zone = WMapZone<_TestMapItem>(maps: items);
      zone.addMarkerTapListener((item) => tapped.add(item));

      // Marker.onTap 是闭包，需要手动调。找 id='a' 的 marker
      final markerA = zone.markers.firstWhere((m) => m.markerId.value == 'a');
      markerA.onTap!();
      expect(tapped.length, 1);
      expect(tapped.first.id, 'a');

      final markerB = zone.markers.firstWhere((m) => m.markerId.value == 'b');
      markerB.onTap!();
      expect(tapped.length, 2);
      expect(tapped.last.id, 'b');
    });

    test('多个 listener 全部触发', () {
      final l1 = <String>[];
      final l2 = <String>[];
      const items = [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)];
      final zone = WMapZone<_TestMapItem>(maps: items);
      zone.addMarkerTapListener((_) => l1.add('fired'));
      zone.addMarkerTapListener((_) => l2.add('fired'));

      final marker = zone.markers.first;
      marker.onTap!();
      expect(l1.length, 1);
      expect(l2.length, 1);
    });

    test('removeMarkerTapListener → 移除后不再触发', () {
      final l1 = <String>[];
      const items = [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)];
      final zone = WMapZone<_TestMapItem>(maps: items);
      void handler(_TestMapItem _) => l1.add('x');
      zone.addMarkerTapListener(handler);

      final marker = zone.markers.first;
      marker.onTap!();
      expect(l1.length, 1);

      zone.removeMarkerTapListener(handler);
      marker.onTap!();
      expect(l1.length, 1); // 不再增加
    });
  });

  group('WMap + WMapConfig.build → 构造 & wiring', () {
    testWidgets('WMap widget 渲染 GoogleMap', (tester) async {
      const cfg = WMapConfig<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>(
        maps: const [
          _TestMapItem(id: 'a', name: 'A', latitude: 31.1979, longitude: 121.3239),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WMap<_TestMapItem>(config: cfg, zone: zone),
          ),
        ),
      );

      expect(find.byType(GoogleMap), findsOneWidget);
      // zone.markers 应该有 1 个
      expect(zone.markers.length, 1);
      // cameraPosition 指向第一个 item
      expect(zone.cameraPosition!.target.latitude, 31.1979);
    });

    testWidgets('WMap dispose → 移除 listener + 清理 onDataUpdated', (tester) async {
      const cfg = WMapConfig<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WMap<_TestMapItem>(config: cfg, zone: zone)),
        ),
      );

      // zone.onDataUpdated 应该被注册
      expect(zone.onDataUpdated, isNotNull);

      // dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('done'))));

      // dispose 后 onDataUpdated 应该被清除
      expect(zone.onDataUpdated, isNull);
    });
  });
}
