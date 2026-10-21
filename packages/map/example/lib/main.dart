import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:w_tools_map/w_tools_map.dart';

/// 业务模型：只需实现 WMapItem 的四个 getter。
class Shop implements WMapItem {
  const Shop({this.id, this.name, this.latitude, this.longitude});

  @override
  final String? id;

  @override
  final String? name;

  @override
  final double? latitude;

  @override
  final double? longitude;
}

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'w_tools_map example',
      home: MapExamplePage(),
    );
  }
}

class MapExamplePage extends StatefulWidget {
  const MapExamplePage({super.key});

  @override
  State<MapExamplePage> createState() => _MapExamplePageState();
}

class _MapExamplePageState extends State<MapExamplePage> {
  late final WMapZone<Shop> zone;
  Shop? _selected;

  /// 业务侧控制器：用来关闭选中（对应 WMapConfig.onItemClosed 的触发）
  final mapController = WMapController<Shop>();

  @override
  void initState() {
    super.initState();
    zone = WMapZone<Shop>(
      maps: const [
        Shop(id: 'hkg', name: '香港站', latitude: 22.2849, longitude: 114.1581),
        Shop(id: 'kowloon', name: '九龍站', latitude: 22.3049, longitude: 114.1616),
        Shop(id: 'shatin', name: '沙田站', latitude: 22.3826, longitude: 114.1874),
      ],
      defaultZoom: 11,
      // 每个门店用不同颜色的图标
      iconBuilder: (shop) => BitmapDescriptor.defaultMarkerWithHue(
        shop.id == 'hkg'
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueAzure,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('w_tools_map example')),
      body: Stack(
        children: [
          WMap<Shop>(
            controller: mapController,
            config: WMapConfig<Shop>(
              selectZoom: 16,
              closeZoom: 11,
              // 底部卡片会挡住地图，留出 140 的内边距
              padding: const EdgeInsets.only(bottom: 140, top: 80),
              // 选中时把相机往上挪一点，给底部卡片留位置
              selectLatOffset: 0.002,
              onItemSelected: (item) => setState(() => _selected = item),
              onItemClosed: (_) => setState(() => _selected = null),
            ),
            zone: zone,
          ),
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                child: ListTile(
                  title: Text(_selected!.name ?? ''),
                  subtitle: Text(
                    '${_selected!.latitude}, ${_selected!.longitude}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // 走控制器关闭：相机动回去 + onItemClosed 回调
                      final selected = _selected;
                      if (selected != null) {
                        mapController.closeSelection(selected);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
