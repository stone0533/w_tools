import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 地图条目抽象基类
///
/// 业务数据模型实现此接口，提供地图渲染所需的必需字段。
/// 其他业务字段（如营业时间、地址、标签等）由子类自行持有。
abstract class WMapItem {
  /// 唯一标识（用于生成 [MarkerId]）
  String? get id;

  /// 名称（用于 Marker [InfoWindow] 标题）
  String? get name;

  /// 纬度
  double? get latitude;

  /// 经度
  double? get longitude;
}

/// 从业务模型里取地图所需字段的适配器。
///
/// 两种接入方式：
/// 1. 模型 `implements WMapItem`（简单场景，直接用）；
/// 2. 模型不动，传三个取值函数（json_serializable 生成的模型只能用这种方式，
///    否则每次重新生成都会被覆盖）。
class WMapItemMapper<T> {
  /// MarkerId：必须稳定（同一对象重建后不变）
  final String Function(T item) id;

  /// InfoWindow 标题
  final String? Function(T item)? name;

  /// 经纬度。
  ///
  /// 用 record 而不是 `LatLng`：业务层不必 import google_maps_flutter，
  /// 换地图实现时只改这个包。
  final ({double latitude, double longitude}) Function(T item) position;

  const WMapItemMapper({
    required this.id,
    required this.position,
    this.name,
  });
}

/// `implements WMapItem` 时的默认 mapper。
WMapItemMapper<T> wMapItemMapper<T>() {
  return WMapItemMapper<T>(
    id: (item) {
      final it = item as WMapItem;
      // 依次回退：id > name > 经纬度（都比 hashCode 稳定）
      return it.id ?? it.name ?? '${it.latitude ?? 0.0}_${it.longitude ?? 0.0}';
    },
    name: (item) => (item as WMapItem).name,
    position: (item) {
      final it = item as WMapItem;
      return (latitude: it.latitude ?? 0.0, longitude: it.longitude ?? 0.0);
    },
  );
}

/// 资产图标缓存：`asset@imagePixelRatio` -> 解码结果。
///
/// key 里带 pixelRatio：同一张图用不同密度时不至于互相顶掉。
final Map<String, BitmapDescriptor> _assetIconCache = {};

/// 正在解码中的 key（避免重复解码）
final Set<String> _loadingIconKeys = {};

String _iconCacheKey(String asset, double imagePixelRatio) =>
    '$asset@$imagePixelRatio';

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

/// MarkerId 规则见 [WMapItemMapper.id]（id > name > 经纬度，不用 hashCode）。
bool _sameCamera(CameraPosition? a, CameraPosition? b) {
  if (a == null || b == null) return a == b;
  return a.target == b.target &&
      a.zoom == b.zoom &&
      a.bearing == b.bearing &&
      a.tilt == b.tilt;
}

/// 地图区域类
///
/// 持有 [GoogleMapController]、[markers] 集合、地图数据列表 [maps]，
/// 支持外部复用、跨组件共享控制器状态及通过 [update] 刷新数据。
///
/// 泛型 [T] 约束为 [WMapItem]，业务方传入自己的数据模型类型。
class WMapZone<T> {
  /// Google 地图控制器
  GoogleMapController? googleMapController;

  /// 区域 ID
  String? zoneId;

  /// 区域名称
  String? name;

  /// Marker 集合
  Set<Marker> markers = {};

  /// 地图数据列表
  List<T>? maps;

  /// 初始相机位置（maps 为空时为 null，[WMap] 会提供默认位置）
  CameraPosition? cameraPosition;

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

  /// 数据更新回调（单值，仅保留向后兼容）。
  ///
  /// 多个 [WMap] 共享同一 zone 时会互相覆盖，请改用
  /// [addDataUpdatedListener] / [removeDataUpdatedListener]。
  @Deprecated('Use addDataUpdatedListener/removeDataUpdatedListener instead')
  void Function()? onDataUpdated;

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
    WMapItemMapper<T>? mapper,
  }) : mapper = mapper ?? wMapItemMapper<T>() {
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
    markers.clear();
    maps?.forEach((element) {
      markers.add(
        Marker(
          markerId: MarkerId(mapper.id(element)),
          position: _latLngOf(element),
          infoWindow: InfoWindow(title: mapper.name?.call(element)),
          icon: _iconFor(element),
          onTap: () {
            for (final listener in List<void Function(T)>.of(_onMarkerTaps)) {
              listener(element);
            }
          },
        ),
      );
    });
    final first = maps?.firstOrNull;
    if (first != null) {
      cameraPosition = CameraPosition(
        target: _latLngOf(first),
        zoom: defaultZoom,
      );
    } else {
      cameraPosition = null;
    }
    for (final listener in List<void Function()>.of(_onDataUpdatedListeners)) {
      listener();
    }
    // ignore: deprecated_member_use_from_same_package
    onDataUpdated?.call();
  }

  /// 更新地图数据并重新初始化
  void update(List<T>? maps) {
    this.maps = maps;
    initMap();
  }
}

/// [WMap] 的控制器：用于从业务 UI 侧触发地图动作（目前只有「关闭选中」）。
///
/// 之前 `closeSelection` 定义在私有的 `_WMapState` 里，外部拿不到实例，
/// 导致 [WMapConfig.onItemClosed] 永远无法触发。把控制器传给 [WMap] 即可。
class WMapController<T> {
  _WMapState<T>? _state;

  /// 是否已绑定到某个 [WMap]
  bool get isAttached => _state != null;

  void _attach(_WMapState<T> state) => _state = state;

  void _detach(_WMapState<T> state) {
    if (identical(_state, state)) _state = null;
  }

  /// 选中某个条目：等价于点地图上的 marker（相机动画 + [WMapConfig.onItemSelected]）。
  /// 用于「点底部列表里的门店 → 地图跟着跳」这类交互。
  Future<void> select(T item) async {
    await _state?.select(item);
  }

  /// 关闭选中：相机动到条目位置并触发 [WMapConfig.onItemClosed]。
  /// 未绑定（对应 WMap 还没挂载）时什么都不做。
  Future<void> closeSelection(T item) async {
    await _state?.closeSelection(item);
  }
}

/// 通用地图组件
///
/// 基于 [GoogleMap] 封装，职责仅限：
/// - 渲染地图与 Marker
/// - 管理相机动画（选中/关闭时的平滑移动）
/// - 暴露 [GoogleMapController] 供外部控制
///
/// 不内置任何业务 UI（列表面板、选中浮起、空状态等），
/// 业务方通过 [WMapConfig.onItemSelected] / [WMapConfig.onItemClosed]
/// 接收事件，自行构建业务 UI。
class WMap<T> extends StatefulWidget {
  /// 组件配置
  final WMapConfig<T> config;

  /// 地图区域（数据 + 控制器）
  final WMapZone<T> zone;

  /// 可选控制器：用于从业务侧关闭选中（[WMapController.closeSelection]）
  final WMapController<T>? controller;

  const WMap({
    super.key,
    required this.config,
    required this.zone,
    this.controller,
  });

  @override
  State<WMap<T>> createState() => _WMapState<T>();
}

class _WMapState<T> extends State<WMap<T>> {
  /// 当前选中的条目
  T? _selected;

  /// 最近一次应用到地图的相机位置（避免每次数据刷新都重置用户的手势）
  CameraPosition? _appliedCamera;

  @override
  void initState() {
    super.initState();
    _selected = null;
    _wire();
  }

  void _wire() {
    widget.zone.addMarkerTapListener(_select);
    widget.zone.addDataUpdatedListener(_handleDataUpdated);
    widget.controller?._attach(this);
  }

  void _unwire() {
    widget.zone.removeMarkerTapListener(_select);
    widget.zone.removeDataUpdatedListener(_handleDataUpdated);
  }

  @override
  void dispose() {
    _unwire();
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone != widget.zone ||
        oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      _unwire();
      _selected = null;
      _appliedCamera = null;
      _wire();
      // 换了 zone：把新数据的相机位置同步过去
      _syncCameraIfNeeded();
    }
  }

  /// 选中某个条目：更新选中态、通知业务、相机居中
  Future<void> select(T item) async {
    if (!mounted) return;
    setState(() => _selected = item);
    widget.config.onItemSelected?.call(item);
    final position = widget.zone.mapper.position(item);
    await _animateTo(
      position.latitude - widget.config.selectLatOffset,
      position.longitude,
      widget.config.selectZoom,
      item,
    );
  }

  /// Marker 点击（同步接口，直接交给 [select]）
  void _select(T item) => select(item);

  /// 关闭选中条目（由 [WMapController] 调用）
  Future<void> closeSelection(T item) async {
    if (!mounted) return;
    setState(() => _selected = null);
    final position = widget.zone.mapper.position(item);
    await _animateTo(
      position.latitude,
      position.longitude,
      widget.config.closeZoom,
      item,
    );
    widget.config.onItemClosed?.call(item);
  }

  /// 数据更新：重绘（图标可能刚异步加载完）、校验选中态、补一次相机同步
  void _handleDataUpdated() {
    if (!mounted) return;
    setState(() {});
    _validateSelected();
    _syncCameraIfNeeded();
  }

  /// 数据是异步到达时，`initialCameraPosition` 早就用过了（当时 maps 还是空），
  /// 地图会一直停在默认位置。这里在 zone 有了新相机位置后补一次移动。
  void _syncCameraIfNeeded() {
    final controller = widget.zone.googleMapController;
    final target = widget.zone.cameraPosition;
    if (controller == null || target == null) return;
    if (_sameCamera(_appliedCamera, target)) return;
    _appliedCamera = target;
    controller.moveCamera(CameraUpdate.newCameraPosition(target));
  }

  /// 选中态一致性校验：若选中条目已不在当前 maps 列表，则清除选中
  void _validateSelected() {
    final selected = _selected;
    if (selected == null) return;
    final selectedId = widget.zone.mapper.id(selected);
    final stillExists =
        widget.zone.maps?.any((a) => widget.zone.mapper.id(a) == selectedId) ??
            false;
    if (!stillExists && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selected = null);
      });
    }
  }

  /// 平滑移动相机到指定坐标并打开对应 Marker 的 InfoWindow。
  ///
  /// 必须 await 相机动画：动画进行中调用 `showMarkerInfoWindow` 会被随后的
  /// 相机移动覆盖掉，表现为「点了 marker 但 InfoWindow 不弹」。
  Future<void> _animateTo(double lat, double lng, double zoom, T item) async {
    final controller = widget.zone.googleMapController;
    if (controller == null) return;
    final markerId = MarkerId(widget.zone.mapper.id(item));
    _appliedCamera = CameraPosition(target: LatLng(lat, lng), zoom: zoom);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_appliedCamera!),
    );
    if (!mounted) return;
    if (widget.zone.markers.any((m) => m.markerId == markerId)) {
      // 校验 marker 是否存在再打开 InfoWindow，避免静默失败
      await controller.showMarkerInfoWindow(markerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    return GoogleMap(
      initialCameraPosition: zone.cameraPosition ??
          const CameraPosition(target: LatLng(0, 0), zoom: 1),
      onMapCreated: (GoogleMapController controller) {
        zone.googleMapController = controller;
        _appliedCamera = zone.cameraPosition;
      },
      onTap: widget.config.onMapTap == null
          ? null
          : (LatLng position) => widget.config.onMapTap?.call(position),
      padding: widget.config.padding,
      markers: zone.markers,
    );
  }
}

/// 地图组件配置类
///
/// 仅负责地图相机行为和事件回调，不包含任何 UI 样式配置。
class WMapConfig<T> {
  /// 选中条目时的缩放级别
  final double selectZoom;

  /// 关闭条目时的缩放级别
  final double closeZoom;

  /// 选中条目时的纬度偏移（向上偏移；0 表示不偏移，Marker 居中）
  final double selectLatOffset;

  /// 选中条目回调
  final ValueChanged<T>? onItemSelected;

  /// 关闭条目回调
  final ValueChanged<T>? onItemClosed;

  /// 点击地图空白处（不是 Marker）时回调，常用于「点空白关闭选中」
  final ValueChanged<LatLng>? onMapTap;

  /// 地图可视区域的内边距。
  ///
  /// 底部有选中卡片、顶部有筛选栏时用它把可视中心抬起来，
  /// 否则选中的 marker 会被卡片挡住。
  final EdgeInsets padding;

  const WMapConfig({
    this.selectZoom = 12,
    this.closeZoom = 11,
    this.selectLatOffset = 0.0,
    this.onItemSelected,
    this.onItemClosed,
    this.onMapTap,
    this.padding = EdgeInsets.zero,
  });

  /// 构建 WMap 组件
  WMap<T> build({required WMapZone<T> zone, WMapController<T>? controller}) {
    return WMap<T>(config: this, zone: zone, controller: controller);
  }
}
