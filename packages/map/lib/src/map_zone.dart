part of 'map.dart';

/// 资产图标缓存：`asset@imagePixelRatio` -> 解码结果。
///
/// key 里带 pixelRatio：同一张图用不同密度时不至于互相顶掉。
final Map<String, BitmapDescriptor> _assetIconCache = {};

/// 正在解码中的 key（避免重复解码）
final Set<String> _loadingIconKeys = {};

String _iconCacheKey(String asset, double imagePixelRatio) => '$asset@$imagePixelRatio';

/// 加载并缓存资产图标；失败返回 null（调用方降级为默认图标）。
Future<BitmapDescriptor?> _loadAssetIcon(
  String asset,
  double imagePixelRatio,
) async {
  final key = _iconCacheKey(asset, imagePixelRatio);
  final cached = _assetIconCache[key];
  if (cached != null) return cached;
  if (!_loadingIconKeys.add(key)) return null;
  try {
    final data = await rootBundle.load(asset);
    final icon = BitmapDescriptor.bytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      imagePixelRatio: imagePixelRatio,
    );
    _assetIconCache[key] = icon;
    return icon;
  } catch (_) {
    // 资产不存在/解码失败：保持默认图标，不要崩
    return null;
  } finally {
    _loadingIconKeys.remove(key);
  }
}

/// 资产图标预热。
///
/// 在 App 启动阶段调用一次，进入地图页时直接命中缓存，
/// 避免首帧先画默认图标再切换（3ms 左右的可见闪烁）。
///
/// ```dart
/// await WMapIconAssets.preload(
///   ['assets/images/map_address_icon.png'],
///   imagePixelRatio: 2.5,
/// );
/// ```
abstract final class WMapIconAssets {
  static Future<void> preload(
    Iterable<String> assets, {
    double imagePixelRatio = 1.0,
  }) async {
    for (final asset in assets) {
      await _loadAssetIcon(asset, imagePixelRatio);
    }
  }
}

/// 比较相机位置（[CameraPosition] 已按 target / zoom / bearing / tilt 实现 `==`）
bool _sameCamera(CameraPosition? a, CameraPosition? b) => a == b;

/// 地图区域类
///
/// 持有 [GoogleMapController]、[markers] 集合、地图数据列表 [maps]，
/// 支持外部复用、跨组件共享控制器状态及通过 [update] 刷新数据。
///
/// 泛型 [T] 无约束：实现 [WMapItem] 可直接用默认 mapper，否则必须传 [WMapItemMapper]。
class WMapZone<T> {
  /// Google 地图控制器
  GoogleMapController? googleMapController;

  /// 区域 ID
  String? zoneId;

  /// 区域名称
  String? name;

  /// Marker 集合（按 [initMap] 的结果重建，未变化的条目复用同一实例）
  Set<Marker> markers = {};

  /// 上一次生成的 Marker（按 id 缓存，减少 Google Maps 重建闪烁）
  final Map<String, Marker> _markerCache = {};

  /// 上次生成 Marker 时的内容签名（id -> 签名）
  final Map<String, Object> _markerSignatures = {};

  /// 当前条目索引（id -> 最新实例），Marker onTap 回调时取最新数据
  final Map<String, T> _itemsById = {};

  /// 地图数据列表
  List<T>? maps;

  /// 初始相机位置（maps 为空时为 null，[WMap] 会提供默认位置）
  CameraPosition? cameraPosition;

  /// 没有可渲染条目时的初始相机（例如先显示城市中心，等数据回来再移动）
  ///
  /// 未设置时保持历史行为：[WMap] 回落到 `(0,0)/zoom 1`。
  final CameraPosition? initialCamera;

  /// Marker 图标（为 null 时使用默认图标）
  BitmapDescriptor? icon;

  /// Marker 图标的资产路径（如 `assets/images/map_address_icon.png`）。
  ///
  /// 优先级：`iconBuilder` > `icon` > `iconAsset` > 默认图标。
  /// 由包内部 `rootBundle` 加载并缓存，业务层不必 import google_maps_flutter，
  /// 也不会因为每次构建都新建 BitmapDescriptor 而累积图标缓存。
  final String? iconAsset;

  /// `iconAsset` 的像素密度（对应 `BitmapDescriptor.bytes` 的 imagePixelRatio）
  final double imagePixelRatio;

  /// 按条目决定 Marker 图标（优先级高于 [icon]）。
  ///
  /// 用于"不同门店画不同图标"（旗舰店 / 普通店 / 暂停营业等）。
  /// 注意：Google Maps 对自定义图片图标有缓存，建议复用同一个 BitmapDescriptor 实例。
  final BitmapDescriptor Function(T item)? iconBuilder;

  /// Marker 点击回调列表（支持多个 [WMap] 共享同一 zone）
  final List<void Function(T)> _onMarkerTaps = [];

  /// 数据更新回调列表（支持多个 [WMap] 共享同一 zone）
  final List<void Function()> _onDataUpdatedListeners = [];

  /// 默认缩放级别
  final double defaultZoom;

  /// 业务模型 -> 地图字段的适配器
  final WMapItemMapper<T> mapper;

  /// 构造函数
  WMapZone({
    this.googleMapController,
    this.zoneId,
    this.name,
    this.maps,
    this.icon,
    this.iconAsset,
    this.imagePixelRatio = 1.0,
    this.iconBuilder,
    this.defaultZoom = 11,
    this.initialCamera,
    WMapItemMapper<T>? mapper,
  }) : mapper = mapper ?? _defaultMapper<T>() {
    initMap();
  }

  /// 注册数据更新回调（[WMap] 在 initState 时调用）
  void addDataUpdatedListener(void Function() listener) {
    if (_onDataUpdatedListeners.contains(listener)) return;
    _onDataUpdatedListeners.add(listener);
  }

  /// 移除数据更新回调（[WMap] 在 dispose 时调用）
  void removeDataUpdatedListener(void Function() listener) {
    _onDataUpdatedListeners.remove(listener);
  }

  /// 当前注册的数据更新回调数量（测试用）
  @visibleForTesting
  int get dataUpdatedListenerCount => _onDataUpdatedListeners.length;

  /// 注册 Marker 点击回调（[WMap] 在 initState 时调用）
  void addMarkerTapListener(void Function(T) listener) {
    if (_onMarkerTaps.contains(listener)) return;
    _onMarkerTaps.add(listener);
  }

  /// 移除 Marker 点击回调（[WMap] 在 dispose 时调用）
  void removeMarkerTapListener(void Function(T) listener) {
    _onMarkerTaps.remove(listener);
  }

  LatLng _latLngOf(T item) {
    final p = mapper.position(item);
    return LatLng(p.latitude, p.longitude);
  }

  BitmapDescriptor _iconFor(T item) {
    final built = iconBuilder?.call(item);
    if (built != null) return built;
    if (icon != null) return icon!;
    final asset = iconAsset;
    if (asset == null || asset.isEmpty) return BitmapDescriptor.defaultMarker;
    final key = _iconCacheKey(asset, imagePixelRatio);
    final cached = _assetIconCache[key];
    if (cached != null) return cached;
    // 首次遇到就先返回默认图标，解码完成后 initMap 重建（WMap 会 setState）
    if (!_loadingIconKeys.contains(key)) {
      _loadAssetIcon(asset, imagePixelRatio).then((icon) {
        if (icon != null) initMap();
      });
    }
    return BitmapDescriptor.defaultMarker;
  }

  /// 初始化地图
  ///
  /// 依据 [maps] 生成 [markers]，并以首个条目作为初始相机位置。
  /// 若 [maps] 为空，[cameraPosition] 保持为 null。
  void initMap() {
    final renderable = <T>[];
    final nextMarkers = <Marker>{};
    final nextCache = <String, Marker>{};
    final nextSignatures = <String, Object>{};
    final nextItems = <String, T>{};

    maps?.forEach((element) {
      if (mapper.isValid?.call(element) == false) return;
      renderable.add(element);

      final id = mapper.id(element);
      final position = _latLngOf(element);
      final name = mapper.name?.call(element);
      final icon = _iconFor(element);
      final signature = Object.hash(
        name,
        position.latitude,
        position.longitude,
        identityHashCode(icon),
      );

      final cached = _markerCache[id];
      final marker = cached != null && _markerSignatures[id] == signature
          ? cached
          : Marker(
              markerId: MarkerId(id),
              position: position,
              infoWindow: InfoWindow(title: name),
              icon: icon,
              onTap: () {
                // 复用 Marker 时指向最新实例，避免点击拿到旧数据
                final current = _itemsById[id] ?? element;
                for (final listener in List<void Function(T)>.of(_onMarkerTaps)) {
                  listener(current);
                }
              },
            );

      nextMarkers.add(marker);
      nextCache[id] = marker;
      nextSignatures[id] = signature;
      nextItems[id] = element;
    });

    _markerCache
      ..clear()
      ..addAll(nextCache);
    _markerSignatures
      ..clear()
      ..addAll(nextSignatures);
    _itemsById
      ..clear()
      ..addAll(nextItems);
    markers
      ..clear()
      ..addAll(nextMarkers);
    final first = renderable.firstOrNull;
    if (first != null) {
      cameraPosition = CameraPosition(
        target: _latLngOf(first),
        zoom: defaultZoom,
      );
    } else {
      cameraPosition = initialCamera;
    }
    for (final listener in List<void Function()>.of(_onDataUpdatedListeners)) {
      listener();
    }
  }

  /// 更新地图数据并重新初始化
  void update(List<T>? maps) {
    this.maps = maps;
    initMap();
  }
}
