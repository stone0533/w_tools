> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0002：消费方依赖**子包**，不依赖聚合包

> 本 ADR 正文冻结在 2026-10-24。根包聚合范围此后两次收缩（6.0 去 map/qr、7.0 去 app），
> app / map 也已拆成契约层 + 实现层，见 [ADR-0006](0006-package-topology.md)。
> 正文里的「8 个 Flutter 子包」与示例版本号是 2026-10-24 的状态；当前根包只聚合 6 个基础包，
> 以根 `pubspec.yaml` 为准。


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
  w_tools_app_getx: ^1.0.0
  w_tools_form: ^2.0.0
  w_tools_ui: ^2.1.0
  w_tools_api: ^1.0.0
  w_tools_toast: ^1.0.0
  # 需要再加 w_tools_qr / w_tools_map / w_tools_map_google
```

业务代码只 import 项目自己的聚合入口（`lib/app/w/toolkit.dart`，由 `dart run w_tools_cli:w_tools init` 生成），
不直接 import 子包 —— 换依赖方式时只改一个文件。

## 后果

**收益**：不用的能力（尤其原生 SDK）不进构建；子包可独立升级，不必等聚合包发版。

**代价**：消费方 pubspec 从 1 行变 N 行；新增能力要改自己的 `toolkit.dart`；
需要一条检查防止「又依赖回聚合包」（`doctor` 的 R1/R2）。

## 备选方案

- **删掉聚合包**：对「什么都用」的项目不友好，且破坏已有用户的升级路径。不采纳。
- **让 `w_tools_map` 的 google_maps 变成可选依赖**：Dart/pub 不支持可选依赖；
  已拆成 `w_tools_map`（模型/接口）+ `w_tools_map_google`（Google 实现）；聚合包仍不重新纳入 map，
  需要地图的项目显式依赖两个包。
- **消费方在 app 里包一层 re-export 聚合包**：只换 import 路径，不改变依赖图，等于没解决。否决。

## 工具支持

- `dart run w_tools_cli:w_tools init`：生成 `toolkit.dart` + 暂存层 README + `lib/app/ui/` 页面规范 + `AGENTS.md` 片段
- `dart run w_tools_cli:w_tools doctor`：R1（禁止聚合包）/ R2（禁止直连子包）；
  完整规则集见 [`docs/conventions.md`](../conventions.md) §7（R1~R9）

## 重新评估的条件

- 聚合包长期无人使用，可以评估删除；
- pub 支持可选依赖 / feature flags，聚合包的「快捷方式」价值重新成立；
- 消费方工具链能自动按需引入（`init` 生成的 toolkit 已接近这一步）。

## 补充（2026-11-06，不改决策）：R1 与聚合包定位

根包在 6.0 / 7.0 后只聚合 6 个基础包，不再包含 map / qr；R1 的原始理由（原生 SDK 外溢）
已经弱化，现在的理由是「避免为不用的基础包买单 + 减少版本耦合」。

- 当前仍保持 R1 = error：聚合包只作为快速体验 / 旧项目兼容的入口，README 已标注这一点；
- 若存量项目的摩擦过大，重新评估为 R1 默认 warn、由 `doctor --strict` 判 error；
- 这条不改变决策 1：消费方仍应直接依赖子包，业务代码走项目自己的聚合入口。
