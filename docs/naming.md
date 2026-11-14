# 命名规范

> 本文是命名规则的**唯一事实源**：规则写在这里，存量例外登记在
> [`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml)。
> ADR 只记录「为什么」（[ADR-0004](adr/0004-component-config-model.md) /
> [ADR-0005](adr/0005-app-options-and-plugin-ownership.md) /
> [ADR-0007](adr/0007-component-naming-roles.md)）；组件事实在 catalog；生成物不手改。
> ADR / CHANGELOG 里出现具体名字只作为历史证据，与本文冲突时以本文为准。

- 读者：维护者 / 仓库 AI；消费方看到的公开名字同样受本文约束
- 覆盖：包、目录、文件、公开 / 私有类型、成员、测试、脚本、文档
- 不覆盖：消费方业务模型与界面文案；JSON 字段；路由字符串；环境变量；第三方 API 的既有名字；
  生成物（`*.g.dart`、`catalog.g.dart`、`templates.g.dart`）
- 改规则 = 改本文 + [`scripts/check_naming.py`](../scripts/check_naming.py)（需要时）；
  改存量例外 = 改 [`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml)

**术语**

- **库包**：消费方依赖的 `w_tools_*` 包；`w_tools_cli` / `figma` / `device` / `e2e` 是工具包，不套 `W` 前缀。
- **公开面**：barrel `lib/w_tools_<pkg>.dart` 用 `export ... show` 导出的类型。
- **角色**：一个名字承担的那一个职责（§3.3）；一个名字只承担一个角色后缀。
- **存量 / 基线**：规则出现前已经存在的名字；可放行的登记在 `naming_baseline.yaml`。

## 目录

- [0. 三条总则](#0-三条总则)
- [1. 包与目录](#1-包与目录)
- [2. 文件](#2-文件)
- [3. 类型](#3-类型)
- [4. 私有实现与成员](#4-私有实现与成员)
- [5. 测试、脚本与文档](#5-测试脚本与文档)
- [6. 存量例外](#6-存量例外)
- [7. 机器校验边界](#7-机器校验边界)
- [8. 改名与迁移](#8-改名与迁移)
- [9. 规则如何演进](#9-规则如何演进)
- [10. 历史](#10-历史)

## 0. 三条总则

1. **先定作用域，再定角色，最后选词。** 同一个词在不同作用域含义不同：
   文件用 `snake_case`，类型用 `PascalCase`，成员用 `camelCase`。
2. **名词在前，角色在后。** 角色决定后缀（`WImageStyle`），
   不要用后缀暗示实现（`WImageHelper`）。
3. **一个名字只承担一个角色后缀。** 视觉归 `Style`、行为归 `Options`、
   作用域默认归 `Theme`；不造 `XxxConfigOptions` 这种双角色名，也不为了「像规范」硬加后缀。

### 30 秒选词流程

```text
1. 先看对象类别：
   组件        → W + 名词短语（§3.2），不加 Widget / Component / Control
   协作类型    → W + 名词 + 一个角色后缀（§3.3）
   成员 / 文件 → §4.2 / §2
2. 协作类型按 §3.3 的表从上往下判断，第一个成立的角色赢。
3. 没有合适的角色后缀 → 不套后缀，用组件专属名词；
   确实是存量例外 → 走 §6 的登记位，不要临时造词。
```

复杂情况按这个顺序展开：

```text
作用域（包 / 文件 / 类型 / 成员 / 测试 / 文档）
  → 对象类别（组件 / 协作类型 / 成员）
  → 角色（§3.3）
  → 后缀
  → 存量（§6，只减不增）
```

### 三个完整例子（示意）

以下名字只用于演示判断路径，不要求代码里存在；新增真实名字时按同样的顺序走。

```text
例 1：新增一个评分组件
1. 是组件 → W + 名词：WRatingBar（不加 Widget）
2. 有运行期控制（清空 / 提交）→ WRatingBarController
3. 样式参数 → WRatingBarStyle
4. 单个星 → WRatingStar（组件名词，不套后缀）

例 2：新增上传结果
1. 是返回结果 → WUploadResult（成功 / 失败 / 取消）
2. 成功分支 → WUploadSuccess
3. 失败分支 → WUploadFailure（不是 WUploadError）
4. 错误对象 → WUploadError

例 3：新增一组上传参数
1. 构造后不变、只影响怎么跑 → WUploadOptions
2. 运行期可改、跨调用复用 → WUploadSettings
3. 纯数据、不可变、要登记基线 → WUploadConfig（仅当确实没有行为）
```

> 规则约束**新增**名字。存量按 §8 的 breaking 流程评估，
> 不为了「名字合规」做无版本过渡的改名。
> 「只约束新增」也适用于行为约束：§3.4 的 Config 约束只对**新增** Config 生效，存量见 §6。

## 1. 包与目录

| 对象 | 规则 |
|---|---|
| 包名 | `w_tools_<领域>`，全小写 + 下划线；领域用完整单词（`map_google`，不是 `mapg`） |
| 根聚合包 | 固定 `w_tools`，只重导出基础子包（core / async / ui / form / api / toast） |
| 工具包 | `w_tools_cli` / `w_tools_figma` / `w_tools_device` / `w_tools_e2e`；不适用 §3.1 的 `W` 前缀 |
| 契约 / 实现 | 契约包用领域名（`w_tools_map`），实现包加实现限定词（`w_tools_map_google`） |
| `lib/` 布局 | `lib/src/` 放实现；库包用 `lib/w_tools_<pkg>.dart` 作为唯一公开入口；工具包入口在 `bin/` |
| 组件目录 | `lib/src/components/<分组>/<组件>/`；分组用 `layout` / `navigation` / `common` 这类用途词；单文件组件（如 `layout/step.dart`）可以不成目录 |
| 目录名 | `snake_case`；一个目录只放一组相关文件，不要让 `utils/` 变成杂物间 |
| `example` / `test` / `tool` | 不进公开面：example 是消费方视角，test 是内部测试，tool 是维护脚本 |

不新增 `w_tools_utils` / `w_tools_helpers` / `w_tools_common` 这类没有领域的包；
需要共用就放进已有的领域包，或新开有业务含义的包。

## 2. 文件

| 对象 | 规则 |
|---|---|
| Dart 文件 | `snake_case.dart`；不出现大写、连字符 |
| 一个文件 | 按角色拆：组件入口、`Style`、`Options` / `Config`、`State`、`Builder` 尽量各自成文件；同类小类型（enum / typedef / 变体）和同类组件（如 `direct_fields.dart`）可以聚合 |
| 组件文件 | 入口 `<组件>.dart`，其余按角色拆：`image_style.dart` / `image_source.dart` / `image_state.dart`。文件角色要和类型角色一致：`Options` 不要放进 `*_config.dart` |
| 平台实现 | `_io.dart` / `_web.dart` 等平台后缀；入口用条件导出，不在文件名里写平台判断 |
| barrel | `lib/w_tools_<pkg>.dart` 用 `export ... show` 控制公开面；`lib/src/**` 不直接对外 |
| 生成物 | `*.g.dart` 只由生成器写，不手改 |
| 测试 | `test/<主题>_test.dart`；golden 图放 `test/goldens/`；helper 放 `test/_helpers/` |
| example | `example/lib/main.dart` 是入口；页面用 `<名字>_page.dart` |

## 3. 类型

### 3.1 前缀

- 库包的公开类型（barrel 导出的 `class` / `enum` / `mixin` / `extension` / `typedef`）一律 `W` 前缀。
  只在 `lib/src` 里可见、或用 `hide` 隐藏的迁移壳不算公开类型，不参与命名门禁。
- 工具包不套 `W`：它们是给维护者用的 CLI / 设备工具，不是消费方 API。
- 例外只有一类：`DioRegistry` 这类基础设施入口（消费方只调用、不继承）。名字应该表达职责
  而不是品牌，登记在 [`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml)。
  api 6.0 已删除数据层空壳类型（`BaseRepository` / `IApiPath` / `ApiClientId`），基线随之收缩。
- 公开类型的首行 doc comment 写清它是什么；命名只负责可预测，不负责解释。
- 私有类型用 `_` 前缀且不导出；需要对应公开类型时写成 `_WImageState` 这种形式。

### 3.2 组件名

- `W` + 名词短语，回答「它长什么样 / 是什么」，不回答「给谁用」。
- 不加 `Widget` / `Component` / `Control` 后缀。
- 组件专属后缀（不属于 §3.3 的角色表，但同样只用一个）：

| 后缀 | 用途 | 例 |
|---|---|---|
| （无） | 组件名就是名词短语 | `WImage` / `WButton` / `WNavDestination` |
| `View` | 某个状态 / 数据的展示层；可以有交互，命令式控制放 `Controller` | `WAsyncView` / `WImageErrorView` / `WQrView` |
| `Page` | 全屏页面入口；当前没有公开的 `W*Page`，新增页面时使用 | — |
| `Scaffold` | 页面骨架 | `WScaffold` |
| `Sliver` | 某个列表 / 区块的 sliver 版本 | `WListViewSliver` / `WAsyncStateSliver` |

- `Builder` 是显式构建器（`WAsyncStateBuilder`），
  只能有一个 `build()` 入口。
- 组合优先用名词堆叠（`WFormTextFieldPasswordToggle`），不用 `With` / `And` 连接词；
  堆叠要能读成一个名词短语，不要把两个角色并排。

### 3.3 角色后缀

这是**判断流程**，不是分类学：`维度` 列只解释它为什么排在这一位，
`检查` 列的「弱」表示只能人工判断（§7）。

判定顺序**从上往下，第一个成立的赢**；`Config` 是角色后缀的最后兜底，不是默认。
引用某个角色时写「§3.3 第 5 行（Controller）」，行号就是判定顺序，不要只写后缀。

| 顺序 | 角色 | 后缀 | 维度 | 装什么 | 判定问句 | 典型例子 | 检查 |
|---|---|---|---|---|---|---|---|
| 1 | 视觉样式 | `Style` | 语义 | 颜色 / 字号 / 圆角 / 阴影 / fit | 只影响「长什么样」？ | `WImageStyle` / Material `ButtonStyle` | 弱 |
| 2 | 行为参数 | `Options` | 语义 | 回调 / 重试 / 超时 / 解码 / 放行规则 | 装的是行为字段（回调 / 重试 / 超时 / 解码 / 放行规则），不是纯数据？ | `WImageLoadOptions` / `WAsyncOptions` | 弱 |
| 3 | 作用域默认 | `Theme` | 作用域 | 给子树的一组默认值（可被局部覆盖） | 要给整棵子树兜底一组默认值？ | `WFormTheme` / `WImageTheme` | 弱 |
| 4 | UI 插槽 | `Slots` | 语义 | 占位 / 错误 / 进度 / 重试 | 替换组件内部的某块 UI？ | `WImageSlots` | 弱 |
| 5 | 运行期控制 | `Controller` | 构件 | 分页 / 重试 / 播放 / 滚动 | 有生命周期，要命令式调用？ | `WAsyncController` / `WMapController` | 弱 |
| 6 | 状态 | `State` | 语义 | 运行期状态 / widget `State<T>` / 不可变快照 | 是「当前状态」的载体？ | `WAsyncState` / `WStepState` | 弱 |
| 7 | 输入 | `Source` | 语义 | URL / 文件 / 字节 / 业务模型 | 描述「数据从哪来」？ | `WImageSource` / `WNetworkImageSource` | 弱 |
| 8 | 输出 | `Result` / `Failure` / `Error` | 语义 | 成功结果 / 失败分支 / 错误对象 | 是调用的返回值、失败分支或错误？ | `WAsyncResult` / `WAsyncFailure` / `WImageError` | 弱 |
| 9 | 构建入口 | `Builder` | 构件 | 组装 widget 的回调对象 | 需要调用方决定子结构？ | `WAsyncStateBuilder` / `WStepItemBuilder` | 弱 |
| 10 | 子树上下文 | `Scope` | 作用域 | 把 controller / 当前实例放进子树读取 | 要在子树里读写运行期上下文？ | `WFormScope` | 弱 |
| 11 | 种类 | `Type` / `Kind` | 语义 | 封闭枚举语义 | 是「哪一种」？ | `WImageType` / `WPlatformType` | 弱 |
| 12 | 组件数据 | `Data` | 语义 | 组件产出的纯数据 | 是组件内部流转的数据？ | `WScreenData` / `WFormTextFieldData` | 弱 |
| 13 | 列表项 | `Item` | 语义 | 列表单元模型 | 是列表里的一项？ | `WMapItem` / `WFormValidatorItem` | 弱 |
| 14 | 扩展 | `Extension` | 构件 | 给已有类型加方法 | 不改类型本身加能力？ | `WColorExtension` / `WBoxDecorationExtension` | 弱 |
| 15 | 回调 | `Callback` | 语义 | 公开签名里的函数类型 | 是公开的函数类型别名？ | `WCountdownCallback` | 弱 |
| 16 | 可变设置 | `Settings` | 生命周期 | 运行期可改的一组设置（不一定落盘） | 需要在运行期改一组设置？ | `WFormValidatorSettings` | 弱 |
| 17 | 调用参数 | `Params` | 生命周期 | 一次性入参 | 只是这次调用的参数？ | —（暂无公开类型） | 弱 |
| 18 | 不可变数据载体 | `Config` | 形态 | 纯数据、无业务行为、构造后不变 | 没有行为字段，只是一个不可变的值对象？ | `WLocaleConfig` | 强（基线） |

以上都不成立 → **不套角色后缀**，用组件专属名词（`WPressable` / `WNavDestination` 这类）；
不要为了「像规范」硬加一个后缀。

按维度看，18 行可以分成五组（这只帮助理解，不是分组优先级）：

| 维度 | 行 | 共同点 |
|---|---|---|
| 语义 | 1 / 2 / 4 / 6 / 7 / 8 / 11 / 12 / 13 / 15 | 名字回答「是什么」 |
| 作用域 | 3 / 10 | 默认值 vs 运行期上下文 |
| 生命周期 | 16 / 17 | 可变设置 vs 一次性入参 |
| 构件 | 5 / 9 / 14 | 控制 / 构建 / 扩展 |
| 形态 | 18 | 不可变值对象 |

实际判定仍然从上往下；不要按组跳着判断。

补充：

- `Options` 只装行为 / 生命周期，不装 UI；视觉一律 `Style`。
  例外：`WAppOptions` 是应用组合根，不是组件 Options；允许 `home` / `builder` / `appWrapper`
  这类组合根字段。应用外观统一走 `WAppTheme`（`theme` / `darkTheme` / `themeMode` /
  `systemUiOverlayStyle`），不要再往 `WAppOptions` 加视觉字段。
- `Options` 里必须有行为字段；如果全是数据，不要用 `Options`：视觉参数走 `Style`，
  组件内部流转的数据走 `Data`，其余独立的不可变值对象走 `Config`（`Theme` 只在需要给子树
  提供默认值时用）。
- `Theme` 是给子树提供一组默认值（可以放在 App 根部，也可以按页面隔离，如 `WFormTheme`）；
  只影响单个组件实例的局部默认值不要叫 `Theme`，放构造参数或 `Options`。
  它和 `Scope` 都可能内部用 `InheritedWidget`，区别是「默认值」还是「运行期对象」。
- `Scope` 的名字用被作用域的领域 / 对象：传 controller 用领域名（`WFormScope`），
  不要写 `<领域>ControllerScope`；作用域的对象本身是命名类型时，可以写 `<对象>Scope`
  （`WScreenScope`）。
- 复合名只允许「A 的 B」式修饰：`WFormFieldStyleScope` 读作「面向 `WFormFieldStyle` 的 Scope」，
  不是两个并列角色；`XxxConfigOptions` 这类并列角色仍然禁止。
- Flutter 既有名词（`ThemeData` / `Sliver` / `Route`）原样保留，不拆成两个角色。
- 扩展名的 `Extension` 前紧挨被扩展的类型，用途 / 领域限定词放在它前面：
  `<用途><目标类型>Extension`，不要写成 `<目标类型><用途>Extension`。
- 试用角色：`Slots` / `Settings` / `Params` 目前是窄角色，但都允许在新代码使用（不需要先转正）；
  出现第二个使用方后按 §9 评估是否转正；`Params` 暂无公开类型，暂不推广。
- 常见构件名词（不是角色后缀，确有其物时才用）：`Loader` / `Formatter` / `Interceptor` /
  `Mapper` / `Handler` / `Strings` / `Frame`。新增这类词前先看能否归入上表，不要造同义词。

同义择一：

| 你会犹豫 | 用 | 别用 | 判据 |
|---|---|---|---|
| 状态载体 | `State` | `Status` | `State` 是载体（`WAsyncState`）；`Status` 只表示封闭状态枚举 / 标签（`WAsyncStatus`） |
| 只读快照 | `Snapshot` | `State` | 只有强调「某一刻的不可变拷贝」才用（例如 `XxxSnapshot`），否则归 `State` |
| 失败分支 | `Failure` | `Error` | `Failure` 是 `Result` 的失败分支（`WAsyncFailure`） |
| 错误对象 / 视图 | `Error` | `Failure` | `Error` 是错误本身或错误视图（`WImageError` / `WImageErrorView`） |
| 返回值（成功 / 失败 / 取消） | `Result` | `Status` | 返回值用 `Result`，即使内部是 enum；`Status` 只描述过程阶段（idle / loading / ready） |
| 成组的样式 / 常量 | `Styles` | `Style` | 成组用复数（`WTextStyles`）；单组件参数用单数 `Style` |
| 子树默认值 | `Theme` | `Scope` | 一组默认值（`WFormTheme`），可被局部覆盖 |
| 运行期上下文 | `Scope` | `Theme` | controller / 当前实例进子树（`WFormScope`），不是默认值 |
| 构造后不变的行为参数 | `Options` | `Settings` / `Params` | 构造后不变（`WImageLoadOptions`） |
| 运行期可改的设置 | `Settings` | `Options` | 运行期可改（`WFormValidatorSettings`）；不要求落盘 |
| 一次性入参 | `Params` | `Options` | 一次调用有效，跨调用复用就归 `Options` / `Settings` |
| 运行期控制 | `Controller` | `State` | 有生命周期、命令式方法（`WAsyncController`）；纯数据用 `State` |

#### async 的窄角色

- `Activity`（`WAsyncActivity`）：并发活动计数器，不是加载视图；新代码优先复用，不另造 `LoadingCounter`。
- `Views`（`WAsyncThemeViews`）：默认视图解析器；新代码优先复用，不另造 `Resolver`。

### 3.4 Config 的硬约束

- 构造是 `const`，字段全是 `final`，实现 `==` / `hashCode`；背景见 [ADR-0004](adr/0004-component-config-model.md)。
- 禁止可变字段、公开 `build()`、组件组装、隐藏默认值的第二入口。
- 派生用 `copyWith` / `merge` / `resolve` / `toXxx`。
- 新增 Config 必须登记 [`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml)；
  `scripts/check_naming.py` 会拦未登记的名字。登记说明要写清是「允许」还是「存量债务」。
- 新增的、满足本节约束的 Config 登记为「允许」；存量不满足的登记为「债务」并冻结。
- 适用范围：只约束**新增** Config；存量里可变或缺少 `==` / `hashCode` 的按 §6 冻结。
  给存量补不可变 / `==` 属于行为变更，走 §8，不混在命名修复里。
- `Config` 不能装 UI 或行为：行为用 `Options`，UI 插槽用 `Slots`。

### 3.5 禁止的名字

- `XxxUtil` / `XxxHelper` / `XxxManager` / `XxxService`：没有角色，说明还没想清放哪。
- `XxxImpl` / `XxxNew` / `XxxV2` / `OldXxx`：版本进 CHANGELOG，不进名字。
- `XxxConfigOptions` 这类双角色名：一个名字一个角色。
- 可变 `XxxConfig`：要可变就用 `Controller` / `Options` / `Settings`。
- 用 `XxxData` 当业务模型：用领域名（`Order` / `User`）。
- 新接口不要用 `I` 前缀（api 的 `IApiPath` 已在 6.0 删除）：Dart 用抽象类 / mixin 表达接口。
- 自造缩写：`WImg` / `WBtn` / `WMsg`，用完整单词。
- 参数 / 成员名不要拿 `config` 兜住所有类型：`Options` 用 `options`，`Style` 用 `style`，
  `Slots` 用 `slots`；否则类型叫 `Options`、参数叫 `config`，两个角色又混在一起。

## 4. 私有实现与成员

### 4.1 私有类型

- `_` + 公开名（`_WImageState`、`_WFormScopeButton`）；没有对应公开类型时 `_` + 描述性名字。
- 私有类型不写进 barrel / catalog；`part` 不跨包。
- 不要为了绕过命名规则把该公开的类型改私有：需要公开就按公开规则命名。

### 4.2 成员

| 对象 | 规则 | 例子 |
|---|---|---|
| 回调字段 | `onXxx` | `onPressed` / `onChanged` |
| 布尔 | `isXxx` / `hasXxx` / `canXxx` / `shouldXxx` | `isLoading` / `hasMore` |
| 动作 | 动词开头，不加 `do` | `retry()` / `loadMore()` |
| 派生 | `copyWith` / `merge` / `resolve` / `toXxx` | `toJson()` |
| 工厂 | `.of` / `.from` / `.fromJson` | `WImageTheme.of(context)` |
| 枚举值 | `camelCase`，不重复类名 | `WImageType.network` |
| 常量 | `camelCase`，按语义分组 | `WShadows.card` |
| 参数 | 名词；布尔参数 `isXxx` / `hasXxx` / `canXxx`；回调 `onXxx`；不用 `enableXxx` | `child` / `builder` / `onChanged` |
| getter | 无副作用、O(1)、不抛业务错误 | `isLoading` |
| 方法 | 有副作用 / IO / 耗时 / 可能抛错 | `loadMore()` / `retry()` |
| 返回 Future / Stream | 用动词，不加 `Async` 后缀 | `loadMore()`，不写 `loadMoreAsync()` |

- `build()` 只允许出现在显式 `Builder` 上，且是该类型唯一入口；这里指**非 Widget 的公开
  `build()`**，`Widget.build` 的框架覆盖不在此列。
- 布尔字段不用 `enable` / `disable` 命名；状态用 `enabled`。
- 存量 `WButton.loading` 沿用 Flutter 习惯（不改成 `isLoading`）；新布尔参数仍按
  `isXxx` / `hasXxx` / `canXxx`。
- 索引基：`WStep.current` 是 1 基（与 `WStepItemBuilder` 的 1 基索引一致），
  这是冻结例外；新 API 统一 0 基。
- 泛型参数用 `T` / `TValue` / `TResult` 这类有含义的名字，不写 `T1` / `Type`。
- 抽象类 / mixin 用领域名词；不新加 `I` / `Abstract` 前缀，`Base*` 只作为存量。
- 集合用复数（`children` / `items`），映射用 `<值>By<键>`（`itemsById`）。
- 公开命名参数：布尔默认 `false`，必填用 `required`；参数数量规则见
  [`CONTRIBUTING.md`](../CONTRIBUTING.md)。

### 4.3 缩写

- 类型名里缩写按单词处理：`WQrView` / `WApiSettings`，不写成全大写缩写（如 WQR / WAPI 开头）。
- 成员和变量用单词式缩写：`baseUrl`，不写 `baseURL`；
  平台判断沿用 `dart:io` 的 `isIOS` / `isMacOS` 写法，这是平台名惯例，不推广到其他词。
- 不新造缩写：`usr` / `cfg` / `msg`；统一用 `url` / `api` / `id` / `json` / `qr` / `ui` / `http`。

### 4.4 顶层函数与常量

- 顶层函数不套 `W` 前缀：判定用 `is` / `has` / `can` 开头，动作直接用动词
  （`isRetryableNetworkError`）。它们仍是公开 API，要写 `///` 说明。
- 顶层常量用 `camelCase`；成组常量放进 `abstract final class` 承载
  （`WShadows` / `WGradients`）。

## 5. 测试、脚本与文档

| 对象 | 规则 |
|---|---|
| 测试 | `test/<主题>_test.dart`；一个文件测一个行为面；helper 放 `test/_helpers/`（只 import barrel；需要 `src` 的放 `test/internal/`） |
| golden | `test/goldens/<组件>_<状态>.png`，用 `--update-goldens` 生成 |
| 脚本 | `check_*` 只读检查，`gen_*` 生成物，其余用「动词_名词」；Python 用 `.py`，shell 用 `.sh` |
| 脚本参数 | kebab-case（`--with-tests`）；布尔开关不加 `=true` |
| 文档 | 新文档用 `kebab-case.md`；模块文档沿用 `<pkg>_module.md`；目录索引用 `README.md` |
| ADR | `NNNN-kebab-title.md`，编号四位递增（[规则](adr/README.md)） |
| CLI 子命令 | 单个短词，不加 `w_tools` 前缀：`init` / `doctor` / `context` / `list` / `explain` / `feedback` |
| 文档里的符号 | 行内代码中的 `W*` 必须真实存在，由 `scripts/check_doc_symbols.py` 检查 |

## 6. 存量例外

规则只约束**新增**名字。已经存在、但不符合角色的名字，不为「合规」做无过渡改名（见 §8）。
存量不是「一个文件收所有」，而是两个登记位 + 规则内冻结项：

| 登记位 | 收什么 | 说明 |
|---|---|---|
| `configs` | 公开 `W*Config` | 登记册：允许项、grandfather、冻结的遗留可变都要有一行 |
| `prefixes` | 不带 `W` 的公开类型 | api 数据层，消费方要继承或实现 |

[`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml) 是登记册，不是纯债务清单：
新增公开 `W*Config` 必须登记并写清原因（允许 / 债务）；债务行只减不增，
并尽量写计划版本或 issue（例如「计划 6.0 再评估」），只写「以后再说」的行在 review 时补目标。

不进基线、但在规则内冻结的例外：

- **组件级角色**：`WImageSlots`——角色还没推广（§3.3），不是「允许的新名字」。
- **旧扩展名**：7.0 已改为 `WImageStyleExtension` / `WColorExtension` /
  `WThemeDataExtension`；通知 Builder 的旧扩展已删除。
  这三个新名字按 §3.3 的 `Extension` 角色，不再登记例外。

以上两类不占基线，因为它们是「角色还没推广 / 规则例外」，不是「允许的存量名字」；
它们同样只减不增，新增同类名字按 §3.3 的 `Extension` 角色处理。

`scripts/check_naming.py` 直接读基线，并双向检查：

- 代码里有、基线里没有 → 新名字，先按 §3.3 选对角色；确实要保留才加行并 review；
- 基线里有、代码里已经没有 → 名字已删 / 已改，同步删行。

## 7. 机器校验边界

强度定义：

- **强**：preflight / CI 阻断，能自动判定；失败只能改代码或登记基线。
- **弱**：无法用正则 / AST 判定，只能人工判断；PR 描述里要写结论（见下方清单）。

| 规则 | 检查 | 强度 |
|---|---|---|
| 公开 `W*Config` 必须在基线登记 | `scripts/check_naming.py` | 强 |
| 基线里的名字必须仍存在于公开 API | `scripts/check_naming.py` | 强 |
| 库包公开类型 `W` 前缀 | `scripts/check_naming.py` | 强（基线 `prefixes`） |
| Dart 文件名 `snake_case` | `scripts/check_naming.py` | 强 |
| 公开类型进 catalog / `uncataloged.yaml` | `scripts/check_public_catalog.py` | 强 |
| ADR 文件名 / 编号 / 索引 | `scripts/check_docs_facts.py` | 强 |
| 本文示例里的符号 / 成员存在 | `scripts/check_doc_symbols.py` | 强 |
| 角色是否选对、成员命名、缩写、双角色名 | code review | 弱 |
| 复合名、参数名、`Settings` / `Params` 语义 | code review | 弱 |
| `Config` 不可变、`build()` 唯一 | review + 测试 | 弱 |

### review 清单（复制到 PR 描述）

1. 新公开类型有且**只有一个**角色后缀？按 §3.3 从上往下判断过？
2. 名字能读成「A 的 B」吗？有没有两个并列角色（`XxxConfigOptions`）？
3. `Config` 不可变、无行为、有 `==` / `hashCode`？新增 Config 登记基线了吗？
4. `Options` 里没有 UI？`Settings` 真的可变？`Params` 真的只用一次？
5. 公开 `build()` 只在 `*Builder` 上？
6. 改名 / 删除同步了 catalog、README、example、migration、baseline 吗？

**脚本通过 ≠ 命名合规。** 门禁只守「能被正则判定的名字」；
`Options` 里塞 UI、`Config` 藏 `build()` 这类问题仍然只能靠 review 发现。
本文里的反例（如 `WImg`）在 `scripts/check_doc_symbols.py` 的 `NAMING_DOC_IGNORE` 登记，
新增反例时同步。

可以先自动化的候选项（按性价比排序，加之前先量误报率）：

- 公开 `W*Config` 之外的可变类型（缺 `==` / 非 `const` 构造）；
- `Settings` / `Params` / `Slots` 的登记；
- 扩展名后缀（`*X` / `*Color` 之类）；
- 含 `Config` 但不以它结尾的复合名；
- 公开成员名（`build()` 唯一入口、`onXxx` 回调字段）。

不要为了覆盖率把规则变成噪声：每加一条检查，先确认它能稳定判定，
否则留在 review 清单里。

## 8. 改名与迁移

1. 先加新名字，旧名字标 `@Deprecated`，并在声明附近写 `/// remove-in: <x.y.z>`
   （`scripts/check_deprecations.py` 会拦缺到期版本或到期未删的项）；
2. 下个 major 删除旧名，跑 `python3 scripts/check_removed_api.py`，把旧名补进名单；
3. 补 `docs/migrations/<pkg>-<major>.md` 与对应 CHANGELOG；
4. 删掉 [`scripts/naming_baseline.yaml`](../scripts/naming_baseline.yaml) 里的旧行；
5. 公开变化按 [`AGENTS.md`](../AGENTS.md) 的分类同步 catalog、README、example、模板，
   并跑 `check_public_catalog.py` / `check_package_docs.py` / `preflight.sh`。

不要为了「名字合规」做无版本过渡的 breaking；[ADR-0007](adr/0007-component-naming-roles.md)
记录的「先冻结新增面、收口放下个 major」仍然有效。

## 9. 规则如何演进

角色不是一次定死的，但演进要有门槛：

| 状态 | 条件 | 落地 |
|---|---|---|
| 试用 | 有至少 1 个真实使用方，且判定问句能把它和现有角色区分开 | 写进 §3.3 的补充并标「试用」；不强制新代码使用 |
| 稳定 | 有至少 2 个真实使用方，且不会和现有角色抢名字 | 去掉「试用」，更新 §7 与 review 清单 |
| 废止 | 出现更准确的角色，或长期没有新增使用方 | 停止新增；下个 major 清理存量并更新基线 |

当前状态：

- **试用**：`Slots`（`WImageSlots` 是唯一使用方）、`Settings`（`WFormValidatorSettings`）、
  `Params`（暂无公开类型）。
- **辅助词**：`Status` / `Snapshot` / `Styles` 不单独占角色行，按 §3.3 的同义规则使用；
  `Failure` 已并入 `Result` / `Failure` / `Error` 行。

试用角色可以直接用于新代码，不需要先转正；转正只决定它是否进入默认推荐、检查清单和检查脚本。

改角色的流程：先改本文 → 更新 §7 的强度 / 清单 → 需要时改 `scripts/check_naming.py` →
更新基线注释 → 在 CHANGELOG 记一笔。角色变化是规则变化，不是「改个名字」。

## 10. 历史

- [ADR-0004](adr/0004-component-config-model.md)：组件配置 = 不可变值对象 + 显式作用域；
  首次约束 `XxxConfig` 不得携带行为。
- [ADR-0005](adr/0005-app-options-and-plugin-ownership.md)：`WLocaleConfig` 作为数据载体出现。
- [ADR-0007](adr/0007-component-naming-roles.md)：把命名从「后缀表」收敛为「先判断角色」，
  并把规则正文移到本文；ADR 不再承载存量名单。
- 2026-11-06：本文修订——角色表补「维度 / 检查 / 典型例子」，补同义择一、review 清单与
  规则演进；`Config` 与 `build()` 的口径收紧，存量改为「基线两类 + 规则内冻结项」。
- 已完成的改名：`WMapConfig` → `WMapOptions`（map_google）、
  `WImageLoadConfig` → `WImageLoadOptions`（ui）；细节见对应 CHANGELOG 与迁移文档。
