import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:w_tools_map/w_tools_map.dart';
import 'package:w_tools_map_google/w_tools_map_google.dart';

class _FakeMapsPlatform extends GoogleMapsFlutterPlatform {
  final moved = <CameraPosition>[];
  final _created = <int>{};

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    if (_created.add(creationId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPlatformViewCreated(creationId);
      });
    }
    return const SizedBox.expand();
  }

  @override
  Future<void> init(int mapId) async {}

  @override
  void dispose({required int mapId}) {}

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMarkers(MarkerUpdates markerUpdates, {required int mapId}) async {}

  @override
  Future<void> updatePolygons(PolygonUpdates polygonUpdates, {required int mapId}) async {}

  @override
  Future<void> updatePolylines(PolylineUpdates polylineUpdates, {required int mapId}) async {}

  @override
  Future<void> updateCircles(CircleUpdates circleUpdates, {required int mapId}) async {}

  @override
  Future<void> updateHeatmaps(HeatmapUpdates heatmapUpdates, {required int mapId}) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) => const Stream.empty();

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) => const Stream.empty();

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) => const Stream.empty();

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) => const Stream.empty();

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) => const Stream.empty();

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) => const Stream.empty();

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) => const Stream.empty();

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) => const Stream.empty();

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) => const Stream.empty();

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) => const Stream.empty();

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) => const Stream.empty();

  @override
  Stream<PointOfInterestTapEvent> onPointOfInterestTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MapTapEvent> onTap({required int mapId}) => const Stream.empty();

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) => const Stream.empty();

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) => const Stream.empty();

  @override
  Stream<GroundOverlayTapEvent> onGroundOverlayTap({required int mapId}) => const Stream.empty();

  @override
  Future<void> moveCamera(CameraUpdate cameraUpdate, {required int mapId}) async {
    final json = cameraUpdate.toJson() as List<Object>;
    if (json.first == 'newCameraPosition') {
      final position = json[1] as Map<String, Object>;
      final target = position['target'] as List<double>;
      moved.add(
        CameraPosition(
          target: LatLng(target[0], target[1]),
          zoom: (position['zoom'] as num).toDouble(),
        ),
      );
    }
  }
}

class _Shop implements WMapItem {
  const _Shop({required this.id, required this.lat, required this.lng});

  @override
  final String id;
  final double lat;
  final double lng;

  @override
  String? get name => id;

  @override
  double? get latitude => lat;

  @override
  double? get longitude => lng;
}

void main() {
  testWidgets('initialCamera 占位后，首条数据到达会移动相机', (tester) async {
    final original = GoogleMapsFlutterPlatform.instance;
    final fake = _FakeMapsPlatform();
    GoogleMapsFlutterPlatform.instance = fake;
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);

    final zone = WMapZone<_Shop>(
      maps: const [],
      initialCamera: const CameraPosition(target: LatLng(31.2, 121.5), zoom: 11),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WMap<_Shop>(zone: zone, config: const WMapConfig<_Shop>()),
      ),
    );
    await tester.pump(); // onMapCreated
    await tester.pump(); // post-frame listener

    zone.update(const [_Shop(id: 'a', lat: 31.30, lng: 121.60)]);
    await tester.pump();

    expect(fake.moved, isNotEmpty);
    expect(fake.moved.last.target.latitude, closeTo(31.30, 1e-6));
    expect(fake.moved.last.target.longitude, closeTo(121.60, 1e-6));
  });
}
