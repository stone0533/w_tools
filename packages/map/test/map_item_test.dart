import 'package:test/test.dart';
import 'package:w_tools_map/w_tools_map.dart';

class _Item implements WMapItem {
  _Item(this.id, this.name, this.latitude, this.longitude);
  @override
  final String? id;
  @override
  final String? name;
  @override
  final double? latitude;
  @override
  final double? longitude;
}

void main() {
  test('默认 mapper 使用稳定 id 并过滤缺失坐标', () {
    final mapper = wMapItemMapper<_Item>();
    final item = _Item('store-1', 'Store', 31.2, 121.5);
    expect(mapper.id(item), 'store-1');
    expect(mapper.position(item), (latitude: 31.2, longitude: 121.5));
    expect(mapper.isValid!(item), isTrue);
    expect(mapper.isValid!(_Item(null, 'bad', null, 1)), isFalse);
  });
}
