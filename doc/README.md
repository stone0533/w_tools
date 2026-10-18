# W Tools 模块文档

## 概述

`w_tools` 是一个 Flutter Monorepo 工具集，包含 8 个独立子包，覆盖应用启动、UI 组件、表单构建、网络请求、Toast 提示、二维码、地图、核心工具等常见场景。所有子包通过顶层 `w_tools` 聚合导出，业务工程可按需引入。

## 子包职责

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

## 依赖约束矩阵

> ✅ 表示该子包强依赖外部包（不可替换）。

| 子包 | 强依赖外部包 |
|------|--------------|
| `w_tools_app` | `get`（GetX，不可替换） |
| `w_tools_form` | `flutter_form_builder`、`form_builder_validators`、`intl` |
| `w_tools_ui` | `badges`、`cached_network_image` |
| `w_tools_qr` | `qr_code_scanner_plus`（锁定 `>=2.1.2 <2.2.0`） |
| `w_tools_toast` | `bot_toast` |
| `w_tools_api` | `dio` |
| `w_tools_map` | `google_maps_flutter` |
| `w_tools_core` | `encrypt`、`crypto`、`convert`、`logger`、`shared_preferences`、`synchronized` |

子包间**无强制相互依赖**，可单独引入。

## SDK 与最低版本

> 所有子包都有 `resolution: workspace`（顶层 pubspec 统一指定），因此必须满足 `sdk: ^3.6.0`。

| 子包 | Dart SDK | Flutter SDK |
|------|----------|-------------|
| `w_tools_core` | ^3.6.0 | >= 3.27 |
| `w_tools_app` | ^3.6.0 | >= 3.27 |
| `w_tools_ui` | ^3.6.0 | >= 3.27 |
| `w_tools_api` | ^3.6.0 | >= 3.27 |
| `w_tools_toast` | ^3.6.0 | >= 3.27 |
| `w_tools_qr` | ^3.6.0 | >= 3.27 |
| `w_tools_map` | ^3.6.0 | >= 3.27 |
| `w_tools_form` | ^3.10.0 | >= 3.38 |

## 文档风格

- 所有模块文档使用**中文**撰写。
- `pubspec.yaml`、API 字段名、方法名、类名等保持**英文原名**。
- 文档结构统一为：概述 → 模块结构 → 逐类说明（功能说明、核心方法/参数、使用示例）→ 完整配置示例 → 注意事项。
- `api_module.md` 与 `map_module.md` 为已有文档，其余 6 个为本次整理补充。

## 模块文档索引

| 模块 | 文档 | 状态 |
|------|------|------|
| App 模块 | [app_module.md](app_module.md) | ✅ 已创建 |
| Core 模块 | [core_module.md](core_module.md) | ✅ 已创建 |
| UI 模块 | [ui_module.md](ui_module.md) | ✅ 已创建 |
| Form 模块 | [form_module.md](form_module.md) | ✅ 已创建 |
| API 模块 | [api_module.md](api_module.md) | ✅ 已有 |
| Toast 模块 | [toast_module.md](toast_module.md) | ✅ 已创建 |
| QR 模块 | [qr_module.md](qr_module.md) | ✅ 已创建 |
| Map 模块 | [map_module.md](map_module.md) | ✅ 已有 |
