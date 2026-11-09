- **Scanning**: use `WQrView`, not the raw `QRView`; create a `WQrController` in the page and pass
  `WQrView(controller: ...)`; restart with `controller.restart()` (`WQrViewState` was removed).
- **Once vs continuous**: `scanOnce` decides whether scanning pauses after a hit (default true, only
  applies when `onScanned` is set); use `scanOnce: false` + `scanInterval` for continuous scanning;
  without `onScanned` the camera never auto-pauses.
