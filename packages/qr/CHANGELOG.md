# Changelog

## 1.0.0

首次发布。

- 新增 `WQrView`：二维码 / 条形码扫描组件，支持单次与连续扫描
- 新增 `scanOnce` / `scanInterval`：扫码后暂停、相同内容去重
- 新增 `WQrViewState.restartScan()`：重新开始扫描
- 新增 `WQrController`：广播式扫描流与相机控制（暂停 / 恢复 / 翻转 / 闪光灯等）
- 应用生命周期：后台自动暂停相机，前台恢复
- 新增 `WQrViewOverlayShape`：扫描框颜色、边框、圆角与区域尺寸配置
- 相机与扫描流异常统一通过 `onError` 上报
- 依赖 `qr_code_scanner_plus` 2.1.2
