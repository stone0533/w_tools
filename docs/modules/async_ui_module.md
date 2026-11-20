# w_tools_async_ui

`w_tools_async_ui` 是 `w_tools_async` 的**规范应用层**。核心包只提供 Controller /
State / Snapshot / 原语 View；本包把业务页面最常见的写法收敛成 3 个入口。

```text
单区块四态         → WAsyncSection
标准分页列表       → WAsyncPagedList
自定义滚动里的分页 → WAsyncPagedSliver
```

## WAsyncSection

```dart
WAsyncSection<List<Gift>>(
  controller: gifts,
  builder: (context, data) => GiftList(data),
)
```

- 内部使用 `WAsyncView`；
- 失败态默认把重试接到 `WAsyncController.load`；
- 页面在 controller 的 `initState` / `onInit` 调 `load()`；
- loading / error 外观默认走 `WAsyncTheme`；per-block 可传
  `loadingBuilder` / `errorBuilder` / `errorBannerBuilder` / `refreshingBuilder`；
- 空态可用 `emptyBuilder` 覆盖；
- 自定义重试可传 `onRetry`，不传时用 `controller.load`。

## WAsyncPagedList

标准用法见 [packages/async_ui/README.md](../../packages/async_ui/README.md) 的「标准分页」；这里只记录边界：

- 下拉刷新使用 Flutter `RefreshIndicator`；
- 滚动接近底部时按 `autoLoadThreshold` 自动 `controller.loadMore()`；
- 默认 footer 读 `controller.snapshot`，展示 loading / 失败重试 / 没有更多；
  文案（含 noMore）走 `WAsyncTheme.strings`；
- `footerBuilder` 可替换 footer；`reloadRequests` 负责程序化刷新；
- `refreshIndicatorStyle` 配置标准 `RefreshIndicator` 的颜色 / 背景 / 线宽 / 位移 /
  触发模式；自定义刷新头仍用 `WAsyncPagedSliver`；
- 不持有外部刷新控制器；需要完全自定义刷新头 / 上拉壳时用 `WAsyncPagedSliver`；
- 标准壳的 loading / error / errorBanner 走 `WAsyncTheme`；需要 per-list 定制时用
  `WAsyncPagedSliver`；
- 不在组件内自动发起首屏请求。

## WAsyncPagedSliver

标准用法见 [packages/async_ui/README.md](../../packages/async_ui/README.md) 的「自定义滚动」；这里只记录边界：

- 只返回四态 sliver（`WAsyncStateSliver<List<T>>`）；
- 支持 `WAsyncPagedSliver.custom(readySliverBuilder: ...)`（叠卡 / 自定义 sliver）；
- 不包含刷新壳 / footer / 文案；header / footer 由调用方自己的滚动壳负责；
- 自建 `RefreshIndicator` 时传 `onRetry: gifts.refresh`，或接自己的刷新入口；
- 给 NestedScrollView、overlap 卡片、自定义滚动壳使用；
- 标准页面优先用 `WAsyncPagedList`。

## 边界

- 不包含已删除的执行组合子（`parallel` / `pool` / `serial` / `first` / `map`）；
- 不包含全局 loading / toast / 登录失效；
- 不 import 任何项目设计系统；
- 不替代核心 `WAsyncView` / `WAsyncStateSliver`：库、设计系统和明确的自定义扩展
  仍可直接使用原语。

完整用法：[packages/async_ui/README.md](../../packages/async_ui/README.md)。
