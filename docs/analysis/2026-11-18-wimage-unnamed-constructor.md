# `WImage.source` 改为无名构造器：决策记录与执行清单

- 日期：2026-11-18
- 状态：**已发布（2026-11-18）**；`w_tools_ui` 14.0.0 / `w_tools_cli` 2.6.0 / `w_tools` 20.0.0
- 目标版本：`w_tools_ui` **14.0.0**（13.0.0 → 14.0.0；breaking）
- 决策：删除 `WImage.source`，改为 **无名 `WImage(...)`**：
  ```dart
  WImage(
    source: WImageSource.network(url),
    style: const WImageStyle(width: 120, height: 120),
  )
  ```
  参数名 `source:` 不变，迁移只是 `WImage.source(` → `WImage(`。

## 背景

`WImage.source` 是 6.0 图片入口收敛时的迁移标记：

```text
删除 WImage(data:) / WImage.network / asset / file / base64 / provider / memory
统一为 WImage.source(source: WImageSource...)
```

现在它已经是**唯一公开构造器**，工厂只是转发到私有 `WImage._`：

```dart
factory WImage.source({
  required WImageSource source,
  ...
}) => WImage._(...);
WImage._({...});
```

因此 `.source` 不承载额外语义，只造成：

- `WImage.source(source: ...)` 构造器名和参数名重复；
- 与 Flutter `Image(image: provider)` 的习惯不一致（命名构造器通常用于不同来源，
  而不是“唯一入口”）；
- 文档 / catalog / example / Playground 都要多写一个词。

## 影响面

### 公开 API

- 删除 `WImage.source`；
- 新增无名工厂 `WImage({required WImageSource source, ...})`（参数、默认值、断言不变）；
- 私有 `WImage._` 保留；
- `check_removed_api.py` 登记 `WImage.source`；
- `check_public_api_diff --package ui`、`check_api_budget --package ui`。

### 仓库内调用点

- `WImage.source` 约 **112 处代码 / 模板**、**160 处文档**（含 README / example / Playground）；
- 主要文件：
  - `packages/ui/lib/src/components/common/image/image.dart`
  - `packages/ui/example/lib/**`（含 `playground_snippet.dart` 的代码面板字符串）
  - `packages/ui/test/**`（图片测试与文档示例测试）
  - `packages/cli/templates/**`（若有图片示例）
  - `packages/ui/README.md`、`docs/modules/ui_module.md`、`docs/agents/ui.md`、catalog

### 版本与发布物料

- `packages/ui/pubspec.yaml` → `14.0.0`；`packages/ui/CHANGELOG.md` 写 `## 14.0.0` 的
  `### Breaking`（说明 `WImage.source` → `WImage`）。
- `docs/migrations/ui-14.0.md` + `docs/migrations/README.md` 索引。
- `packages/cli/lib/src/init/versions.dart` 的 `w_tools_ui: ^14.0.0`。
- 根 `pubspec.yaml` 的 `w_tools_ui: ^14.0.0`；根包版本按 re-export breaking 抬 major
  （当前 19.0.1 → 20.0.0）；根 / CLI 的 `## Unreleased` 或版本段。
- `check_versions.py` / `release_check.sh`。
- 本任务只准备代码与物料，**不发布**；发布另走 K-1 / K-2 / K-4。

### 测试

- 图片相关测试（`image_*`、`docs_examples_test`、example smoke / playground）替换构造器；
- 视觉不变，golden 不需要改；
- 加一条非常小的构造器 smoke 测试，确认 `WImage(source: ...)` 可使用。

## 待确认

1. 14.0 直接删除 `WImage.source`，还是先在 13.x 标
   `@Deprecated('用 WImage(source: ...)')` 再于 14.0 删除（本文按直接 14.0 删除记录）。
2. 是否与下一轮 ui 清理合并发布（本项只是命名，优先级低于功能修复）。

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

## 实现结果（2026-11-18）

- `WImage.source` 已删除，`WImage({required WImageSource source, ...})` 为唯一入口；
- 仓库内代码 / 模板 / 当前文档全部迁移；历史 migration / CHANGELOG 保留原文；
- `check_removed_api` 已登记 `WImage.source`；
- `docs/migrations/ui-14.0.md` 已写；
- ui 14.0.0 / cli 2.6.0 / root 20.0.0 已发布；快照 PR #339 已合并。


## 发布结果（2026-11-18）

- PR #338 合并；快照 PR #339 合并。
- `w_tools_ui` 14.0.0、`w_tools_cli` 2.6.0、`w_tools` 20.0.0 已发布。
- `release_status --online --check`：状态正常；`check_publish_drift`：三包无漂移。
