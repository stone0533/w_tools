import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:w_tools_map/w_tools_map.dart';

/// 不实现 WMapItem 的业务模型（用于 mapper 模式）
class _PlainShop {
  const _PlainShop({required this.code, required this.lat, required this.lng});
  final String code;
  final double lat;
  final double lng;
}

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

    test('markerId 生成优先级: id > name > 经纬度（不用 hashCode）', () {
      const a = _TestMapItem(id: 'myId', name: 'N', latitude: 0, longitude: 0);
      const b = _TestMapItem(id: null, name: 'myName', latitude: 0, longitude: 0);
      const c = _TestMapItem(id: null, name: null, latitude: 22.3, longitude: 114.2);
      final zone = WMapZone<_TestMapItem>(maps: [a, b, c]);

      final markerIds = zone.markers.map((m) => m.markerId.value).toList();
      expect(markerIds, contains('myId'));
      expect(markerIds, contains('myName'));
      // 都没有时用经纬度兜底：对象重建后仍然稳定
      expect(markerIds, contains('22.3_114.2'));
      expect(markerIds.length, 3);
    });

    test('mapper 模式：模型不必实现 WMapItem', () {
      final zone = WMapZone<_PlainShop>(
        maps: const [
          _PlainShop(code: 's1', lat: 22.3, lng: 114.1),
        ],
        mapper: WMapItemMapper<_PlainShop>(
          id: (s) => s.code,
          name: (s) => '門店 ${s.code}',
          position: (s) => (latitude: s.lat, longitude: s.lng),
        ),
      );

      expect(zone.markers.length, 1);
      expect(zone.markers.first.markerId.value, 's1');
      expect(zone.markers.first.position.latitude, 22.3);
      expect(zone.markers.first.infoWindow.title, '門店 s1');
      expect(zone.cameraPosition!.target.longitude, 114.1);
    });

    test('iconBuilder：按条目决定图标，优先于 zone.icon', () {
      var calls = 0;
      final red = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      final green =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      final zone = WMapZone<_TestMapItem>(
        maps: const [
          _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
          _TestMapItem(id: 'b', name: 'B', latitude: 3, longitude: 4),
        ],
        icon: BitmapDescriptor.defaultMarker,
        iconBuilder: (item) {
          calls++;
          return item.id == 'a' ? red : green;
        },
      );

      expect(calls, 2, reason: '每个条目都应调用一次 iconBuilder');
      final icons = zone.markers.map((m) => m.icon).toList();
      expect(icons[0], red);
      expect(icons[1], green);
      expect(icons[0], isNot(icons[1]));
    });

    test('iconAsset：资产缺失时降级为默认图标，不崩', () {
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', latitude: 1, longitude: 2)],
        iconAsset: 'assets/not_exists_should_not_crash.png',
      );
      expect(zone.markers.length, 1);
      expect(zone.markers.first.icon, BitmapDescriptor.defaultMarker);
    });

    test('没有 iconBuilder 时回退到 zone.icon / 默认图标', () {
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', latitude: 1, longitude: 2)],
      );
      expect(zone.markers.first.icon, BitmapDescriptor.defaultMarker);
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

    test('addDataUpdatedListener：initMap 触发、可多注册、可移除', () {
      var first = 0;
      var second = 0;
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)],
      );
      void firstListener() => first++;
      void secondListener() => second++;

      zone.addDataUpdatedListener(firstListener);
      zone.addDataUpdatedListener(secondListener);
      // 重复注册同一个 listener 不会重复触发
      zone.addDataUpdatedListener(firstListener);
      expect(zone.dataUpdatedListenerCount, 2);

      zone.update(const [
        _TestMapItem(id: 'b', name: 'B', latitude: 3, longitude: 4),
      ]);
      expect(first, 1);
      expect(second, 1);

      zone.removeDataUpdatedListener(firstListener);
      zone.initMap();
      expect(first, 1);
      expect(second, 2);
      expect(zone.dataUpdatedListenerCount, 1);
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

    testWidgets('WMap dispose → 移除 listener', (tester) async {
      const cfg = WMapConfig<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>(
        maps: const [_TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WMap<_TestMapItem>(config: cfg, zone: zone)),
        ),
      );

      // 挂载后应该注册了数据更新监听
      expect(zone.dataUpdatedListenerCount, 1);

      // dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('done'))));

      // dispose 后监听应该被移除
      expect(zone.dataUpdatedListenerCount, 0);
    });

    testWidgets('WMapConfig.padding 透传给 GoogleMap', (tester) async {
      const cfg = WMapConfig<_TestMapItem>(
        padding: EdgeInsets.only(bottom: 120),
      );
      final zone = WMapZone<_TestMapItem>(
        maps: const [
          _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WMap<_TestMapItem>(config: cfg, zone: zone)),
        ),
      );

      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.padding, const EdgeInsets.only(bottom: 120));
    });

    testWidgets('WMapController.select → 触发 onItemSelected', (tester) async {
      _TestMapItem? selected;
      final controller = WMapController<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>(
        maps: const [
          _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WMap<_TestMapItem>(
              controller: controller,
              zone: zone,
              config: WMapConfig<_TestMapItem>(
                onItemSelected: (item) => selected = item,
              ),
            ),
          ),
        ),
      );

      await controller.select(zone.maps!.first);
      await tester.pump();
      expect(selected?.id, 'a');
    });

    testWidgets('WMapController 随 WMap 挂载/卸载绑定', (tester) async {
      const cfg = WMapConfig<_TestMapItem>();
      final controller = WMapController<_TestMapItem>();
      final zone = WMapZone<_TestMapItem>(
        maps: const [
          _TestMapItem(id: 'a', name: 'A', latitude: 1, longitude: 2),
        ],
      );

      expect(controller.isAttached, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WMap<_TestMapItem>(
              config: cfg,
              zone: zone,
              controller: controller,
            ),
          ),
        ),
      );
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('done'))),
      );
      expect(controller.isAttached, isFalse);
    });
  });
}
