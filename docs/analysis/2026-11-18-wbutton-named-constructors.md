# `WButton` 改用 named constructors：决策记录与执行清单

- 日期：2026-11-18
- 状态：**已发布（2026-11-18）**；`w_tools_ui` 13.0.0 / `w_tools_cli` 2.4.0 / `w_tools` 19.0.0
- 目标版本：`w_tools_ui` **13.0.0**（12.0.1 → 13.0.0；breaking）
- 决策：采用 **3a. named constructors**（构造器只表达按钮类型）：
  - 新增 `WButton.filled` / `WButton.outlined` / `WButton.text`；
  - **不新增** `WButton.danger`；危险按钮用 `.filled(style: ...)` / 项目 `AppButtons.danger`；
  - **删除**无名构造器 `WButton(...)`，全部迁移为 `WButton.filled(...)`；
  - **删除** `variant` 参数与公开枚举 `WButtonVariant`；
  - **删除** `WButtonTheme.danger`（`danger` 是 tone，不是 type；主题只保留三个类型槽）；
  - **保留** `style`（Material `ButtonStyle`，只做属性覆盖）与 `size`。

## 背景

`WButton` 目前用 `variant` 选择 Material 按钮类，同时允许 `style` 覆盖属性：

```dart
WButton(
  variant: WButtonVariant.outlined, // 选择 OutlinedButton
  style: ButtonStyle(...),          // 覆盖属性
)
```

问题不是“两者都存在”，而是 `style` 无法表达“我是哪种按钮”：

- `ButtonStyle` 只是属性包，没设置 `backgroundColor` 时会落到当前按钮类的默认值；
- `OutlinedButton.styleFrom` / `TextButton.styleFrom` 的 style 套到 `FilledButton` 上，
  背景仍是 `primary`，前景也可能被覆盖成 `primary` → 同色不可见（已验证 `fg == bg`）；
- 当前 CLI 生成的 `AppButtons.secondary/text` + 默认 `variant: filled` 就踩中了这个 bug。

named constructors 把类型放到构造器名里，`style` 退回纯属性覆盖，错配从“运行时视觉”变成
“调用点一眼可见”。

## 目标 API

```dart
WButton.filled(label: '保存', onTap: save);
WButton.outlined(label: '取消', onTap: cancel);
WButton.text(label: '查看更多', onTap: more);

// 危险操作：tone 用 style 表达，不新增构造器
WButton.filled(
  style: AppButtons.danger(context), // 或 FilledButton.styleFrom(backgroundColor: scheme.error, ...)
  label: '删除',
  onTap: remove,
);

// 单按钮覆盖：类型由构造器决定，style 只覆盖属性
WButton.outlined(
  style: OutlinedButton.styleFrom(foregroundColor: brand),
  label: '取消',
  onTap: cancel,
);
```

保留的通用参数：`size` / `label` / `icon` / `content` / `loading` / `loadingBuilder` /
`enabled` / `onTap` / `onLongPress` / `semanticLabel` / `semanticHint` / `loadingLabel` /
`tooltip` / `isSelected` / `focusNode` / `autofocus`。

### 为什么去掉 `danger`

- `danger` 是语气（tone），不是 Material 按钮类型；放成构造器会让“类型”和“语气”两个维度
  重新混在一起。
- `.danger` 只能表达 **filled + danger**；要支持 outlined / text 危险色，只能继续加
  `.outlinedDanger` / `.textDanger`，组合爆炸。
- `WButtonTheme.danger` 只服务于 `.danger`，与 `filled/outlined/text` 不对称；删除后主题层
  只保留三个类型槽。
- 项目级 `AppButtons.danger` 已经是“危险样式”的既有落点，库层不再重复。
- 如果未来确实需要完整的“类型 × 语气”矩阵，再加 `tone` 参数（例如
  `WButton.filled(tone: WButtonTone.danger)`），而不是继续加构造器；那是独立设计。



## 公开面变化（实现时逐项确认）

### 删除

- `WButton.new`（无名构造器；迁移为 `WButton.filled`）。
- `WButton.variant` 参数 / 字段。
- `WButtonVariant` 枚举（`filled` / `outlined` / `text` / `danger`）。
- `WButtonTheme.styleFor(WButtonVariant)`：改为内部解析（私有 kind），不再公开。
- `WButtonTheme.danger` 字段，以及 `copyWith` / `lerp` 的 `danger` 参数：删除；
  `WButtonTheme` 只保留 `filled` / `outlined` / `text` 三个类型槽。

### 保留

- `WButtonTheme` 的三个 `ButtonStyle?` 槽位、`copyWith` / `lerp`。
- `WButton.style`（`ButtonStyle?`）与优先级 `style > size > WButtonTheme`。
- `WButton.filled` / `.outlined` / `.text` 三个命名构造器均为 `const`（参数允许 const 时）。

### 迁移写法

```dart
// before
WButton(label: '保存', onTap: save);
WButton(variant: WButtonVariant.outlined, label: '取消', onTap: cancel);
WButton(variant: WButtonVariant.danger, label: '删除', onTap: remove);

// after
WButton.filled(label: '保存', onTap: save);
WButton.outlined(label: '取消', onTap: cancel);
WButton.filled(style: AppButtons.danger(context), label: '删除', onTap: remove);

// 主题里的 danger 槽删除
// before: WButtonTheme(danger: FilledButton.styleFrom(backgroundColor: scheme.error))
// after:  危险样式放项目 AppButtons.danger / style，不再有全局 danger 槽
```

`WButtonTheme.styleFor(...)` 的外部调用改为直接取 `theme.filled` / `theme.outlined` /
`theme.text`，或走 `WButton` 内部逻辑；如果外部只是读取样式，建议不要依赖 `styleFor`。

## 影响面

### 代码 / 测试

- `packages/ui/lib/src/components/common/button/button.dart`：三个命名构造器、私有 kind、
  `build` 分发。
- `packages/ui/lib/src/components/common/button/button_variant.dart`：删除公开枚举；
  如内部需要，改为私有 `_WButtonKind`。
- `packages/ui/lib/src/components/common/button/button_theme.dart`：`styleFor` 私有化 /
  改签名，并删除 `danger` 槽与 `copyWith` / `lerp` 的 `danger` 参数。
- `packages/ui/test/button_test.dart` / `button_golden_test.dart` / `audit_8_0_test.dart` /
  `value_objects*_test.dart`：构造方式与 golden。
- 仓库内 `WButton(` 约 **80 处**（代码 + 模板），`variant:` 约 **15 处**，`style:` 约 **36 处**；
  其中 `variant: danger` 约 5 处（测试 / example / docs），迁移为 `.filled(style: dangerStyle)`。

### example / CLI 模板

- `packages/ui/example/lib/buttons_page*.dart`、`nav_page.dart` 等：`variant:` → named；
- `packages/ui/example/lib/app_buttons.dart` 与 `packages/cli/templates/app_buttons.dart.tpl`：
  仍返回 `ButtonStyle`，但调用点必须改成 `WButton.outlined(style: AppButtons.secondary(...))`
  这类显式构造；是否删除 `AppButtons`、改用 `WButtonTheme` 是独立的 **L** 任务，不在本次内。
- `packages/cli/templates/agents/{zh,en}/ui.md`、`ui_README*`、`design_system_README*`：
  更新按钮示例。

### catalog / 文档

- `packages/cli/catalog/components.yaml`：
  - `WButton` 的 usage / pitfalls / related 改为 named constructors；
  - 删除 `WButtonVariant` 条目；
  - `WButtonTheme` 的 related / usage 改为三槽，补“不再有 `styleFor` 公开方法”，
    并说明 danger 走项目 `AppButtons.danger` / `style`。
- `docs/agents/button.md`、`docs/modules/ui_module.md`、`packages/ui/README.md`、
  `docs/agents/ui.md`：示例与选择规则；危险按钮示例改为
  `WButton.filled(style: AppButtons.danger(context), ...)`。
- `docs/migrations/ui-13.0.md`：named constructors 对照 + `WButtonVariant` / `WButtonTheme.danger`
  删除说明；与 `WScaffold.basic` 删除共用同一份 13.0 迁移文档。
- `packages/ui/CHANGELOG.md` 的 `## 13.0.0`：
  `### Breaking` / `### Removed` 列出上述公开名。

### 版本与门禁

- `packages/ui/pubspec.yaml` → `13.0.0`。
- `packages/cli/lib/src/init/versions.dart` 的 `w_tools_ui: ^13.0.0`。
- 根 `pubspec.yaml` 的 `w_tools_ui: ^13.0.0`；根 / CLI 的 `## Unreleased`。
- `python3 scripts/check_removed_api.py`：登记 `WButtonVariant`、`WButton.styleFor`、
  `WButtonTheme.danger` 等被删名。
- `python3 scripts/check_api_budget.py --package ui`（ADR-0011；删除通常减面）。
- `python3 scripts/check_public_api_diff.py --package ui`。
- `bash scripts/check_docs.sh`、`bash scripts/preflight.sh --changed`。

## 待确认（实现前）

1. 是否在 12.x 先保留 `WButton(...)` 作为 `.filled` 的 `@Deprecated` 别名，13.0 再删；
   本文按 **13.0 直接删** 记录。
2. `WButtonVariant` 是否完全删除，还是保留为 `@Deprecated` 到 14.0（当前按完全删除记录）。
3. `WButtonTheme.danger` 是否完全删除（当前按完全删除记录；若未来加 `tone`，再设计新槽位）。
4. `AppButtons` 的修复是否另开 **L** 任务（推荐是；本次只保证新 API 下调用点类型正确）。

## 验收（实现时）

```bash
cd packages/ui && flutter test
cd packages/ui/example && flutter test
cd packages/cli && dart run tool/gen_catalog.dart && dart run tool/gen_templates.dart
dart test                                  # packages/cli
cd ../..
python3 scripts/check_removed_api.py
python3 scripts/check_api_budget.py --package ui
python3 scripts/check_public_api_diff.py --package ui
bash scripts/check_docs.sh
bash scripts/preflight.sh --changed
```


---

## 发布结果（2026-11-18）

- PR #326 合并；ui 13.0.0 / cli 2.4.0 发布；快照 PR #327 合并；root 19.0.0 发布。
- `python3 scripts/release_status.py --online --check`：状态正常。
- `check_publish_drift`：ui / cli / root 无漂移。
