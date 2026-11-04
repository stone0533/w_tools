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

  /// 该条目是否可以渲染（返回 false 时跳过，不生成 Marker）。
  ///
  /// 默认 mapper 会跳过经纬度缺失的条目；自定义 mapper 不传时全部渲染。
  final bool Function(T item)? isValid;

  const WMapItemMapper({
    required this.id,
    required this.position,
    this.name,
    this.isValid,
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
    // 经纬度缺失的条目不要画到 (0,0)，直接跳过
    isValid: (item) {
      final it = item as WMapItem;
      return it.latitude != null && it.longitude != null;
    },
  );
}

/// 默认 mapper 的前置校验：`T` 未实现 [WMapItem] 时给出可读错误，
/// 而不是在首次渲染时抛裸 `_TypeError`。
WMapItemMapper<T> defaultMapItemMapper<T>() {
  if (<T>[] is! List<WMapItem>) {
    throw ArgumentError(
      'WMapZone<$T> 没有传 mapper，且 $T 未实现 WMapItem。'
      '请传 WMapZone(mapper: WMapItemMapper(id: ..., position: ...))；'
      'json_serializable 生成的模型只能用这种方式。',
    );
  }
  return wMapItemMapper<T>();
}
