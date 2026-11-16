# async_ui：把 async 页面写法收敛成 4 个入口

`w_tools_async_ui` 是 `w_tools_async` 的可选应用层。它解决的是**同一功能太多正确写法**，
不是增加 async 能力。

## 入口

| 场景 | 入口 |
| --- | --- |
| 单区块 | `WAsyncSection` |
| 标准分页 | `WAsyncPagedList` |
| 自定义滚动 | `WAsyncPagedSliver` |
| footer 文案 | `WAsyncPagedStrings` |

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
  );
}
```

## 反例

| 不要 | 改用 |
| --- | --- |
| 业务页面直接 `WAsyncView` | `WAsyncSection` |
| 业务页面直接 `WAsyncStateSliver` + 自建 footer | `WAsyncPagedList` |
| 自建 `footerStatus` + `footerChanges` 双入口 | `WAsyncPagedList` 的 snapshot |
| 维护 `hasLoadedMorePage` | `snapshot.footerStatus` |
| 在多个独立区块之间共享一个 loading bool | 每块一个 controller + `WAsyncSection` |

## 推荐门禁

迁移期先 `warn`，稳定后改 `error`：

```yaml
banned:
  - id: no-raw-async-view
    pattern: '\bWAsyncView\b'
    use: 'WAsyncSection'
    reason: '业务页面统一走 async_ui；默认 onRetry 接 controller.load'
    level: warn
    paths: ['lib/app/modules/**']
    ignore: ['lib/app/ui/**', 'lib/app/design_system/**']

  - id: no-raw-paged-sliver
    pattern: '\bWAsyncStateSliver\b'
    use: 'WAsyncPagedList / WAsyncPagedSliver'
    reason: '分页 footer 统一读 snapshot'
    level: warn
    paths: ['lib/app/modules/**']
```

## 边界

- 不包含 `parallel` / `pool` / `serial` / `first` / `map`；
- 不包含全局 loading / toast / 登录失效；
- 不包含项目设计系统；空态 / 错误通过 `WAsyncTheme` 或 builder 注入；
- 不自动 load / refresh；首屏请求由页面 controller 负责。
