# AppButtons 配对契约与回归测试（L 任务）

- 日期：2026-11-18
- 状态：**已实现（2026-11-18）**；CLI 模板 / ui_README / example / 测试已落地，未发布
- 场景：**L（改 w_tools_cli / init 模板）**，附带 `packages/ui/example` 镜像与测试
- 依赖：[`WButton` 改用 named constructors](2026-11-18-wbutton-named-constructors.md)
  （需要 `WButton.filled` / `.outlined` / `.text` 才能写新契约；不要在 12.x 提前改）

## 决策

保留 `AppButtons` 作为**项目级 `ButtonStyle` 注册表**，不把它改成
“类型 + 样式”的复合对象；用**文档注释 + 测试**把每个方法与 `WButton` 构造器的配对锁住。

## 配对契约

| `AppButtons` 方法 | 返回样式来源 | 必须搭配 |
|---|---|---|
| `primary(context)` | `FilledButton.styleFrom` | `WButton.filled(...)` |
| `secondary(context)` | `OutlinedButton.styleFrom` | `WButton.outlined(...)` |
| `text(context)` | `TextButton.styleFrom` | `WButton.text(...)` |
| `danger(context)` | `FilledButton.styleFrom(error)` | `WButton.filled(...)` |

理由：`ButtonStyle` 只是属性包，**不携带“我是哪种按钮”**；`AppButtons.text` 配
`WButton.filled` 会得到 FilledButton 的默认背景 + TextButton 的前景色，出现同色不可见
（已在 12.0.1 上验证 `fg == bg`）。

## 改动清单（实现时）

### CLI 模板

- `packages/cli/templates/app_buttons.dart.tpl`：
  - 每个 `static ButtonStyle` 增加文档注释，写明“配合 `WButton.filled` / `.outlined` /
    `.text` 使用”；
  - 文件头补一句：`AppButtons 只提供样式，不改变按钮类型；调用点必须使用匹配的构造器`。
- `packages/cli/templates/ui_README.md` / `ui_README.en.md`：
  - 增加 AppButtons → WButton 构造器对照表；
  - 所有示例改为显式构造器（`WButton.outlined(style: AppButtons.secondary(context), ...)`）。
- `packages/cli/templates/design_system_README.md` / `.en.md`：
  - 补一句 `AppButtons` 只负责样式，不负责类型。
- `packages/cli/catalog/components.yaml`：
  - `WButton` 的 pitfalls 增加“`style` 不改变按钮类型；AppButtons.primary/danger 配
    `.filled`，secondary 配 `.outlined`，text 配 `.text`”；
  - 跑 `dart run tool/gen_catalog.dart`。

### ui example（模板镜像）

- `packages/ui/example/lib/app_buttons.dart`：与模板保持同一份注释 / 契约。
- `packages/ui/example/lib/buttons_page.dart`、`buttons_page_sections.dart`、
  `nav_page.dart` 等所有 `WButton(style: AppButtons.*)` 调用点改成匹配构造器：
  ```dart
  WButton.outlined(style: AppButtons.secondary(context), label: '取消', onTap: cancel);
  WButton.text(style: AppButtons.text(context), label: '查看更多', onTap: more);
  WButton.filled(style: AppButtons.danger(context), label: '删除', onTap: remove);
  ```

### 测试

- `packages/ui/example/test/` 新增配对回归测试：
  - 对 `primary` / `secondary` / `text` / `danger` 分别用对应构造器挂载；
  - 断言渲染的 Material 类型（`FilledButton` / `OutlinedButton` / `TextButton`）；
  - 断言前景色 != 背景色，防止“同色不可见”回归。
- `packages/cli/test/internal/init_test.dart`（或模板新鲜度测试）：
  - 断言生成的 `app_buttons.dart` 含四个方法的配对注释；
  - 断言 `ui_README` 的示例使用 `.filled` / `.outlined` / `.text`。

### 版本 / 文档

- `w_tools_cli` 当前 2.3.11；模板 / catalog / 教学变化至少抬 patch（实现时按 semver 确认），
  写 `packages/cli/CHANGELOG.md`；改 catalog 后跑 `gen_catalog.dart`，改模板后跑
  `gen_templates.dart`。
- 仓库文档 `docs/agents/button.md`、`docs/modules/ui_module.md`、`packages/ui/README.md`
  的文件配对说明，建议随本任务一起改；若按场景拆分，则归 **F** 另开，不要混进 L 的代码改动。
- 不新增公开库 API；`AppButtons` 仍是生成的项目文件，不是 `w_tools_ui` 公开类型。

## 不在本任务内

- 不把 `AppButtons` 改成 `(variant, ButtonStyle)` record 或 `WButtonPreset`；
- 不恢复 `WButton.danger` / `WButtonTheme.danger`；
- 不处理 `WScaffold.basic`（独立任务，见
  [`ui-13.0` 删除记录](2026-11-18-wscaffold-basic-removal.md)）。

## 验收（实现时）

```bash
cd packages/cli && dart test
cd ../..
cd packages/ui/example && flutter test
cd ../..
bash scripts/check_docs.sh
bash scripts/preflight.sh --changed
```
