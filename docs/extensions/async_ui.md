# async_ui：把 async 页面写法收敛成 3 个入口

`w_tools_async_ui` 是 `w_tools_async` 的可选应用层。它解决的是**同一功能太多正确写法**，
不是增加 async 能力。

## 入口

| 场景 | 入口 |
| --- | --- |
| 单区块 | `WAsyncSection` |
| 标准分页 | `WAsyncPagedList` |
| 自定义滚动 / ready sliver | `WAsyncPagedSliver` |

业务页面不要再直接写 `WAsyncView` / `WAsyncStateSliver`；它们保留给库、设计系统和明确的自定义扩展。

## 最小用法

```dart
final gifts = WAsyncController.list<Gift>((_) => api.gifts());

@override
void initState() {
  super.initState();
  gifts.load();
}

@override
void dispose() {
  gifts.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return WAsyncSection<List<Gift>>(
    controller: gifts,
    builder: (context, data) => GiftList(data),
  );
}
```

分页：

```dart
final gifts = WAsyncPagedController<Gift>((page, token) async {
  final resp = await api.gifts(page: page, token: token);
  return WAsyncPage(items: resp.list, hasMore: resp.total > page * 20);
});

@override
void initState() {
  super.initState();
  gifts.refresh();
}

@override
Widget build(BuildContext context) {
  return WAsyncPagedList<Gift>(
    controller: gifts,
    itemBuilder: (context, gift) => GiftTile(gift),
    reloadRequests: reloadRequests, // 可选；程序化刷新
    autoLoadThreshold: 200,         // 可选；滚动自动加载
    footerBuilder: (context, snapshot) => AppFooter(snapshot), // 可选
    refreshIndicatorStyle: const WAsyncRefreshIndicatorStyle( // 可选
      color: Color(0xFF00A86B),
      backgroundColor: Colors.white,
    ),
  );
}
```

`WAsyncPagedList` 下拉刷新用 Flutter `RefreshIndicator`；滚动接近底部时自动
`gifts.loadMore()`。默认 footer 读 `gifts.snapshot`，展示 loading / 失败重试 /
没有更多。`refreshIndicatorStyle` 配置标准头的颜色 / 背景 / 线宽等，不提供自定义
刷新头动画或完成 / 失败文案。

需要完全自定义刷新头 / 上拉壳时，用 `WAsyncPagedSliver` + 自己的滚动壳：

```dart
RefreshIndicator(
  onRefresh: gifts.refresh,
  child: CustomScrollView(
    slivers: [
      WAsyncPagedSliver<Gift>(
        controller: gifts,
        itemBuilder: (context, gift) => GiftTile(gift),
      ),
      SliverToBoxAdapter(child: AppFooter(controller: gifts)),
    ],
  ),
)
```

## 反例

| 不要 | 改用 |
| --- | --- |
| 业务页面直接 `WAsyncView` | `WAsyncSection` |
| 业务页面直接 `WAsyncStateSliver` + 自建刷新壳 | `WAsyncPagedList` / `WAsyncPagedSliver` |
| 在 `WAsyncPagedList` 外再包一层刷新壳 | 标准页面直接用 `WAsyncPagedList`；自定义用 `WAsyncPagedSliver` |
| 自建 `footerStatus` + `footerChanges` 双入口 | `WAsyncPagedList` 的 snapshot |
| 维护 `hasLoadedMorePage` | `snapshot.footerStatus` |
| 在多个独立区块之间共享一个 loading bool | 每块一个 controller + `WAsyncSection` |

## 推荐门禁

R10 从 CLI 2.3.1 起为 `error`；如果项目还没迁移完，用下面的 ignore / rules.R10 关闭。

```yaml
banned:
  - id: no-raw-async-view
    pattern: '\bWAsyncView\b'
    use: 'WAsyncSection'
    reason: '业务页面统一走 async_ui；默认 onRetry 接 controller.load'
    level: error
    paths: ['lib/app/modules/**']
    ignore: ['lib/app/ui/**', 'lib/app/design_system/**']

  - id: no-raw-paged-sliver
    pattern: '\bWAsyncStateSliver\b'
    use: 'WAsyncPagedList / WAsyncPagedSliver'
    reason: '分页 footer 统一读 snapshot'
    level: error
    paths: ['lib/app/modules/**']
```

## 边界

- 不包含 `parallel` / `pool` / `serial` / `first` / `map`；
- 不包含全局 loading / toast / 登录失效；
- 不包含项目设计系统；空态 / 错误通过 `WAsyncTheme` 或 builder 注入；
- 不自动 load / refresh；首屏请求由页面 controller 负责。

## R10 迁移

CLI 2.3.1 起，R10 从 `warn` 升级为 `error`。项目依赖 `w_tools_async_ui` 时，
`lib/app/modules/**` 里以下写法会被 doctor 拦住：

```text
WAsyncView(...)          → WAsyncSection(...)
WAsyncStateSliver(...)   → WAsyncPagedList(...) / WAsyncPagedSliver(...)
// footer 由 app 自己的 header/footer 负责
hasLoadedMorePage        → snapshot.footerStatus
```

迁移期临时放行：

```dart
// w_tools:ignore R10 reason: 迁移中
WAsyncView<List<Gift>>(...);
```

或按项目关闭（`rules.R10: false`）：

```yaml
rules:
  R10: false
```

长期仍建议把业务页面的 async 原语替换成 `WAsyncSection` / `WAsyncPagedList` / `WAsyncPagedSliver`；
`lib/app/ui` / 暂存层不在 R10 扫描范围，可以继续封装原语。
