# Async 模块

`w_tools_async` 负责异步执行、四态状态、Controller、分页与异步视图。

- 页面区块：`WAsyncController` + `WAsyncView`。
- 纯执行：`WAsync.tryRun` / `WAsync.run` / `WAsync.retry` / `WAsync.timeout` / `WAsync.tryAll`。
- 分页：`WAsyncPagedController` + `WAsyncPagedSnapshot`。
- 全局默认视图：`WAsyncTheme`。

> 本页只讲**架构、职责边界与行为约定**；完整代码示例统一看
> [`packages/async/README.md`](../../packages/async/README.md)。两处不要各写一份可运行代码，
> 避免默认值 / 参数在两边漂移。

## 快速判断

| 需求 | 入口 |
| --- | --- |
| 页面区块四态 | `WAsyncController` + `WAsyncView` |
| 滚动页 | `WAsyncView`（滚动组件放进 `readyBuilder`） |
| Sliver | `WAsyncStateSliver` |
| 分页 | `WAsyncPagedController` |
| 分页 footer 状态 | `WAsyncPagedSnapshot.footerStatus` |
| 纯执行，不抛异常 | `WAsync.tryRun` |
| 纯执行，失败抛异常 | `WAsync.run` |
| 重试 / 超时 | `WAsync.retry` / `WAsync.timeout` |
| 独立区块并行，保留每个结果 | `WAsync.tryAll` |
| 全局默认 loading / empty / error | `WAsyncTheme` / `WAsyncStrings` |

## 模块结构

```text
lib/src/task/
  async_task.dart              # WAsync 执行入口
  async_result.dart            # WAsyncResult / Success / Failure / Cancelled
  cancel_token.dart            # WCancelToken / WCancellationException
lib/src/state/
  async_state.dart             # WAsyncState / WAsyncStatus
  async_controller.dart        # WAsyncController
  async_paged_controller.dart  # WAsyncPagedController / WAsyncPage / WAsyncPagedSnapshot
lib/src/view/
  async_view.dart              # WAsyncView
  async_state_sliver.dart      # WAsyncStateSliver
  async_theme.dart             # WAsyncTheme
  async_theme_views.dart       # 默认视图解析（内部，不从 barrel 导出）
  async_strings.dart / async_error_view.dart / async_error_banner.dart
```

## 1. WAsync

`WAsync` 不依赖 Widget；没有 UI 状态时直接用。

### 执行入口

| 方法 | 语义 |
| --- | --- |
| `tryRun` | 返回 `WAsyncResult`，不抛业务异常 |
| `run` | 返回成功值；失败抛原始异常 |
| `retry` | 重试后返回成功值；最终失败抛异常 |
| `timeout` | 超时抛 `TimeoutException` |
| `tryAll` | 并发执行任务工厂，单个失败不抛错，每个结果按输入顺序返回 |

普通并发直接用 `Future.wait` / `Future.any`；本包只保留和「多区块页面」直接相关的入口。
参数错误（`concurrency < 1`、负数的 `retryCount` / `retryDelay` / `timeout`）以失败的
Future 返回 `ArgumentError`。

### 行为约定

- `WAsyncFailure.isProgrammingError` 区分 `Error`（TypeError / StateError）与业务异常；
- `onError` 只是失败通知，不改变返回值，也不会吞 `run` / `retry` / `timeout` 的异常；
  `onError` / `onRetry` 自身抛错会被忽略；
- `WAsyncHooks` 是回调值对象；`WAsyncExecutor` 携带默认 hooks，在 composition root
  创建并注入；单次 `hooks` 可覆盖，`WAsyncHooks.none` 可关闭默认；
- 没有全局 `defaultHooks`；默认配置用 `WAsyncExecutor` 实例；
- `run` / `tryRun` / `retry` / `timeout` 支持 `onStart` / `onFinally`：`onStart` 在任务前，
  `onFinally` 在成功 / 失败 / 取消后（且在 `onError` 之后）；已取消 token 不触发；
- `retry` / `timeout` 的钩子包住整次操作，不按 attempt 重复；`onRetry` 仍按 attempt 调用；
- `tryAll` 的 `onStart` / `onFinally` 是 **batch-level**，整批各一次；空集合 / 已取消 token 不触发；
- 成功结果用返回值 / `WAsyncSuccess`，不提供 `onSuccess`；
- `onStart` / `onFinally` 自身异常被忽略，不影响任务结果；
- executor 在 composition root 创建一次；测试创建独立 executor，不依赖全局重置；
- `WAsyncController` / `WAsyncPagedController` 内部 `load` / `refresh` / `loadMore`
  不读取 executor hooks；页面四态由 view 管理；
- `tryAll` 的 `onError` 按**失败任务个数**通知，不是按批次；
- 取消是协作式的：`WCancelToken` 在开始、结束、重试等待等边界检查，不中止已经开始的
  Future；取消后不可复用；
- 取消与失败同轮竞态：非 `Error` 按取消处理，`Error` 仍返回 `WAsyncFailure`，避免把编程
  错误吞成取消。

完整用法：[README 执行结果](../../packages/async/README.md#执行结果) ·
[独立区块并行](../../packages/async/README.md#独立区块并行) ·
[重试与超时](../../packages/async/README.md#重试与超时) ·
[取消](../../packages/async/README.md#取消)

## 2. WAsyncState

四态快照：`loading` / `ready` / `empty` / `failed`。约定：

- 首次请求发出前是 `loading`，不能用 `empty` 占位；
- 请求成功但结果为空才是 `empty`；
- 请求失败是 `failed`，与「没有数据」是两种状态；
- 已有数据时刷新失败用 `failed` + `previousData` 保留旧数据；
- `isRefreshing` 只表示「有旧数据时的 loading」，首屏 / 重试仍看 `isLoading`；
- `WAsyncState.list` 把 null / 空列表转为 `empty`，但不复制、不包装输入列表；
- 相等性是字段浅比较；列表按引用比较，不按内容比较。

状态读取：`when` 四态全覆盖，或 `status` + `data` / `error` 手写分支。
类型分工见 [README 状态 / 结果分不清时](../../packages/async/README.md#四态状态)。

## 3. Controller

### WAsyncController

一个区块一个 Controller。loader 统一接收 `WCancelToken`；不需要取消时写 `(_) => ...`。

- `load()` 取消上一次请求；旧请求返回后不会覆盖新状态；
- `WAsyncController.list` 额外保留空列表 → empty、`state.data` unmodifiable；
- `replaceData` 取消在飞 `load`，旧结果不写回；
- `onError` 只是失败兜底通知，四态仍由 Controller 维护；
- `isEmpty` 是同步回调，不要抛错：`load()` 会把回调抛错转为 `failed` 并通知 `onError`；
  `replaceData()` 会同步抛出（编程错误直接暴露）。

### WAsyncPagedController

loader 统一返回 `WAsyncPage`（items + 可选 hasMore）。

- `refresh()` 重新加载第一页；刷新在飞时再次调用会取消旧请求，旧结果不写回；
- `loadMore()` 只追加，失败只写 `snapshot.loadMoreError`，不清空列表；
- `hasMore` 为 null 时「本页非空即还有更多」；
- `replaceData(data, {bool? hasMore})` 取消在飞 refresh / loadMore；
- 观察入口只有两个：`state`（四态，喂给 `WAsyncView`）与 `snapshot`（分页状态）；
- `onError` 里重入 `refresh` / `replaceData` 时，`loadMore` 的 generation 守卫会丢弃旧失败，
  不把 stale `loadMoreError` 写回新状态。

#### 分页 footer 状态

`WAsyncPagedSnapshot` 是分页的唯一观察快照：

| 字段 | 作用 |
| --- | --- |
| `state` | `WAsyncState<List<T>>`，直接喂 `WAsyncView` |
| `footerStatus` | hidden / loading / failed / noMore / loadMore |
| `loadMoreError` | 最近一次追加失败 |
| `hasMore` | 是否还有下一页 |
| `isLoadingMore` | `footerStatus == loading` |

footer 用 `AnimatedBuilder(animation: controller.snapshot)` 重建。派生规则（按优先级）：

- 还没有数据（首屏 loading / empty / 整页 failed）→ `hidden`；
- refresh 进行中 → `hidden`（`loadMore` 会被忽略）；
- `loadMoreError` 非空 → `failed`；
- 正在追加 → `loading`；
- 没有更多：成功翻过页 → `noMore`，第一页就到底 → `hidden`；
- 其余 → `loadMore`。

完整代码与分页壳见 [paged-list 配方](../recipes/paged-list.md)。

## 4. View

`WAsyncView` 渲染四态，`onRetry` 为 `VoidCallback?`；为 null 时默认错误视图不渲染按钮。

| 能力 | 约定 |
| --- | --- |
| loading / empty / error | 未传 per-view builder 时回退到 `WAsyncTheme` |
| refreshing / errorBanner | 宽高都有界时占固定槽，内容让位；任一维无界时是内容盒 overlay |
| ready / refreshing / failed + 旧数据 | 共用同一层容器，状态切换不重建 `readyBuilder` 子树 |
| 默认错误视图 | 只显示标题，不渲染异常原文；详情走 `onError` / 日志 / 自定义 builder |
| 滚动内容 | 滚动组件放进 `readyBuilder`，不要包在 `WAsyncView` 外面 |

`WAsyncStateSliver` 用于 `CustomScrollView`：

- ready → `readySliverBuilder`；
- loading / empty / failed（无数据）→ `SliverFillRemaining`；
- failed + 旧数据 → 错误条（列表上方）+ ready sliver；
- refreshing + 旧数据 → ready sliver，刷新进度由外层刷新壳负责；
- 始终返回同一个 `SliverMainAxisGroup`，ready 子树不会被重建。

`readySliverBuilder` 必须返回 sliver；loading / empty / error 的 theme builder 返回普通
Widget（不是 sliver），组件会自己包 `SliverFillRemaining`。

## 5. Theme

`WAsyncTheme` 放在 App 根部，统一默认视图与文案。

| 字段 | 作用 |
| --- | --- |
| `loadingBuilder` / `emptyBuilder` | 普通视图与 sliver 共用的 loading / empty |
| `errorBuilder` / `errorBannerBuilder` | 整块错误 / 刷新失败错误条 |
| `refreshingBuilder` | 刷新进度 |
| `strings` | `WAsyncStrings` 文案 |

同一组 builder 同时作用于 `WAsyncView` 与 `WAsyncStateSliver`；builder 必须返回**非滚动**
Widget（不是 sliver，也不要返回 `ListView` / `CustomScrollView`）；需要滚动内容时用
`readyBuilder` / `readySliverBuilder`。
包内默认视图带 `liveRegion`；显式 / 主题 builder 不会自动加语义，自定义视图要自己保留。

完整示例见 [README 主题](../../packages/async/README.md#主题)。

## 6. 边界与版本

- `initial` 与 load / refresh 同规则：空列表转 empty、列表 unmodifiable、`isEmpty` 生效。
- `WAsyncPagedController` 的 `initialPage` 参数是 1-based；当前只支持 page 型分页，不支持 cursor。
- `WAsyncState.ready([]) != empty`；`isRefreshing` 依赖 data 非 null；`onError` 不带 StackTrace。
- pre-cancelled token 不触发 hooks；`retryIf` / `retryDelayBuilder` 抛错按最终失败；timeout 不取消底层 Future。
- `async` 当前是 Flutter 异步层；`view/` 是状态渲染原语，页面级组合在 async_ui。

## 7. 测试与版本

```bash
cd packages/async
flutter test
```

当前 8.1.1；迁移见 [async-8.0](../migrations/async-8.0.md) / [async-8.1](../migrations/async-8.1.md)。
AI 路由见 [docs/agents/async.md](../agents/async.md)。
