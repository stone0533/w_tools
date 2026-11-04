> 决策记录：记录当时的决策背景；当前实现以模块文档和代码为准。

# ADR 0004：组件配置模型——不可变值对象 + 显式作用域

- 状态：已采纳（2026-11-03）
- 相关：[`docs/analysis/2026-11-03-remediation-plan.md`](../analysis/2026-11-03-remediation-plan.md)（阶段 3）、
  [ADR-0002](0002-consumers-depend-on-subpackages.md)、[ADR-0003](0003-subpackage-typography-without-ui.md)、
  [`docs/conventions.md`](../conventions.md) §6

## 背景

评审发现同一类能力存在多种载体，且互相不可组合：

1. **可变 Config + 链式 setter**（`WFormTextFieldConfig`、旧 `WToastConfig`）：
   不能 `const`，共享会串味，`copyWith(null)` 不能清空；`build()` 成了事实上的公开入口。
2. **静态全局变量**（`WFormDefaults`、`WConfig`）：不可测试、跨测试污染，需要 `reset()` 兜底。
3. **作用域 Widget**（`WFormTheme`、`WAsyncTheme`）：能力正确，但每个包各写一套。
4. **布尔并列**（`bordered` / `readOnly` / `showLoading` …）：多状态场景要靠多个 bool 组合，
   调用方与实现方都容易漏。

结果是：同一个语义有三种写法，文档要解释“什么时候用哪个”，行为也容易出现分歧
（同一字段经 `Config.build` 与直接字段两条路径默认值不同）。

## 决策

1. **新增或重构的公开配置类型一律是不可变值对象**：
   `const` 构造、`final` 字段、`copyWith` 用哨兵（传 `null` 表示清空）、实现 `==` / `hashCode`。
   示例：`WToastStyle`、`WAsyncOptions`、`WFormIcons`、`WImageStyle`。
2. **命名按职责**：
   - `XxxStyle`：视觉样式（颜色、字号、圆角、builder）；
   - `XxxOptions`：行为选项（回调、重试、超时、合并策略）；
   - `XxxIcons`：一组同语义资源；
   - `XxxTheme`：通过 `InheritedWidget` 提供作用域默认值（`WFormTheme` / `WAsyncTheme` / `WToastTheme`）。
   不再新增 `XxxConfig`；存量 `WForm*Config` 在 form 4.0 迁移。
3. **不提供公开 `build()`**：组件的组装逻辑留在包内（`@internal` 或私有函数），
   公开入口只有组件本身与它的 `Style` / `Options`。
4. **布尔并列改为枚举**：同一维度有 3 种及以上状态（或互斥组合）时定义 enum
   （如 `WButtonType`、`WAsyncStatus`），不要用多个 bool 表达。
5. **默认值来自 Theme**：样式默认值必须从 `ColorScheme` / `TextTheme` 派生，
   禁止在默认样式里出现字面量色值（form / toast / async 由 `scripts/check_style_literals.py` 守护）。
6. **作用域选择**：
   - 需要跟着 `ThemeData` 走、参与主题合并的 → `ThemeExtension`（如 `WTextStyles`）；
   - App 级别、不参与主题的开关 / builder 集合 → `InheritedWidget`（如 `WAsyncTheme`）。
7. **破坏性变更两段式**（见 [ADR-0002](0002-consumers-depend-on-subpackages.md) 与 D2）：
   先弃用 + 迁移表，下一个大版本删除。

## 影响

- 调用方从“改字段”变成“换实例”，`const` 与 `==` 让缓存 / 重建判断可靠；
- 每个能力只有一个入口，文档与测试面收敛；
- 代价：迁移期需要同时维护旧可变 Config（弃用壳），且 `copyWith` 需要哨兵实现；
- `WForm*Config` 的可变 API 仍保留到 form 4.0，期间新代码用直接字段 + `Style`。

## 不做什么

- 不引入代码生成（`freezed` 等）来生成值对象：当前规模下手写 `copyWith` / `==` 更可控；
- 不把运行期状态放进 `Style` / `Options`（如 loading 计数）：状态放到独立对象
  （`WAsyncLoading`）或控制器里；
- 不为了“统一”强行把各包的作用域 Widget 合并成一个跨包类型。
