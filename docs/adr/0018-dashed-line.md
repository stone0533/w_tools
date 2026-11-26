> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0018：WDashedLine 作为 ui 的水平虚线原语

- 状态：已采纳（2026-11-26）
- 相关：[`w_tools_ui` 模块文档](../modules/ui_module.md) · [`components.yaml`](../../packages/cli/catalog/components.yaml)

## 背景

ureward 的 `lib/app/design_system/w_dashed_line.dart` 以 `// STAGED: 待上移到 w_tools_ui`
标记，已有 6 处使用（钱包卡 / 交易详情 / 商家记录 / 结果页）；仓库的待补清单也把
“虚线分隔”列为应进入 `w_tools_ui` 的通用视觉原语（`docs/modules/components.md` §10）。

原实现是项目内组件：依赖 ureward 的 `ScreenUtil .w`、`color` 必填、只处理水平线，
且没有对 `dashWidth + dashGap <= 0` 的防御（release 下 `while` 可能死循环）。直接复制会把
项目适配带进库，也不能满足主题 / 边界 / 测试要求。

## 决策

1. 在 `w_tools_ui` 增加公开组件 `WDashedLine`，只做**水平**虚线；竖线等有真实需求时再以
   additive 参数扩展，不提前设计 `axis`。
2. API 固定为逻辑像素：`color` / `thickness` / `dashWidth` / `dashGap` / `indent` /
   `endIndent`；`color` 为 null 时先取 `DividerTheme.color`，再回退
   `ColorScheme.outlineVariant`。
3. 库内不依赖 `ScreenUtil`；需要按设计稿缩放时由调用方传入已缩放值
   （例如 `1.w` / `WScreen.of(context).w(1)`）。
4. `thickness > 0`、`dashWidth > 0`、`dashGap >= 0`、缩进非负用 assert 校验；painter
   在 release 下对 `dashWidth + dashGap <= 0` 直接返回，避免死循环。
5. 宽度跟随父级，和 Material `Divider` 一样要求宽度有界；`Row` 中用 `Expanded`。
6. 作为普通组件（`teach: false`）登记 catalog，不进入 `entrypoints.yaml`，避免为一个
   装饰原语增加 AGENTS 模板预算。
7. 按 ADR-0011 在 `scripts/api_budget.yaml` 登记新类型例外，`until: 15.0.0`。

## 后果

- ureward 可删除 staged 副本，统一使用 `w_tools_ui` 的实现；其他项目也获得同一虚线原语。
- 新增公开类型使 ui 进入 minor（14.2.0），根包 / CLI 约束随之抬升；新类型需要 ADR 例外在
  15.0.0 前保持登记。
- 代价：只支持水平线；需要竖线时再开 additive API，而不是现在猜参数。

## 落地结果

未执行。
