# w_tools_async_ui

`w_tools_async_ui` 是 `w_tools_async` 的**规范应用层**。核心包只提供 Controller /
State / Snapshot / 原语 View；本包把业务页面最常见的写法收敛成 4 个入口。

```text
单区块四态        → WAsyncSection
标准分页列表      → WAsyncPagedList
自定义滚动里的分页 → WAsyncPagedSliver
footer 文案       → WAsyncPagedStrings
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
- loading / error 外观走 `WAsyncTheme`；空态可用 `emptyBuilder` 覆盖。

## WAsyncPagedList

标准用法见 [packages/async_ui/README.md](../../packages/async_ui/README.md) 的「标准分页」；这里只记录边界：
内部持有 `RefreshController` 和 `SmartRefresher`，统一处理刷新 / 上拉 / footer / generation。

- 内部持有 `RefreshController` 和 `SmartRefresher`；
- 统一处理下拉刷新、上拉加载、footer 五种状态、重试和 generation；
- `loadMore` 失败只更新 footer，不清空列表；
- 页面在 controller 的 `initState` / `onInit` 调 `refresh()`；
- 不在组件内自动发起首屏请求。

## WAsyncPagedSliver

标准用法见 [packages/async_ui/README.md](../../packages/async_ui/README.md) 的「自定义滚动」；这里只记录边界：

- 只返回 `SliverMainAxisGroup`（四态 + footer）；
- 不包含 `SmartRefresher` / `RefreshController`；
- 给 NestedScrollView、overlap 卡片、自定义滚动壳使用；
- 标准页面优先用 `WAsyncPagedList`。

## WAsyncPagedStrings

分页 footer 的文案值对象，默认英文；项目传中文或其它语言。不要修改核心
`WAsyncStrings`。

## 边界

- 不包含 已删除的执行组合子（`parallel` / `pool` / `serial` / `first` / `map`）；
- 不包含全局 loading / toast / 登录失效；
- 不 import 任何项目设计系统；
- 不替代核心 `WAsyncView` / `WAsyncStateSliver`：库、设计系统和明确的自定义扩展
  仍可直接使用原语。

完整用法：[packages/async_ui/README.md](../../packages/async_ui/README.md)。
