# W Tools 模块文档

## 概述

`w_tools` 是一个 Flutter Monorepo：**11 个库子包**（10 个 Flutter + 1 个纯 Dart 地图接口）
+ **聚合包 `w_tools`** + **工具包（`w_tools_cli` / `figma` / `device` / `e2e`）**。

11 个库子包中，只有 `core` / `async` / `ui` / `form` / `api` / `toast` 由根包
`w_tools` 聚合导出；`app` / `app_getx` / `map` / `map_google` / `qr` 按需直接依赖。
`w_tools_cli` 是独立的开发工具（`init` / `doctor`），只放 `dev_dependencies`，不参与聚合、也不进构建。

## 库子包职责

| 子包 | 路径 | 职责 |
|------|------|------|
| `w_tools_core` | `packages/core/` | 零 UI 依赖的核心工具：扩展方法、日志、加解密、Token 管理、存储、倒计时、正则等 |
| `w_tools_async` | `packages/async/` | 异步执行、四态状态、Controller 与异步视图 |
| `w_tools_app` | `packages/app/` | 启动契约 `WAppPlugin`（GetX 无关） |
| `w_tools_app_getx` | `packages/app_getx/` | GetX 启动器 `WApp`、语言切换、路由管理、底部弹窗 |
| `w_tools_ui` | `packages/ui/` | 通用 UI 组件：按钮、图片、文本、AppBar、Scaffold、导航、TabBar、列表等 |
| `w_tools_form` | `packages/form/` | 基于 `flutter_form_builder` 的表单组件：输入框、下拉、日期选择、校验、按钮、边框 |
| `w_tools_api` | `packages/api/` | 基于 Dio 的网络请求封装：`DioRegistry`、日志/Token 拦截器、仓库基类 |
| `w_tools_toast` | `packages/toast/` | 基于 `bot_toast` 的 Toast 提示封装 |
| `w_tools_qr` | `packages/qr/` | 基于 `qr_code_scanner_plus` 的二维码扫描组件 |
| `w_tools_map` | `packages/map/` | 平台无关地图模型 / mapper |
| `w_tools_map_google` | `packages/map_google/` | Google Maps 实现 `WMap` |

## 工具包

| 包 | 路径 | 运行环境 | 职责 |
|------|------|----------|------|
| `w_tools_cli` | `packages/cli/` | 纯 Dart | 消费方接入工具：`init` 生成聚合入口/暂存层/项目 UI 规范/AGENTS 片段，`doctor` 检查接入约定 |
| `w_tools_figma` | `packages/figma/` | 纯 Dart | 只读的 Figma 取数 / 规格 / token / diff CLI（命令与额度见 [`packages/figma/README.md`](../../packages/figma/README.md)） |
| `w_tools_device` | `packages/device/` | 纯 Dart | 设备验证 CLI：列模拟器 / 启动 / 截图 / 在 DeviceHub 里按设备坐标点击（自动标定）；平台矩阵与命令见 [`packages/device/README.md`](../../packages/device/README.md) |
| `w_tools_e2e` | `packages/e2e/` | Flutter | 设备验证的免登录入口（编译期开关，release 天然失效） |

`w_tools_cli` 依赖 `args` / `path` / `yaml`；`w_tools_figma` 依赖 `yaml`；`w_tools_device` 依赖 `image`；`w_tools_e2e` 是 Flutter 包。

## 依赖约束矩阵（库子包）

> ✅ 表示该子包强依赖外部包（不可替换）。具体约束以各包 `pubspec.yaml` 为准。
> 子包之间**不新增相互依赖**（含不依赖 `w_tools_ui`）：排版通过 `ThemeData.textTheme` 共享，
> 见 [ADR-0003](../adr/0003-subpackage-typography-without-ui.md)。唯一例外是「实现包 → 契约包」
> 两对（`app_getx → app`、`map_google → map`），见 [ADR-0006](../adr/0006-package-topology.md)。

| 子包 | 强依赖外部包 |
|------|--------------|
| `w_tools_app_getx` | `get`（GetX，不可替换） |
| `w_tools_form` | `flutter_form_builder`、`intl` |
| `w_tools_ui` | `cached_network_image` |
| `w_tools_qr` | `qr_code_scanner_plus` |
| `w_tools_toast` | `bot_toast` |
| `w_tools_api` | `dio` |
| `w_tools_map_google` | `google_maps_flutter` |
| `w_tools_async` | `flutter`（无第三方强依赖） |
| `w_tools_core` | `encrypt`、`crypto`、`convert`、`logger`、`shared_preferences`、`synchronized` |

除 `app_getx → app`、`map_google → map` 两对契约关系外，库子包之间没有相互依赖，可单独引入；
完整拓扑（库包 / 契约 / 实现 / 工具包 / 聚合包）见
[ADR-0006](../adr/0006-package-topology.md)。

## SDK 与最低版本

> 所有包都带 `resolution: workspace`（由顶层 pubspec 统一解析）。版本以各包
> `pubspec.yaml` 的 `environment` 为准，下表只是速查。

| 包 | Dart SDK | Flutter SDK |
|------|----------|-------------|
| `w_tools_core` | ^3.10.0 | >= 3.38 |
| `w_tools_async` | ^3.10.0 | >= 3.38 |
| `w_tools_app` | ^3.10.0 | >= 3.38 |
| `w_tools_app_getx` | ^3.10.0 | >= 3.38 |
| `w_tools_ui` | ^3.10.0 | >= 3.38 |
| `w_tools_api` | ^3.10.0 | >= 3.38 |
| `w_tools_toast` | ^3.10.0 | >= 3.38 |
| `w_tools_qr` | ^3.10.0 | >= 3.38 |
| `w_tools_map` | ^3.10.0 | — |
| `w_tools_map_google` | ^3.10.0 | >= 3.38 |
| `w_tools_form` | ^3.10.0 | >= 3.38 |
| `w_tools_cli` | ^3.10.0 | —（纯 Dart） |
| `w_tools_figma` | >=3.6.0 <4.0.0 | —（纯 Dart） |
| `w_tools_device` | >=3.6.0 <4.0.0 | —（纯 Dart） |
| `w_tools_e2e` | >=3.6.0 <4.0.0 | >= 3.22 |

## 文档风格

- 所有模块文档使用**中文**撰写。
- `pubspec.yaml`、API 字段名、方法名、类名等保持**英文原名**。
- 文档结构优先：概述 → 模块结构 → 边界 / 架构 → 跨类关系 → 注意事项；
  历史逐类说明保留，但新增内容不要再复制包 README 的安装 / API 表。
- 包 README 是安装、最小用法、常用配方的事实源；逐参数 API 以 pub.dev API 文档 / 源码为准。
  modules 文档负责边界与架构，参数细节优先链接各包 README（[packages/](../../packages)）或
  [`components.md`](components.md)。
- 新增或修改组件时，改 [`packages/cli/catalog/components.yaml`](../../packages/cli/catalog/components.yaml)
  并跑 `cd packages/cli && dart run tool/gen_catalog.dart` 重新生成 [`components.md`](components.md)（不要手改）。

## 相关文档

| 文档 | 内容 |
|------|------|
| [`components.md`](components.md) | 组件目录：按用途找现成组件，含「不要用在哪」 |
| [`../docs/conventions.md`](../conventions.md) | 接入约定：包 / 暂存层 / 业务层的判定与 doctor 规则 |
| [`../CONTRIBUTING.md`](../../CONTRIBUTING.md) | 新增/修改组件的硬性要求 |
| [`../docs/releasing.md`](../releasing.md) | 发版流程与发布脚本 |
| [`../docs/adr/0002-consumers-depend-on-subpackages.md`](../adr/0002-consumers-depend-on-subpackages.md) | 为什么消费方依赖子包而不是聚合包 |
| [`../packages/cli/README.md`](../../packages/cli/README.md) | `init` / `doctor` 的用法与规则 |

## 模块文档索引

| 模块 | 文档 |
|------|------|
| App 模块 | [app_module.md](app_module.md) |
| Core 模块 | [core_module.md](core_module.md) |
| Async 模块 | [async_module.md](async_module.md) |
| UI 模块 | [ui_module.md](ui_module.md) |
| Form 模块 | [form_module.md](form_module.md) |
| API 模块 | [api_module.md](api_module.md) |
| Toast 模块 | [toast_module.md](toast_module.md) |
| QR 模块 | [qr_module.md](qr_module.md) |
| Map 模块 | [map_module.md](map_module.md) |
