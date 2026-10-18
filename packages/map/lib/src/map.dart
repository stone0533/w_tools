import 'package:flutter/material.dart';
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

/// 地图区域类
///
/// 持有 [GoogleMapController]、[markers] 集合、地图数据列表 [maps]，
/// 支持外部复用、跨组件共享控制器状态及通过 [update] 刷新数据。
///
/// 泛型 [T] 约束为 [WMapItem]，业务方传入自己的数据模型类型。
class WMapZone<T extends WMapItem> {
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

  /// Marker 点击回调列表（支持多个 [WMap] 共享同一 zone）
  final List<void Function(T)> _onMarkerTaps = [];

  /// 默认缩放级别
  final double defaultZoom;

  /// 数据更新回调（由 [WMap] 内部注册，用于刷新选中态一致性）
  void Function()? onDataUpdated;

  /// 注册 Marker 点击回调（[WMap] 在 initState 时调用）
  void addMarkerTapListener(void Function(T) listener) {
    _onMarkerTaps.add(listener);
  }

  /// 移除 Marker 点击回调（[WMap] 在 dispose 时调用）
  void removeMarkerTapListener(void Function(T) listener) {
    _onMarkerTaps.remove(listener);
  }

  /// 构造函数
  WMapZone({
    this.googleMapController,
    this.zoneId,
    this.name,
    this.maps,
    this.icon,
    this.defaultZoom = 11,
  }) {
    initMap();
  }

  /// 初始化地图
  ///
  /// 依据 [maps] 生成 [markers]，并以首个条目作为初始相机位置。
  /// 若 [maps] 为空，[cameraPosition] 保持为 null。
  void initMap() {
    markers.clear();
    maps?.forEach((element) {
      final markerId = MarkerId(
        element.id ?? element.name ?? hashCode.toString(),
      );
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(
            element.latitude ?? 0.0,
            element.longitude ?? 0.0,
          ),
          infoWindow: InfoWindow(title: element.name),
          icon: icon ?? BitmapDescriptor.defaultMarker,
          onTap: () {
            for (final listener in _onMarkerTaps) {
              listener(element);
            }
          },
        ),
      );
    });
    final first = maps?.firstOrNull;
    if (first != null) {
      cameraPosition = CameraPosition(
        target: LatLng(
          first.latitude ?? 0.0,
          first.longitude ?? 0.0,
        ),
        zoom: defaultZoom,
      );
    } else {
      cameraPosition = null;
    }
    onDataUpdated?.call();
  }

  /// 更新地图数据并重新初始化
  void update(List<T>? maps) {
    this.maps = maps;
    initMap();
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
class WMap<T extends WMapItem> extends StatefulWidget {
  /// 组件配置
  final WMapConfig<T> config;

  /// 地图区域（数据 + 控制器）
  final WMapZone<T> zone;

  const WMap({
    super.key,
    required this.config,
    required this.zone,
  });

  @override
  State<WMap<T>> createState() => _WMapState<T>();
}

class _WMapState<T extends WMapItem> extends State<WMap<T>> {
  /// 当前选中的条目
  T? _selected;

  @override
  void initState() {
    super.initState();
    _selected = null;
    // 注册 Marker 点击回调
    widget.zone.addMarkerTapListener(_select);
    // 注册数据更新回调（选中态一致性）
    widget.zone.onDataUpdated = _validateSelected;
  }

  @override
  void dispose() {
    widget.zone.removeMarkerTapListener(_select);
    if (widget.zone.onDataUpdated == _validateSelected) {
      widget.zone.onDataUpdated = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zone != widget.zone) {
      oldWidget.zone.removeMarkerTapListener(_select);
      oldWidget.zone.onDataUpdated = null;
      widget.zone.addMarkerTapListener(_select);
      widget.zone.onDataUpdated = _validateSelected;
      _selected = null;
    }
  }

  /// 选中某个条目：更新选中态并居中地图
  void _select(T item) {
    setState(() => _selected = item);
    _animateTo(
      (item.latitude ?? 0.0) - widget.config.selectLatOffset,
      item.longitude ?? 0.0,
      widget.config.selectZoom,
      item,
    );
    widget.config.onItemSelected?.call(item);
  }

  /// 关闭选中条目（供外部调用）
  void closeSelection(T item) {
    setState(() => _selected = null);
    _animateTo(
      item.latitude ?? 0.0,
      item.longitude ?? 0.0,
      widget.config.closeZoom,
      item,
    );
    widget.config.onItemClosed?.call(item);
  }

  /// 选中态一致性校验：若选中条目已不在当前 maps 列表，则清除选中
  void _validateSelected() {
    if (_selected == null || _selected?.id == null) return;
    final stillExists = widget.zone.maps
        ?.any((a) => a.id?.compareTo(_selected!.id ?? '') == 0) ?? false;
    if (!stillExists && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selected = null);
      });
    }
  }

  /// 平滑移动相机到指定坐标并打开对应 Marker 的 InfoWindow
  void _animateTo(double lat, double lng, double zoom, T item) {
    final controller = widget.zone.googleMapController;
    if (controller == null) return;
    final markerIdStr = item.id ?? item.name ?? item.hashCode.toString();
    final markerId = MarkerId(markerIdStr);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom),
      ),
    );
    // 校验 marker 是否存在再打开 InfoWindow，避免静默失败
    if (widget.zone.markers.any((m) => m.markerId == markerId)) {
      controller.showMarkerInfoWindow(markerId);
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
      },
      markers: zone.markers,
    );
  }
}

/// 地图组件配置类
///
/// 仅负责地图相机行为和事件回调，不包含任何 UI 样式配置。
class WMapConfig<T extends WMapItem> {
  /// 选中条目时的缩放级别
  final double selectZoom;

  /// 关闭选中条目时的缩放级别
  final double closeZoom;

  /// 选中条目时的纬度偏移（向上偏移；0 表示不偏移，Marker 居中）
  final double selectLatOffset;

  /// 选中条目回调
  final ValueChanged<T>? onItemSelected;

  /// 关闭选中条目回调
  final ValueChanged<T>? onItemClosed;

  const WMapConfig({
    this.selectZoom = 12,
    this.closeZoom = 11,
    this.selectLatOffset = 0.0,
    this.onItemSelected,
    this.onItemClosed,
  });

  /// 构建 WMap 组件
  WMap<T> build({required WMapZone<T> zone}) {
    return WMap<T>(config: this, zone: zone);
  }
}
