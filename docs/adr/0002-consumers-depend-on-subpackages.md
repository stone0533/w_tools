# ADR 0002：消费方依赖**子包**，不依赖聚合包

- 状态：已采纳（2026-10-24）
- 相关：[`docs/conventions.md`](../conventions.md)、[`packages/cli/templates/toolkit.dart.tpl`](../../packages/cli/templates/toolkit.dart.tpl)、根 `pubspec.yaml`

## 背景

聚合包 `w_tools` 依赖全部 8 个 Flutter 子包，其中：

- `w_tools_map` → `google_maps_flutter`（原生 SDK）
- `w_tools_qr` → `qr_code_scanner_plus`（原生相机）

于是**任何**只写 `w_tools: ^2.0.0` 的消费方，即使完全不用地图，也会把 Google Maps
原生 SDK 打进构建：

- `GeneratedPluginRegistrant` 注册 `GoogleMapsPlugin`
- iOS 需要 GoogleMaps pod（以及 Maps API key 配置）
- 实测：去掉 maps 后 `classes2.dex` 从 2 MB 降到 1 MB

聚合包的价值是「一次引入全部」的便利，但对不用地图的项目是纯负担。

## 决策

**对外推荐消费方只依赖用到的子包**，聚合包保留（不删）但降级为「需要全部能力时的快捷方式」。

```yaml
dependencies:
  w_tools_core: ^1.0.0
  w_tools_app: ^1.0.0
  w_tools_form: ^1.0.0
  w_tools_ui: ^2.0.0
  w_tools_api: ^1.0.0
  w_tools_toast: ^1.0.0
  # 需要再加 w_tools_qr / w_tools_map
```

业务代码只 import 项目自己的聚合入口（`lib/app/w/toolkit.dart`，由 `dart run w_tools_cli:init` 生成），
不直接 import 子包 —— 换依赖方式时只改一个文件。

## 后果

**收益**：不用的能力（尤其原生 SDK）不进构建；子包可独立升级，不必等聚合包发版。

**代价**：消费方 pubspec 从 1 行变 N 行；新增能力要改自己的 `toolkit.dart`；
需要一条检查防止「又依赖回聚合包」（`doctor` 的 R1/R2）。

## 备选方案

- **删掉聚合包**：对「什么都用」的项目不友好，且破坏已有用户的升级路径。不采纳。
- **让 `w_tools_map` 的 google_maps 变成可选依赖**：Dart/pub 不支持可选依赖；
  真正可行的是拆成 `w_tools_map`（纯接口）+ `w_tools_map_google`（实现）。**长期建议走这条**，
  拆完后聚合包就能安全地重新推荐。
- **消费方在 app 里包一层 re-export 聚合包**：只换 import 路径，不改变依赖图，等于没解决。否决。

## 工具支持

- `dart run w_tools_cli:init`：生成 `toolkit.dart` + 暂存层 README + `lib/app/ui/` 页面规范 + `AGENTS.md` 片段
- `dart run w_tools_cli:doctor`：R1（禁止聚合包）/ R2（禁止直连子包）等 6 条检查
