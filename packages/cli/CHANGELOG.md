# Changelog

## 1.7.2

### Added
- `.w_tools_doctor.yaml` 的 `ai.figma: auto|true|false`；`init` 自动检测 pubspec 的 `w_tools_figma`，避免不带 `--figma` 时删除 Figma 片段。

### Changed
- `--figma` 片段不再重复 UI / form 组件规则；版本约束收敛到单一常量。
- `init --figma` 优先使用消费方 pubspec 的 `w_tools_figma` 约束；path/git 依赖不生成 pub 版本。

## 1.7.1

### Changed
- `init --figma` 模板升级到 `w_tools_figma ^0.3.0`，补充 frames / spec 深度 / tokens map / diff --if-stale。

## 1.7.0

### Added
- `init --figma` 生成 Figma → Flutter AGENTS 片段；不引入 `w_tools_figma` 依赖、不影响 toolkit。

## 1.6.1

### Changed
- AGENTS UI 片段补充 `lib/app/ui/` 是项目永久 UI 层、不走 STAGED、不计划上移。
- banned 段落增加 R9 只匹配已登记 pattern 的边界说明；英文输出改为英文标题与说明。
- AGENTS base 明确先判断永久 UI 层 / 暂存层；英文 banned 条目使用 use / reason 标签。
- AGENTS closing 自动生成 doctor 规则速查表；CLI 示例改用真实 `Image.asset` 禁用场景；CONTRIBUTING 补充 grep 检查经验。
- DoctorRule 内置中英文 summary，AGENTS 规则表与规则定义单一来源；base 去掉 no-ui 下的具体 UI 组件名。
- base 的 UI 分层说明移回 ui 片段；R3/R4 改用 TextScan，跳过行尾注释。
- doctor 规则表 summary 只描述规则；R6/R9 启用状态改由表头说明，避免 summary 混入项目状态。
- 修正 R9 示例 id 为 `no-raw-image`，文档索引与 AGENTS 维护说明同步为 R1~R9。
- README / conventions 增加无 CLI 时 grep 与 R1/R2/R4/R9 的映射，明确 `--include-tests` 与 R4 的覆盖边界。
- AGENTS base 补充上移候选要求（默认值/测试/CHANGELOG）与 API 参数 ≤ 3 的形状建议。
- base 明确 CHANGELOG 由包维护者在进入 w_tools 时补；文档补充 doctor 文本级/字符串边界说明；补英文模板测试。

## 1.6.0

### Added
- 新增 R9 项目禁用 API：`.w_tools_doctor.yaml` 的 `banned` 支持 literal / regex、paths / ignore、use / reason 与 level。
- 支持 `// w_tools:ignore R9 reason: ...` / `// w_tools:ignore-file R9 reason: ...`，没有 reason 不生效。
- `init` 会把有效 `banned` 生成到 AGENTS；`explain` 会提示当前项目禁用项。
- README 增加 5 分钟上手、命令决策表、升级后重新生成、退出码与 R9/banned 说明；`init` / `doctor` / `list` / `explain` 的 `--help` 补示例。
- R9 预编译 regex / 缓存 glob；banned 文档说明文本级匹配边界。
- AGENTS 模板按 app / form / api / async 能力裁剪；ui README 图片示例改用 `WImage.asset`。
- `context` 区分 pubspec / doctor 配置解析错误，并按项目类型输出 `flutter` / `dart` 命令；`explain` 支持 `--root` 并兜底坏配置。
- 新增 init 单项开关 `--no-form` / `--no-app` / `--no-api`；区分 pubspec.lock 解析错误。
- 抽出 `ProjectFacts`，让 context 与 R5/R7 共用 toolkit / 暂存层 / 依赖事实；新增 `--no-toast`。
- AGENTS 模板拆成 base + feature 片段（ui / form / api / app / async / toast / core / qr / map / closing），去掉 full / no_ui 两套大模板。
- init 能力参数统一为 `--<feature>` / `--no-<feature>`；新增 `--map` / `--no-map`，保留 `--with-map` 兼容别名。
- init 的 feature help 从注册表生成；所有 feature 正反参数冲突统一报错，JSON features 改用 `toJson()`。
- `context --format=json` 增加 `schema` 标识与 v1 JSON Schema；采用新增字段兼容、破坏性变化才 bump 的策略。
- context schema 测试使用 `json_schema` 校验真实 `toJson()` 输出，并用包根定位 schema 文件。
- 内部模型收敛：InitFeatures 改为 Set<InitFeature>，ProjectSnapshot 持有 ProjectFacts，不再复制字段。
- 命令层统一通过 `ProjectFiles.loadConfig` 读取 `.w_tools_doctor.yaml`，减少重复异常处理。
- R6 / R9 共用 `TextScan` 文本扫描，统一跳过整行注释与行号计算。
- R9 预过滤无效 banned 条目，避免每个源文件行重复 validate。
- R6/R9 跳过行尾 `//` 注释；R2 同时检查 `export package:w_tools_*`。

### Changed
- 消费方 AGENTS 模板补充 `WTextVariant` 不够用时的处理顺序：先 `variant + style`，项目内重复抽本地 helper，稳定跨页面语义再提库内 variant。
- 组件目录同步 `WText` 的 variant 边界说明。
- 消费方 AGENTS 模板统一间距入口：`SizedBox` 用 `WSizeBox`，`Padding` 用 `WPadding`，`EdgeInsets` 用 `num.allPadding`；不再推荐 `num.heightBox` / `widthBox` / `squareBox`。

## 1.5.0

- 已发布版本（此前的模板与文档修正；不含 1.6.0 的 R9 / schema / feature registry）。

## 1.4.0

### Changed
- 消费方 AGENTS 模板补充 Form 直接字段、WImage、弹层与轻提示规则；修正不存在的 `WnnToast` 引用。
- 消费方 AGENTS 不再放完整按钮代码，仅保留决策规则；完整模板留在 docs/agents/button.md。
- 组件目录同步 Form 的 `WForm` / 直接字段 / `WFormFieldStyle` 入口，移除旧 App helper 名称。
- 升级 `w_tools_cli` 后，消费方需重新执行 `dart run w_tools_cli:init`（或 `--check-drift`）以更新 AGENTS 片段。
- 修复 `init` 生成的 `w_tools_ui` 约束仍为 `^2.1.0`：同步到 `^3.0.0`，避免新项目解析到旧 UI。
- 消费方 AGENTS 与组件目录补充 `w_tools_api` 的 `DioRegistry` / `WTokenInterceptor` / `WLogInterceptor` 网络规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_app` 的 `WApp.start` / 插件依赖 / `WLanguage` / `WRouteObserver` 启动规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_core` 的 `WStorage.init` / 明文存储 / `WValidator` 与 `WRegExp` 分工规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_qr` 的 `WQrView` / `WQrController` / `restartScan` 扫码规则。
- 消费方 AGENTS 与组件目录补充 `w_tools_map` 的 `WMap` / `WMapZone` / `WMapItemMapper` 地图规则，仅在 `--with-map` 时生成。
- 新增 `example/`：命令演示与基于临时 `demo_project` 的可复现 init / check-drift / doctor / context / list / explain 流程；脚本自动准备依赖并清理临时目录。
- `DoctorConfig.copyWith` 支持覆盖 `colorMinCount` / `ignore`。

## 1.3.0

### Added
- 新增 `w_tools_async` 子包支持：`init --profile=full` 默认导出，
  `--no-async` 可关闭；`toolkit` / pubspec 片段同步。

## 1.2.0

### Added
- `init` 生成 `lib/app/ui/app_bars.dart`、`app_boxes.dart`、`app_buttons.dart`、
  `app_card.dart` 与 `app_scaffold.dart`：标准页面默认使用 `AppScaffold`，
  AppBar / 盒子 / 按钮样式统一走 `AppBars.style` / `AppBoxes` / `AppButtons`，
  重复卡片用 `AppCard`。`lib/app/design_system/` 只保留待上移组件。
  `AppBoxes.card` / `warning` 跟随主题；`AppCard` 默认使用 `AppBoxes.card(context)`，
  支持 `clipBehavior`。
- AGENTS / 暂存层规范补充：真按钮用 `WButton`，任意 child/卡片点击用 `WPressable`。
- toolkit 导出 AppScaffold/AppBars/AppButtons；AGENTS / `lib/app/ui/README.md`
  增加页面与按钮规范。
- 固定 `lib/app/ui/` 与 `lib/app/design_system/`：R2/R4/R5 与 init 使用同一套路径。
- `init --no-ui`：不生成 `lib/app/ui/` 与 `design_system/`，不导出 `w_tools_ui`，AGENTS 不写 UI 规则。
- `init --profile=minimal|ui|api|full`：按能力组合生成 toolkit 与依赖片段。
- `init --no-instructions`：不生成/不检查 AGENTS 等 AI 指令文件，优先于 `--targets`。
- help 明确 UI 生成条件；text 输出 profile / features / targets；R8 文档说明跳过 UI starter。
- `init` 报告 profile / targets 切换后遗留的 UI 与指令文件（`stale`），但不会自动删除。
- R5 / context 只统计 `.dart` 暂存文件，不再把 `design_system/README.md` 算作缺 `// STAGED`。
- R4 同时检查 `lib/app/ui/` 与 `design_system/`，项目 UI 也不得依赖业务层；R3 对这两层豁免硬编码色。
- `lib/app/ui/` 下的 App* 与 README 视为 starter：自定义后不算 drift，也不会被
  `init` / `--check-drift` 覆盖。
- 新增 `tool/check_templates_compile.dart`，CI 用 Flutter analyze 编译检查生成的 UI starter。
- 迁移：旧版生成的 `design_system/app_*.dart` 移到 `lib/app/ui/`；
  toolkit 的 export 改为 `../ui/...`。

## 1.1.1

### Changed
- `init` 生成的 pubspec 片段把 `w_tools_ui` 约束更新到 `^2.0.0`
  （配合 `w_tools_ui 1.2.0` 的 `String.toImage` 增强）。

## 1.1.0

### Added
- `dart run w_tools_cli:context`：输出项目事实（已装版本、toolkit 导出、暂存层、
  规则、当前检查结果），支持 `--format=json|markdown|prompt` 与 `--max-tokens`。
- `dart run w_tools_cli:list` / `:explain`：内置组件目录查询（来源
  `catalog/components.yaml`，生成 `catalog.g.dart`），避免凭记忆造组件名。
- `init --json`：机器可读的初始化结果。
- `init --targets=agents,claude,cursor,copilot`：同一份指令写到多个 agent 文件；
  `cursor` 新文件带 frontmatter。`--lang=zh|en` 生成中英文指令；
  `.w_tools_doctor.yaml` 的 `ai.targets` / `ai.language` 可作为默认值。
- 生成物头部带 `generated by w_tools_cli x.y.z`，`doctor` 的 R8 检查是否过期。
- `doctor` 新增 R7（toolkit 与 pubspec 依赖一致）、R8（生成物版本）。
- `doctor --format=markdown`：可直接粘给 AI / PR 评论的摘要。
- `doctor --json` 的 issue 增加结构化 `fix`（`run` / `edit`），AI 可直接执行；
  没有 `fix` 时继续用 `hint`。

### Changed
- `init` 的 AGENTS/CLAUDE 片段升级为 AI 工作流（context → list/explain → doctor）。
- 5 个入口共用 CLI runner，`--version` / `--help` 行为一致；
  `list` / `explain` 支持 `--format=json`。
- 规则注册表统一到 `doctorRules`，新增规则只改一处；规则间共享文件读取缓存。
- `R7` 不再重复报告聚合包 `w_tools`（由 R1 负责）。

### Fixed
- 生成的指令会代入真实项目名（不再留下 `<app>` 占位符）。
- R8 不再把用户手写的 `CLAUDE.md` / copilot 文件当成生成物误报。
- `init` 的 pubspec 片段在已有 `dependencies` / `dev_dependencies` 时只追加缩进行，
  避免复制出重复的顶层 key。

## 1.0.0

首次发布：`init` / `doctor`（R1~R6）、模板生成与 `.w_tools_doctor.yaml`。
