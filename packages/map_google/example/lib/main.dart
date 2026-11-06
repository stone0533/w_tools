import 'package:flutter/material.dart';
import 'package:w_tools_map/w_tools_map.dart';
import 'package:w_tools_map_google/w_tools_map_google.dart';

void main() {
  runApp(const MapExampleApp());
}

class MapExampleApp extends StatelessWidget {
  const MapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_map 示例',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0EA5E9),
        useMaterial3: true,
      ),
      home: const ShopMapPage(),
    );
  }
}

/// 普通业务模型，不实现 WMapItem，模拟 json_serializable 生成的模型。
class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

class ShopMapPage extends StatefulWidget {
  const ShopMapPage({super.key});

  @override
  State<ShopMapPage> createState() => _ShopMapPageState();
}

class _ShopMapPageState extends State<ShopMapPage> {
  static const _shops = <Shop>[
    Shop(id: 'bund', name: '外滩店', latitude: 31.2400, longitude: 121.4900),
    Shop(id: 'xintiandi', name: '新天地店', latitude: 31.2190, longitude: 121.4750),
    Shop(id: 'jingan', name: '静安寺店', latitude: 31.2230, longitude: 121.4450),
  ];

  static final _mapper = WMapItemMapper<Shop>(
    id: (shop) => shop.id,
    name: (shop) => shop.name,
    position: (shop) => (
      latitude: shop.latitude,
      longitude: shop.longitude,
    ),
  );

  late final WMapZone<Shop> _zone;
  final _controller = WMapController<Shop>();
  Shop? _selected;
  bool _onlyJingan = false;

  @override
  void initState() {
    super.initState();
    _zone = WMapZone<Shop>(
      maps: _shops,
      mapper: _mapper,
      defaultZoom: 12,
    );
  }

  void _toggleFilter() {
    final selected = _selected;
    if (selected != null) {
      // 先让地图关闭选中（隐藏 InfoWindow / 复位相机），再更新数据
      _controller.closeSelection(selected);
    }
    setState(() {
      _onlyJingan = !_onlyJingan;
      _zone.update(
        _onlyJingan ? _shops.where((shop) => shop.id == 'jingan').toList() : _shops,
      );
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('门店地图'),
        actions: [
          IconButton(
            tooltip: _onlyJingan ? '显示全部门店' : '只看静安店',
            onPressed: _toggleFilter,
            icon: Icon(_onlyJingan ? Icons.filter_alt : Icons.filter_alt_off),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WMap<Shop>(
              zone: _zone,
              controller: _controller,
              config: WMapOptions<Shop>(
                selectZoom: 15,
                closeZoom: 12,
                selectLatOffset: 0.002,
                padding: EdgeInsets.only(bottom: _selected == null ? 0 : 150),
                onItemSelected: (shop) {
                  setState(() => _selected = shop);
                },
                onItemClosed: (shop) {
                  setState(() => _selected = null);
                },
                onMapTap: (_) {
                  final selected = _selected;
                  if (selected != null) {
                    _controller.closeSelection(selected);
                  }
                },
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _selected == null
                ? _ShopPicker(
                    shops: _zone.maps ?? const <Shop>[],
                    onSelect: (shop) => _controller.select(shop),
                  )
                : _SelectedShopCard(
                    shop: _selected!,
                    onClose: () => _controller.closeSelection(_selected!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShopPicker extends StatelessWidget {
  const _ShopPicker({required this.shops, required this.onSelect});

  final List<Shop> shops;
  final ValueChanged<Shop> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('点击 marker 或下方按钮选中门店'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final shop in shops)
                  ActionChip(
                    label: Text(shop.name),
                    onPressed: () => onSelect(shop),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedShopCard extends StatelessWidget {
  const _SelectedShopCard({required this.shop, required this.onClose});

  final Shop shop;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${shop.latitude}, ${shop.longitude}'),
                ],
              ),
            ),
            TextButton(onPressed: onClose, child: const Text('关闭')),
          ],
        ),
      ),
    );
  }
}
