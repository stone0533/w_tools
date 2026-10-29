# W Tools 模块文档

## 概述

`w_tools` 是一个 Flutter Monorepo：**8 个 Flutter 子包** + **聚合包 `w_tools`** +
**纯 Dart 工具包 [`w_tools_cli`](../../packages/cli/README.md)**。

8 个 Flutter 子包通过顶层 `w_tools` 聚合导出，业务工程可按需引入；`w_tools_cli` 是
独立的开发工具（`init` / `doctor`），只放 `dev_dependencies`，不参与聚合、也不进构建。

## Flutter 子包职责

| 子包 | 路径 | 职责 |
|------|------|------|
| `w_tools_core` | `packages/core/` | 零 UI 依赖的核心工具：扩展方法、日志、加解密、Token 管理、存储、倒计时、正则、异步任务等 |
| `w_tools_app` | `packages/app/` | 应用启动器 `WApp`、插件体系 `WAppPlugin`、语言切换、路由管理、底部弹窗 |
| `w_tools_ui` | `packages/ui/` | 通用 UI 组件：按钮、图片、文本、AppBar、Scaffold、导航、TabBar、列表等 |
| `w_tools_form` | `packages/form/` | 基于 `flutter_form_builder` 的表单组件：输入框、下拉、日期选择、校验、按钮、边框 |
| `w_tools_api` | `packages/api/` | 基于 Dio 的网络请求封装：`DioRegistry`、日志/Token 拦截器、仓库基类 |
| `w_tools_toast` | `packages/toast/` | 基于 `bot_toast` 的 Toast 提示封装 |
| `w_tools_qr` | `packages/qr/` | 基于 `qr_code_scanner_plus` 的二维码扫描组件 |
| `w_tools_map` | `packages/map/` | 基于 `google_maps_flutter` 的通用地图组件 `WMap` |

## 工具包（纯 Dart）

| 包 | 路径 | 职责 |
|------|------|------|
| `w_tools_cli` | `packages/cli/` | 消费方接入工具：`init` 生成聚合入口/暂存层/项目 UI 规范/AGENTS 片段，`doctor` 检查接入约定 |

只依赖 `args` / `path` / `yaml`，不依赖 Flutter；发版独立于子包与聚合包。

## 依赖约束矩阵（Flutter 子包）

> ✅ 表示该子包强依赖外部包（不可替换）。具体约束以各包 `pubspec.yaml` 为准。

| 子包 | 强依赖外部包 |
|------|--------------|
| `w_tools_app` | `get`（GetX，不可替换） |
| `w_tools_form` | `flutter_form_builder`、`form_builder_validators`、`intl` |
| `w_tools_ui` | `badges`、`cached_network_image` |
| `w_tools_qr` | `qr_code_scanner_plus` |
| `w_tools_toast` | `bot_toast` |
| `w_tools_api` | `dio` |
| `w_tools_map` | `google_maps_flutter` |
| `w_tools_core` | `encrypt`、`crypto`、`convert`、`logger`、`shared_preferences`、`synchronized` |

子包间**无强制相互依赖**，可单独引入。

## SDK 与最低版本

> 所有包都带 `resolution: workspace`（由顶层 pubspec 统一解析）。版本以各包
> `pubspec.yaml` 的 `environment` 为准，下表只是速查。

| 包 | Dart SDK | Flutter SDK |
|------|----------|-------------|
| `w_tools_core` | ^3.6.0 | >= 3.27 |
| `w_tools_app` | ^3.6.0 | >= 3.27 |
| `w_tools_ui` | ^3.6.0 | >= 3.27 |
| `w_tools_api` | ^3.6.0 | >= 3.27 |
| `w_tools_toast` | ^3.6.0 | >= 3.27 |
| `w_tools_qr` | ^3.6.0 | >= 3.27 |
| `w_tools_map` | ^3.6.0 | >= 3.27 |
| `w_tools_form` | ^3.10.0 | >= 3.38 |
| `w_tools_cli` | ^3.10.0 | —（纯 Dart） |

## 文档风格

- 所有模块文档使用**中文**撰写。
- `pubspec.yaml`、API 字段名、方法名、类名等保持**英文原名**。
- 文档结构统一为：概述 → 模块结构 → 逐类说明（功能说明、核心方法/参数、使用示例）→
  完整配置示例 → 注意事项。
- 新增或修改组件时，同步更新 [`components.md`](components.md) 的组件表。

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
| UI 模块 | [ui_module.md](ui_module.md) |
| Form 模块 | [form_module.md](form_module.md) |
| API 模块 | [api_module.md](api_module.md) |
| Toast 模块 | [toast_module.md](toast_module.md) |
| QR 模块 | [qr_module.md](qr_module.md) |
| Map 模块 | [map_module.md](map_module.md) |
