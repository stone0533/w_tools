- **Maps**: use `WMap` + `WMapZone` (configure via `WMapOptions`), not raw `GoogleMap`;
  marker ids must be stable, and `json_serializable` models should use `WMapItemMapper`;
  Google Maps API key required.
