> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0008：w_tools_ui 保留 cached_network_image 作为网络图缓存依赖

- 状态：已采纳（2026-11-13）
- 相关：[ADR-0006](0006-package-topology.md)、
  [`packages/ui/pubspec.yaml`](../../packages/ui/pubspec.yaml)、
  [`packages/ui/README.md`](../../packages/ui/README.md)

## 背景

`w_tools_ui` 的 `WImage` 网络图依赖 `cached_network_image`。这个依赖会传递带入：

- `flutter_cache_manager`（缓存管理）；
- `path_provider` 及其平台实现（缓存目录）；
- `sqflite` 及其平台实现（缓存索引 / 数据库）；
- `octo_image`、`rxdart`、`uuid` 等辅助包；
- Web 端的 `cached_network_image_web`。

对只使用 `WText` / `WButton` / 布局组件的消费方，这些平台插件仍会进入依赖图和插件注册，
`pub deps` 也会更重。需要判断是否把网络图缓存拆成独立包，或保留现状并文档化。

## 决策

**保留 `cached_network_image` 作为 `w_tools_ui` 的直接依赖，不拆分。**

理由：

1. 网络图缓存、重试、占位与 `WImage` 的状态机是当前包的核心能力；拆包会让 `WImage`
   需要跨包契约，增加 API 与版本耦合，收益不足以抵消破坏面。
2. 已有 `WImageSource.provider` 作为逃生口：业务可以传入自己的 `ImageProvider`
   接管加载；asset / file / base64 也不经过网络缓存。
3. Dart pub 没有“可选依赖”；把缓存做成可选只能靠拆包或去掉磁盘缓存，
   两者都是 breaking change，不适合在没有第二个消费场景前做。
4. 依赖体量可以通过文档化和 `pub deps` 让消费方提前判断；不是运行时错误。

## 后果

- 消费方只使用非图片组件时，仍会带上 `path_provider` / `sqflite` 等平台插件；
  这是已知代价，安装段必须说明。
- `WImage` 继续获得磁盘缓存、重试退避与离线可用性，不需要维护第二套网络加载器。
- 如果后续出现以下信号，再重新评估拆包：
  - 多个消费方明确只用非图片组件，且插件注册造成冲突 / 体积问题；
  - Web / 桌面出现 `cached_network_image` 无法解决的支持问题；
  - 需要替换缓存后端（例如统一走业务 CDN / 自研缓存）。

## 被否决的替代方案

| 方案 | 否决原因 |
|---|---|
| 改用 Flutter `Image.network` | 失去磁盘缓存、离线与 `CachedNetworkImageProvider` 的缓存 key / headers 能力 |
| 直接用 `flutter_cache_manager` | 传递依赖基本不变，还要自己维护 `ImageProvider` 与错误映射 |
| 拆 `w_tools_ui_image` 附加包 | 需要跨包契约 + 双份版本 / 文档 / 示例；当前没有第二个使用场景 |
| 把依赖做成可选 | Dart pub 不支持可选依赖；只能删功能或拆包 |
