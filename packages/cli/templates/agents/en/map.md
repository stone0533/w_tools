- **Maps**: use `WMap` + `WMapZone`, not raw `GoogleMap`; marker ids must be stable, and
  `json_serializable` models should use `WMapItemMapper`; Google Maps API key required.
