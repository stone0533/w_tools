# w_tools_map 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-04 | `closeSelection` 只清选中与回位，不隐藏 InfoWindow，业务卡片关了但气泡还在 | ✅ 1.3.1（49e07e0）：关闭时先 `hideMarkerInfoWindow` 再回位 |
