export 'src/map.dart';

// 公开 API 里出现的地图类型由本包统一转出，消费方无需再直接依赖 google_maps_flutter。
export 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        GoogleMapController,
        InfoWindow,
        LatLng,
        Marker,
        MarkerId;
