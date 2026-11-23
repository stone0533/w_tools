# w_tools_form 字段样式作用域：9.0 结构清理（待执行）

- 日期：2026-11-23
- 状态：**待执行（目标 `w_tools_form` 9.0.0）**；功能已在 8.2.0 提供
- 关联：`docs/feedback/form.md` 第 2 条（字段样式作用域整体替换）
- 涉及文件：`packages/form/lib/src/components/form_field_style.dart`

## 背景

反馈 #2：`WFormFieldStyleScope` 默认整体替换页面 `WForm.fieldStyle`，catalog / README 的
示例只传 `height: 72`，照抄会静默丢掉 `containerPadding` / `textStyle` / `placeholderStyle`。

8.2.0 的处理（已完成，行为已定型）：

- `WFormFieldStyleScope.mergeWithParent`（默认 `false`）：`true` 时按「非 null 覆盖」逐字段
  合并外层样式；默认仍整体替换。`style: null` 在默认下=清空，在 `mergeWithParent` 下=沿用。
- `WFormFieldStyle.of(context)`：最近 scope 开启合并时，用 `visitAncestorElements` 向上找
  各层 scope，并对每层用 `dependOnInheritedElement` 注册依赖（页面 `fieldStyle` 运行期
  变化时字段会重建）；遇到整体替换的 scope 就停止。
- `WFormFieldStyle.copyWith`：显式派生完整样式（需要清空某项 / 依赖关系要可见时用）。
- 文档 / catalog / example 全部改为 `mergeWithParent: true` 写法。

**为什么没在 8.2.0 改结构**：`WFormFieldStyleScope` 是已发布的 `InheritedWidget`，改成会
`build` 的 widget 会删掉公开的 `WFormFieldStyleScope.updateShouldNotify`，按仓库门禁只能随
major 做；而功能本身用「读时合并」就能非破坏地落地，所以结构清理留到 9.0。

## 9.0 目标结构

1. `WFormFieldStyleScope` 改为 `StatelessWidget`：
   - `build` 里先 `WFormFieldStyle.of(context)` 解析父样式，再用 `_mergeStyles` 合并；
   - 包一层私有 `_WFormFieldStyleScopeData`（`InheritedWidget`）下发 effective style。
2. `WFormFieldStyle.of(context)` 回到「读最近一层 data」，删除祖先遍历 /
   手动跳过最近 scope / 多次 `dependOnInheritedElement`。
3. 行为保持不变：
   - 默认整体替换；`mergeWithParent: true` 合并；
   - `style: null` 的两种含义不变；中间层整体替换仍会截断合并。
4. 可选：加 `WFormFieldStyleScope.merge({required style, required child})` 命名构造，
   与 Flutter 的 `DefaultTextStyle.merge` / `IconTheme.merge` 对齐；`mergeWithParent`
   保留，不急着改名或废弃。

## 迁移影响（breaking）

- 删除 `WFormFieldStyleScope.updateShouldNotify`（它只是 `InheritedWidget` 的副产品）。
- `WFormFieldStyleScope` 不再是 `InheritedWidget`：直接
  `dependOnInheritedWidgetOfExactType<WFormFieldStyleScope>()` 的代码失效，改用
  `WFormFieldStyle.of(context)`（`docs/modules/form_module.md` 一直就是这个入口）。
- `WFormFieldStyleScope(style: ..., mergeWithParent: ..., child: ...)` 调用点不变。
- 新增 `docs/migrations/form-9.0.md` 记录以上两点。

## 执行清单

- [ ] `form_field_style.dart`：scope 改 `StatelessWidget` + 私有 data；简化 `of`；
      保留 `mergeWithParent` / `copyWith` / `style: null` 语义。
- [ ] 测试：`packages/form/test/field_style_test.dart` 的 6 条 merge 用例不改应全绿；
      补一条结构测试或只写迁移说明（`dependOnInheritedWidgetOfExactType` 不再命中）。
- [ ] 文档：`docs/agents/form.md`、`docs/modules/form_module.md`、`packages/form/README.md`
      中若仍提到 `InheritedWidget` 一并更新。
- [ ] catalog `WFormFieldStyleScope` 条目：若新增 `.merge` 构造，补 usage / pitfalls；
      跑 `dart run tool/gen_catalog.dart`。
- [ ] `packages/form/CHANGELOG.md` 写 `## 9.0.0` 的 `Breaking`；
      `docs/migrations/form-9.0.md`；根 / CLI 约束抬到 `^9.0.0`。
- [ ] `bash scripts/preflight.sh --changed` + `bash scripts/release_check.sh`。

## 验收标准

- 默认替换 / `mergeWithParent` / `style: null` / 截断语义与 8.2.0 完全一致（同一组测试不改）。
- `updateShouldNotify` 的删除写在 `Breaking`，迁移文档给出 `WFormFieldStyle.of` 写法。
- 与 `WFormFieldStyle.hintStyle`、`WFormTextField.label` 等 `remove-in: 9.0.0` 清理同一批发布，
  不为这一个结构改动单独抬 major。

## 预算 / 版本

- 9.0 会删掉 `hintStyle` 等成员，公开面成员数下降；新增 `.merge` 构造不会撞
  `scripts/api_budget.yaml`，无需 ADR / 例外。
- 版本：`w_tools_form` 8.2.0 → 9.0.0；根包与 CLI 只抬约束。
