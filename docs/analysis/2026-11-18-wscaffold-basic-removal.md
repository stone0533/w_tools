# 删除 `WScaffold.basic`：决策记录与执行清单

- 日期：2026-11-18
- 状态：**已发布（2026-11-18）**；随 `w_tools_ui` 13.0.0 / `w_tools` 19.0.0 上线
- 目标版本：`w_tools_ui` **13.0.0**（12.0.1 → 13.0.0；breaking）
- 决策：**删除 `WScaffold.basic`**，不做“默认构造器反转 + `.custom`”方案；页面统一用
  `WScaffold(appBar: WAppBar(...))`。

## 背景

`WScaffold.basic` 是 11.0.0 拆出来的“自动构造 `WAppBar`”入口
（`packages/ui/lib/src/components/layout/scaffold.dart`）。它几乎没有独立行为：

```dart
// WScaffold.basic
WScaffold.basic(title: '订单详情', actions: [...], body: ...);

// 等价写法
WScaffold(
  appBar: WAppBar(title: '订单详情', actions: [...]),
  body: ...,
);
```

差异只有：

1. `.basic` 断言 `title` / `titleWidget` 至少有一个；
2. `.basic` 把顶栏收窄为 `WAppBar`，不允许任意 `PreferredSizeWidget`；
3. 少写一层 `WAppBar(...)`。

维护者判断：这层语法糖不值得继续作为公开构造器存在，决定删除。

## 影响面（实现时逐项确认）

### 公开 API

- 删除构造器 `WScaffold.basic`（含 `WScaffold.basic` tear-off / 签名）。
- 只服务于 `.basic` 的公开成员一并评估删除：
  `title` / `titleWidget` / `leading` / `actions` / `onBack` /
  `automaticallyImplyLeading` / `centerTitle` / `appBarStyle` / `appBarBottom`；
  以及私有 `_basic` 标志与 `build` 中的分支。
- 主构造器 `WScaffold({appBar, body, ...})` 不变；替代写法：
  `WScaffold(appBar: WAppBar(title: ..., actions: ...), body: ...)`。
- `check_removed_api.py` 增加 `WScaffold.basic` / 被删成员的模式；跑
  `python3 scripts/check_removed_api.py`。
- `python3 scripts/check_api_budget.py --package ui`（ADR-0011 公开面预算；删除通常减面）。

### 仓库内调用点

- 代码 / 模板：约 38 处（`packages/ui/test`、`packages/ui/example`、
  `packages/cli/templates/app_scaffold.dart.tpl` 等）。
- 文档：`packages/ui/README.md`、`docs/modules/ui_module.md`、`packages/cli/catalog/components.yaml`、
  `docs/migrations/ui-11.0.md`（历史，不改）、`docs/agents/**`。
- `const WScaffold.basic` 约 3 处；迁移后可用
  `const WScaffold(appBar: WAppBar(...))`（参数都为 const 时）。
- CLI 模板 `app_scaffold.dart.tpl` 是消费方可见输出：改它需要 CLI 版本 / CHANGELOG /
  `gen_templates.dart` / `init_test` 同步。

### 版本与发布物料

- `packages/ui/pubspec.yaml` → `13.0.0`；`packages/ui/CHANGELOG.md` 写 `## 13.0.0` 的
  `### Removed`（说明替代写法）。
- `docs/migrations/ui-13.0.md` + `docs/migrations/README.md` 索引。
- `packages/cli/lib/src/init/versions.dart` 的 `w_tools_ui: ^13.0.0`。
- 根 `pubspec.yaml` 的 `w_tools_ui: ^13.0.0`；根 / CLI 的 `## Unreleased`
  （或随版本发布折叠，按 `docs/releasing.md` K-2）。
- `check_versions.py` / `release_check.sh` 必须通过。
- 本任务只准备代码与物料，**不执行发布**；发布另走 K-1 / K-2 / K-4。

### 测试与教学

- 更新 `packages/ui/test/layout_widgets_test.dart` 中 `.basic` 的用例：
  - 标题 / 返回 / actions / `appBarBottom` 行为改为显式 `WAppBar` 断言；
  - 删除“`.basic` 必须提供 title”这一类构造器专属用例，改为 `WAppBar` 允许空标题的现状。
- example（`scaffold_page` 等）与 CLI 生成模板改成显式 `WAppBar`。
- catalog：`WScaffold` 的 usage / pitfalls / related 改为显式 `appBar`；删除 `.basic` 推荐。
- `templates/agents/{zh,en}/ui.md`（若提到 `.basic`）、README、`docs/modules/ui_module.md`、
  `docs/agents/ui.md` 同步。
- golden 若覆盖默认顶栏，需要重跑 / 更新。

## 待确认

1. **是否先在 12.x 标 `@Deprecated('用 WScaffold(appBar: WAppBar(...))')`，13.0 再删？**
   还是 13.0 直接删除（本文默认按后者记录）。
2. `.basic` 专属的公开字段（`title` / `actions` / `appBarStyle` 等）是否随构造器一起删除；
   若保留，它们会变成永远为 null 的死字段，建议一并删。
3. CLI 模板 `app_scaffold.dart.tpl` 是否同批改成显式 `WAppBar`（会触发 CLI 版本 + 模板再生成）。

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

- 与 WButton named constructors 同一个 PR #326 / 发布波次。
- ui 13.0.0、root 19.0.0 已发布；`WScaffold.basic` 已从 13.0.0 移除。
