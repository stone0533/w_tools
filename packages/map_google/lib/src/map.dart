import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:w_tools_map/w_tools_map.dart';

part 'map_zone.dart';

/// [WMap] 的控制器：从业务 UI 侧触发选中 / 关闭。
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
///
/// ```dart
/// final zone = WMapZone<Store>(
///   maps: stores,
///   initialCamera: const CameraPosition(target: LatLng(31.2, 121.5), zoom: 11),
///   mapper: WMapItemMapper<Store>(
///     id: (s) => s.id,
///     name: (s) => s.name,
///     position: (s) => (latitude: s.lat, longitude: s.lng),
///   ),
/// );
///
/// WMap<Store>(
///   zone: zone,
///   config: WMapConfig<Store>(onItemSelected: (store) {}),
/// );
/// ```
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

  /// 当前 GoogleMap 的控制器（dispose 时只清理自己创建的那个）
  GoogleMapController? _mapController;

  /// 是否已经拿到过可渲染数据（用于 initialCamera → 首条数据的相机补同步）
  bool _hasRenderableData = false;

  /// 选中 / 关闭操作序号：await 后只有最后一次操作能生效
  int _operation = 0;

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

  void _unwire() => _unwireZone(widget.zone);

  void _unwireZone(WMapZone<T> zone) {
    zone.removeMarkerTapListener(_select);
    zone.removeDataUpdatedListener(_handleDataUpdated);
  }

  @override
  void dispose() {
    _unwire();
    widget.controller?._detach(this);
    if (identical(widget.zone.googleMapController, _mapController)) {
      widget.zone.googleMapController = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone != widget.zone || oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      _unwireZone(oldWidget.zone);
      _selected = null;
      _appliedCamera = null;
      _hasRenderableData = false;
      // 控制器只由本 State 持有：迁移给新 zone，避免新 zone 的 select 静默失效
      if (_mapController != null && !identical(oldWidget.zone, widget.zone)) {
        oldWidget.zone.googleMapController = null;
        widget.zone.googleMapController = _mapController;
      }
      _wire();
      // 换了 zone：把新数据的相机位置同步过去
      _syncCameraIfNeeded();
    }
  }

  /// 选中某个条目：更新选中态、通知业务、相机居中
  Future<void> select(T item) async {
    if (!mounted) return;
    final operation = ++_operation;
    setState(() => _selected = item);
    widget.config.onItemSelected?.call(item);
    final position = widget.zone.mapper.position(item);
    await _animateTo(
      position.latitude - widget.config.selectLatOffset,
      position.longitude,
      widget.config.selectZoom,
      item,
      showInfoWindow: false,
    );
    // 快速连点 A/B：只有最后一次操作能开窗，避免气泡与业务卡片错位
    if (!mounted || operation != _operation || _selected != item) return;
    final controller = _controllerOrZone;
    final markerId = MarkerId(widget.zone.mapper.id(item));
    if (controller != null && widget.zone.markers.any((m) => m.markerId == markerId)) {
      await controller.showMarkerInfoWindow(markerId);
    }
  }

  /// Marker 点击（同步接口，直接交给 [select]）
  void _select(T item) => select(item);

  /// 关闭选中条目（由 [WMapController] 调用）
  Future<void> closeSelection(T item) async {
    if (!mounted) return;
    final operation = ++_operation;
    setState(() => _selected = null);

    final controller = _controllerOrZone;
    final markerId = MarkerId(widget.zone.mapper.id(item));
    if (controller != null) {
      // 先隐藏气泡，再回位；不能走 _animateTo 的「自动开窗」分支
      await controller.hideMarkerInfoWindow(markerId);
    }

    final position = widget.zone.mapper.position(item);
    await _animateTo(
      position.latitude,
      position.longitude,
      widget.config.closeZoom,
      item,
      showInfoWindow: false,
    );

    // 若期间用户又选中了别的条目，旧的关闭回调不能再触发
    if (!mounted || operation != _operation || _selected != null) return;
    widget.config.onItemClosed?.call(item);
  }

  /// 数据更新：重绘（图标可能刚异步加载完）、校验选中态、补一次相机同步
  void _handleDataUpdated() {
    if (!mounted) return;
    setState(() {});
    _validateSelected();
    // initialCamera 占位时 _appliedCamera 一开始就非 null；只有首次拿到可渲染
    // 数据时才允许补一次同步，之后的数据刷新不再抢相机。
    if (!_hasRenderableData && widget.zone.markers.isNotEmpty) {
      _hasRenderableData = true;
      _appliedCamera = null;
    }
    if (_appliedCamera == null) _syncCameraIfNeeded();
  }

  /// 数据是异步到达时，`initialCameraPosition` 早就用过了（当时 maps 还是空），
  /// 地图会一直停在默认位置。这里在 zone 有了新相机位置后补一次移动。
  void _syncCameraIfNeeded() {
    final controller = _controllerOrZone;
    final target = widget.zone.cameraPosition;
    if (controller == null || target == null) return;
    if (_appliedCamera == target) return;
    _appliedCamera = target;
    controller.moveCamera(CameraUpdate.newCameraPosition(target));
  }

  /// 选中态一致性校验：若选中条目已不在当前 maps 列表，则清除选中
  void _validateSelected() {
    final selected = _selected;
    if (selected == null) return;
    final selectedId = widget.zone.mapper.id(selected);
    // marker 是按 isValid 过滤后生成的，必须用它判断“还画着没有”
    final stillExists = widget.zone.markers.any((m) => m.markerId.value == selectedId);
    if (!stillExists && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selected = null);
        widget.config.onItemClosed?.call(selected);
      });
    }
  }

  /// 平滑移动相机到指定坐标并打开对应 Marker 的 InfoWindow。
  ///
  /// 必须 await 相机动画：动画进行中调用 `showMarkerInfoWindow` 会被随后的
  /// 相机移动覆盖掉，表现为「点了 marker 但 InfoWindow 不弹」。
  Future<void> _animateTo(
    double lat,
    double lng,
    double zoom,
    T item, {
    bool showInfoWindow = true,
  }) async {
    final controller = _controllerOrZone;
    if (controller == null) return;
    final markerId = MarkerId(widget.zone.mapper.id(item));
    _appliedCamera = CameraPosition(target: LatLng(lat, lng), zoom: zoom);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_appliedCamera!),
    );
    if (!mounted || !showInfoWindow) return;
    if (widget.zone.markers.any((m) => m.markerId == markerId)) {
      // 校验 marker 是否存在再打开 InfoWindow，避免静默失败
      await controller.showMarkerInfoWindow(markerId);
    }
  }

  /// 优先用本 State 持有的控制器；换 zone 后也能继续工作
  GoogleMapController? get _controllerOrZone => _mapController ?? widget.zone.googleMapController;

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final initialCamera =
        zone.cameraPosition ?? const CameraPosition(target: LatLng(0, 0), zoom: 1);
    return GoogleMap(
      initialCameraPosition: initialCamera,
      onMapCreated: (GoogleMapController controller) {
        zone.googleMapController = controller;
        _mapController = controller;
        _appliedCamera = initialCamera;
        _hasRenderableData = zone.markers.isNotEmpty;
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
}
