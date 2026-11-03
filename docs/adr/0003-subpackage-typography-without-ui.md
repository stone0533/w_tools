# ADR 0003：子包不依赖 `w_tools_ui`，排版通过 `ThemeData` 共享

- 状态：已采纳（2026-11-03）
- 相关：[`docs/analysis/2026-11-03-remediation-plan.md`](../analysis/2026-11-03-remediation-plan.md)（D1）、
  [`docs/agents/ui.md`](../agents/ui.md)、`w_tools_ui 3.2.0`（`toTextTheme` / `withWTextStyles`）、
  [ADR-0002](0002-consumers-depend-on-subpackages.md)

## 背景

`form` / `toast` / `async` 都要渲染文字与颜色，而设计系统（`WTextStyles`、按钮样式、图片）
只在 `w_tools_ui` 里。最初的方案（路线图 D1）是让这三个包依赖 ui，理由是"统一排版"。
评估后发现三件事：

1. **共享面很小**：三包实际只缺 8 个左右的样式值（form：4 个边框色 + 1 个 hint 色；
   toast：文字色 / 底色 / 遮罩；async：已在读 `textTheme` 与 `colorScheme`）。
   复杂 widget（`WImage`、`WScaffold`）一个都用不到。
2. **Dart 没有"类型级依赖"**：只要想拿 `WTextStyles` 这个类型，就等于 `pubspec` 加整个 ui 包。
3. **ui 比看起来重**：按本仓库当前解析结果，`cached_network_image`（`WImage` 用）的传递闭包是
   **50 个包、10 个原生插件**（`path_provider` 四平台实现、`sqflite` + android/darwin、`jni`、
   `jni_flutter`）。而 `async` / `toast` / `form` 现在**原生插件数为 0**，`async` 的第三方依赖数为 0。

为一个约 180 行的样式类型引入这条依赖链，比例不成立；同时会让三包的第三方版本被 ui 绑架、
发布顺序被绑死，并让 `w_tools_async` 的"零第三方"承诺失效（与 ADR-0002 的按需依赖精神冲突）。

## 决策

1. **`form` / `toast` / `async` 不新增 `w_tools_ui` 依赖**；三个包的 `pubspec.yaml` 保持不变。
2. **只通过标准 Flutter 类型共享排版**：`ThemeData.textTheme`、`ColorScheme`、
   以及各包已有的 `xxxTheme` / 配置入口（`WFormTheme`、`WToastConfig`、`WAsyncTheme`）。
3. **`WTextStyles` 保留为唯一语义真源**（11 个角色），由应用侧一次性投影：
   `ThemeData.withWTextStyles(styles)` 同时写 `textTheme` 与 ThemeExtension。
   投影表按 **Material 的消费点**选取槽位，而不是一一对应：
   - `body` 同时写 `bodyLarge`（`TextField` 输入）与 `bodyMedium`（普通正文）；
   - `number` **不投影**（否则所有表单输入会变成数字样式）；
   - 其余角色写到用途最接近的槽位（`title→titleLarge`、`caption→bodySmall`、
     `label→labelMedium`、`button→labelLarge`、`badge→labelSmall`、`price→headlineSmall` 等）。
4. **三包的默认样式禁止字面量色值**：不得出现 `Color(0x…)` / `Colors.white|black*`
   （`Colors.transparent` 除外），必须从 `ColorScheme` / `TextTheme` 派生；
   同时保留显式覆盖参数。由 `scripts/check_style_literals.py` 在 CI 检查，
   历史浅色预设可在行内标 `// style-literal-ok: <理由>`。
5. **兜底**：应用没有调用 `withWTextStyles` 时，三包回退到纯 Material 主题（可用，但不是品牌排版）。

## 后果

**正向**

- 三包依赖不变：`async` 保持零第三方依赖，最小消费者（只用 form 或只用 toast）不会被拖入图片缓存。
- 发布解耦：ui 与三包互不阻塞。
- 暗色主题修复：默认色值从 `ColorScheme` 派生后，不再出现"白底表单 / 黑字图标"。
- 单一真源：愿意用语义角色的项目只配 `WTextStyles` 一次。

**负向 / 已知局限**

- `price` / `number` / `badge` 这些 WText 专属语义**到不了 Material 组件**（`TextTheme` 没有对应槽位）。
- 按钮仍是 Material 样式（`ColorScheme` 决定），不会自动变成 `WButton` 的样式。
- 应用需要记住 `withWTextStyles`；忘记时不会报错，只是回到 Material 默认（可见、可文档化）。
- `WForm` 的默认 `borderConfig` 切换到主题派生版本属于视觉变更，需按 semver 进大版本。

## 重新评估的条件

出现以下任一情况时重新考虑"依赖 ui"或"抽零依赖叶子包"：

- 三包需要复用 ui 的**复杂 widget**（而不只是样式值），例如 form 需要 `WImage` 做上传缩略图；
- 需要在**运行期**切换 `WTextStyles` 且三包必须实时跟随；
- 需要跨包共享的还有状态/服务类能力（`WAssets` 的全局配置、`WScreen` 的适配委托等）——
  这些无法投影进 `ThemeData`。

## 附：评估数据

| 项 | 数值 |
| --- | --- |
| `w_tools_ui` 直接第三方 | `cached_network_image`、`badges` |
| 二者传递闭包 | 50 个包（不含 ui 自身） |
| 其中原生插件 | 10 个（`path_provider` ×4 平台实现、`sqflite` + android/darwin、`jni`、`jni_flutter`） |
| `async` / `toast` / `form` 现有原生插件 | 0 / 0 / 0 |

数据来自 `.dart_tool/package_config.json` + 各包 `pubspec.yaml` 的 `dependencies` 闭包，
会随依赖版本变化，但量级不会变。
