> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0016：WAsyncPagedList 标准下拉刷新样式

- 状态：已采纳（2026-11-19）
- 相关：[`packages/async_ui/lib/src/refresh_indicator_style.dart`](../../packages/async_ui/lib/src/refresh_indicator_style.dart)、
  [`docs/adr/0011-api-surface-budget.md`](0011-api-surface-budget.md)、
  [`docs/modules/async_ui_module.md`](../modules/async_ui_module.md)

## 背景

`w_tools_async_ui 2.0` 去掉了 `pull_to_refresh`，标准分页壳改用 Flutter
`RefreshIndicator`。这解决了布局期 `setState` 和依赖维护问题，但标准壳没有暴露
`RefreshIndicator` 的样式参数，接入方无法使用品牌色 / 背景色，默认会跟
`ColorScheme.primary` 走。

完整自定义刷新头、完成 / 失败文案不是 `RefreshIndicator` 的能力；这类需求应使用
`WAsyncPagedSliver` + 自己的滚动壳，而不是把标准壳重新做成 `SmartRefresher`。

## 决策

1. 新增 `WAsyncRefreshIndicatorStyle`，只承载 Flutter `RefreshIndicator` 的样式：
   `color` / `backgroundColor` / `strokeWidth` / `displacement` / `edgeOffset` /
   `triggerMode`。
2. `WAsyncPagedList` 增加 optional `refreshIndicatorStyle`；不传时保持 Flutter 默认。
3. 不增加 `refreshIndicatorBuilder`，不重新引入 `pull_to_refresh`。
4. 自定义刷新头 / 文案由 `WAsyncPagedSliver` + 自建壳负责。
5. 新公开类型走 API budget exception；`async_ui` growth 从 8 调到 12，避免为省
   预算拆样式对象。

## 后果

正向：

- 标准壳可以配置品牌色 / 背景 / 线与位置；
- 不破坏现有 `WAsyncPagedList` API；
- 不引入第二个 controller；
- 不重新引入 `pull_to_refresh`。

代价：

- 新公开类型，需要 ADR + exception；
- 6 个字段接近当前预算上限，所以显式调高 `async_ui` growth；
- 仍然不支持自定义刷新头动画 / 完成失败文案。

## 落地结果

- 状态：未执行
- 证据：待 2.0.0 发布后回填
- 与决策的偏差：无

## 备选方案

1. **只加 3 个颜色字段**：更省 API，但位置 / 触发模式仍要后续补字段；否决。
2. **加 `refreshIndicatorBuilder`**：无法解决自定义头的物理 / 状态机，复杂度转移给业务；
   否决。
3. **把样式放进 core `WAsyncTheme`**：core 不应认识 `RefreshIndicator`；否决。
4. **保留 pull_to_refresh**：与 2.0 去依赖目标冲突；否决。

## 重新评估的条件

- 需要自定义刷新头动画 / 完成失败文案；
- 多页面重复传同一套样式，需要全局主题；
- `RefreshIndicator` 样式参数在 Flutter 新版本变化。
