> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0006：包拓扑——独立库包 + 契约/实现对，根包只聚合基础子包

- 状态：已采纳（2026-11-04 拆包；2026-11-06 记录拓扑与根聚合范围）
- 相关：[ADR-0002](0002-consumers-depend-on-subpackages.md)、[ADR-0003](0003-subpackage-typography-without-ui.md)、
  [`docs/modules/README.md`](../modules/README.md)、[`docs/releasing.md`](../releasing.md)、
  [`docs/migrations/app-3.0.md`](../migrations/app-3.0.md)、[`docs/migrations/map-3.0.md`](../migrations/map-3.0.md)

## 背景

仓库里有三类包：库包（使用者直接依赖）、工具包（只进 `dev_dependencies`）、以及一个根聚合包。
它们共享一个 workspace、各自独立版本。最初的形态是「根包聚合所有子包」，由此产生三个问题：

1. **重依赖外溢**：不用地图的项目也会注册 `GoogleMapsPlugin`，`classes2.dex` 从 1 MB 涨到 2 MB
   （[ADR-0002](0002-consumers-depend-on-subpackages.md) 的实测）。
2. **一个包混两层**：`w_tools_app` 混了 GetX 启动器与插件契约；`w_tools_map` 混了纯模型与 Google 实现。
3. **拓扑没有成文规则**：加新包时只能靠「看别人怎么写」，容易出现「库包 A 依赖库包 B」这种
   把传递依赖和发布顺序一起绑死的结构。

对全部分包做了一次依赖盘点（`packages/*/pubspec.yaml`）：库包之间**只剩两条内部边**——
`app_getx → app`、`map_google → map`，其余库包互相零依赖；`core` 不是任何包的依赖。

## 决策

拓扑按角色定义，数量以 `packages/*/pubspec.yaml` 与根 `pubspec.yaml` 为准：

| 角色 | 包含 | 依赖约束 |
|---|---|---|
| 独立库包 | `core` / `async` / `ui` / `form` / `api` / `toast` / `qr` | **零内部依赖**，可单独引入 |
| 契约包 | `app` / `map` | 零内部依赖；不依赖平台 SDK |
| 实现包 | `app_getx` / `map_google` | 只依赖对应契约包 + 平台 SDK |
| 工具包 | `cli` / `figma` / `device` / `e2e` | 零内部依赖；只进 `dev_dependencies` |
| 聚合包 | 根 `w_tools` | 只依赖基础库包（见下） |

1. **库包之间零内部依赖**：不抽「公共基础包」让所有库依赖它——少量重复代码优于包间耦合；
   唯一的内部依赖是「实现包 → 契约包」。
2. **契约 / 实现拆分**：契约层不带平台 SDK；实现包用 `_<platform>` 后缀（当前只有 `_google`）；
   拆分本身是双方 major，新实现包从 1.0.0 开始；发布先契约包、后实现包。
3. **根包只聚合基础库包**：`core` / `async` / `ui` / `form` / `api` / `toast`；
   `app` / `app_getx` / `map` / `map_google` / `qr` 只允许直接依赖。
4. **工具包不进根聚合**：`cli` / `figma` / `device` / `e2e` 只作为 `dev_dependencies`，
   独立版本、独立发布；它们与库包的语义不同，不参与消费方的运行时依赖图。
5. **新增子包默认不进根聚合**。要进必须同时满足：不引入原生插件或重量级传递依赖、
   不阻塞子包独立发布、不替用户做 `get` / Google Maps / 相机这类选型决定。
6. **从根包移除子包 = 根包 major**，必须在根 `CHANGELOG.md` 的 `Breaking` 下写清替代依赖。
7. 根包定位是**快速体验 / 旧项目兼容**；新项目按 ADR-0002 直接依赖子包。

## 后果

**正向**

- 依赖图是扁平的：任何一个库包出问题都不会阻塞其他包发布；消费方装多少用多少；
- 根包稳定在 6 个纯 Flutter 基础包，解析快、冲突面小；
- 加新包时有明确落点：先判断角色，再决定能不能有内部依赖、要不要进聚合。

**代价 / 已知局限**

- 包数量多，workspace / manifest / 文档矩阵 / 发布顺序都要同步；
- 少量工具代码在库包之间重复（例如格式化、颜色处理），这是换取零耦合的代价；
- 两对契约包必须按顺序发布；用根包的项目升级到 6.0 / 7.0 时要显式补依赖；
- 拆包沿用了 `WMapConfig` 这个早于 ADR-0004 的名字（见 ADR-0004 的 2026-11-06 修订）。

## 备选方案

- **保留全聚合 + 可选依赖**：Dart / pub 不支持可选依赖。
- **抽一个公共基础包，所有库依赖它**：版本绑死、传递依赖回归，正是本 ADR 要避免的结构。
- **条件导出 / 子目录隔离实现**：依赖图不变，GetX 与 Google Maps 仍会强制安装。
- **把工具包合并进 cli 或根包**：工具包是 dev-only，语义与库包不同，合并会让消费方误依赖。
- **删除根包**：破坏已有用户的升级路径，也失去「快速体验」入口。

## 重新评估的条件

- 出现第三个地图实现（高德 / Apple）→ 按 `w_tools_map_<platform>` 继续拆；
- 契约层与实现层出现版本强耦合（每次契约变更都要求实现 major）；
- pub 支持可选依赖 / feature flags，或原生 SDK 变成 Flutter 内置能力；
- 某个工具包被库包反向依赖（说明它已不是 dev-only，需要重新定义角色）；
- 根包的兼容价值消失（主要用户都已直接依赖子包）。

## 落地结果（2026-11-06）

- 状态：已完成；当前包角色与依赖边与上表一致，内部边只有 `app_getx → app`、`map_google → map`。
- 证据：`packages/*/pubspec.yaml`、`scripts/ci_matrix.py`、`docs/modules/README.md`。
- 偏差：无；包数量以 `packages.manifest` 与各包 `pubspec.yaml` 为准（本文不写死）。
