## 1.9.13

### 新增
- `feedback submit` 默认策略：本地 `docs/feedback/` 存在 → 直接写台账；否则
  `.w_tools_doctor.yaml` 的 `feedback.issue: true` → 建 Issue；都不满足 → 跳过（exit 0）。
- `feedback submit --ledger`：仅 w_tools 仓库检出可用，直接追加 `docs/feedback/<包>.md`，
  自动创建缺失包的台账并更新索引待处理数量。
- `feedback submit --issue`：显式创建 Issue（覆盖配置）；`--gh` 保留为别名。
- `.w_tools_doctor.yaml` 新增 `feedback.issue`（默认 false）；生成 AGENTS 改为“默认关闭”。

## 1.9.12

### 新增
- `feedback submit`：校验必填字段，默认生成 GitHub 预填 issue 链接（不上传）；
  `--gh` 直接建 issue，`--local` 离线写收件箱，`--json` 机器可读。
- `feedback search`：本地台账/收件箱查重；`--gh` 同时搜 GitHub issues。
- `templates/agents` 的使用反馈改为 `search → submit` 闭环，收尾必查。
- 新增 `.github/ISSUE_TEMPLATE/feedback.md`；`docs/agents/cli.md` / feedback 台账说明同步。

## 1.9.11

### 改进
- `init` 生成的子包约束同步本轮大版本：core ^3.0、ui ^5.0、form ^4.0、api ^5.0、
  app ^2.0、map ^2.0、toast ^2.0、async ^3.0；新增 `--reset`。
- `init` 始终沿用 `.w_tools/init.json` 的 profile/targets/lang，`--force` 不再静默重置；
  收尾按状态给 next actions，不再无条件 `doctor`。
- `init --json` 带 schema/schemaVersion/needsPubspec/nextActions，文件条目改为 `{path, note}`。
- `doctor` 的 `rules:` 开关对 R1–R5/R7/R8 真正生效；R7 fix 使用真实版本约束；
  `--write-config` 冲突退出码改为 2。
- `list` 无匹配退出码改为 1；`feedback` 缺子命令给出用法并退出 2；统一 `--format` / `--json`。
- `context --json`；doctor issue 带 `fix`；prompt 只列 w_tools/直接依赖并按优先级截断。
- 文本扫描统一去掉块注释 / raw string；`ignore` 支持 `**`；R3 识别 8 位 alpha 颜色。
- `feedback lint` 校验已修复版本号 / 不修理由。
- 组件目录：`WRoute` 条目改为 `WRouteStack`，移除已删除的 UI 组件引用。
- 新增 `docs/agents/cli.md`。

## 1.9.9

### 新增
- `.w_tools/init.json` 记录 `generator`（写这份 manifest 的 CLI 版本）；老文件没有该字段也能读。
- `validatePackageName` / `inboxFile` 提出为可测函数，补 bin 层入参校验测试
  （`../evil` / 大小写 / 空值；收件箱路径固定）。

## 1.9.8

### 改进
- `context.commands` 新增 `feedback` / `feedbackLint`：AI 走「先拿事实」时也能发现反馈入口
- `schema/context.v1.json` 补 `install` 属性（此前 additionalProperties 让它不报错但契约缺失）
- `scripts/check_feedback.sh`：缺 `.dart_tool/package_config.json` 时 **exit 2**（原来 exit 0 静默跳过，
  等于 CI 假绿）；提示先跑 `dart pub get`

### 发布
- 首次打 tag `v1.9.8`；消费方可用 `ref: v1.9.8` 代替 40 位 sha

## 1.9.7

### 改进
- `feedback lint`：`已确认` 条目必须链 issue（`#123` 或链接），否则报错
- `packages/cli/README.md` 新增 `feedback` 命令说明（命令怎么选表 + 子命令表）

## 1.9.6

### 修复
- `feedback lint --include-inbox`：仓库检出时**不再跳过**本项目收件箱（此前该参数实际无效）
- `feedback path --package=`：校验包名（`^[a-z0-9_]+$`），防 `../` 穿越
- `lintLibrary`：索引里列了不存在的文件、或有文件没进索引，都会报错

### 改进
- `lint` 新增 `--stale-days=<n>`（默认 30，0 关闭）：待处理超期给警告（不影响退出码）
- 字段检查改为按行首 `- 字段：` 匹配（允许「命令 / 输入」「影响（…）」这类后缀），
  不再因为正文里出现关键词就过关
- 索引正则允许数字（`e2e` 这类包名此前被误判「没进索引」）
- `scripts/check_feedback.sh` 退化为薄包装：规则只在 Dart lint 里实现一次（避免两套规则漂移）

## 1.9.5

### 新增
- `w_tools_cli:feedback path [--package=<包>]`：输出反馈该写到哪个文件
  （库侧 `<repo>/docs/feedback/<包>.md`，或本项目收件箱 `docs/agents/feedback.md`）。
- `w_tools_cli:feedback lint [--include-inbox]`：校验字段齐全、状态合法、已闭环带版本号、
  索引数量一致；AI 写完反馈可自检。
- AGENTS 模板改用 `feedback path` 取路径；「完成前」加一条 lint 自检。

## 1.9.4

### 新增
- `context --format=json` 新增 `install` 段：`packageRoot` / `repoRoot` / `isRepoCheckout` /
  `feedbackDir`。AI 据此判断「库侧 docs/feedback/ 在不在本机」，不用猜路径。
- AGENTS 的「使用反馈」一节改为先跑上面这条命令取 `feedbackDir`；为空就只写本地收件箱。

## 1.9.3

### 改进
- AGENTS 的「完成前」清单新增一条：本次用过 `w_tools_*` 且有卡点 → 写一条到
  `docs/agents/feedback.md`。把「记反馈」变成收尾动作，比单独一节更容易被执行。

## 1.9.2

### 新增
- `init` 生成的 AGENTS 里新增「使用反馈（给 AI）」一节：任何新项目装完 w_tools 就有
  「遇到问题 → 写 `docs/agents/feedback.md` 收件箱 → 维护者同步到 `docs/feedback/<包>.md`」的指引，
  不用每个项目手抄一遍。

## 1.9.1

### 改进
- `init --device` 生成的镜像示例改名为 `tool/gradle-mirror.init.gradle.example`：
  它是「复制到 `~/.gradle/init.gradle` 才生效」的示例，原名容易被误认为已自动生效。
  文档里的旧路径 `docs/templates/…` 一并修正。

## 1.9.0

### Changed（破坏性：路径）
- `init` 的 manifest 从 `.w_tools_init.json` 迁到 **`.w_tools/init.json`**（工具元数据收敛到 `.w_tools/`）。
  老项目首次 `init` 会自动迁移旧文件并提示。
- 其它生成物不变：`lib/app/w/toolkit.dart`、`lib/app/ui/*`、`AGENTS.md`、`.w_tools_doctor.yaml`
  仍在约定路径（它们必须可被 Dart / agent / Flutter 直接发现）。

# Changelog

## 1.9.10

### Fixed
- `init` 与 doctor 共用 `ProjectLayout`（唯一路径来源）；`init` 现在会读 `.w_tools_doctor.yaml` 的 `toolkit_entry`，不再与 doctor 的检查路径分叉。
- `init --check` 只把用户可见生成物算作缺失：内部 `.w_tools/init.json` 与可选的 `.w_tools_doctor.yaml` 不再让 CI 假红；`--check` 也不再写 manifest，`--check-drift` 不会因 CLI 升级而永久失败。
- `doctor --write-config --force` 覆盖前写 `.bak`（此前会静默抹掉项目维护的 palette / banned / ignore）。
- `feedback lint --stale-days=0` 真正关闭 stale 检查；非法值 exit 2 而不是静默回退 30。
- R2 在 `test/` / `tool/` / `integration_test/` 放行 `w_tools_{cli,figma,device,e2e}`：`tool/main_e2e.dart` 按文档必须直接 import `w_tools_e2e`；`lib/` 仍报错。`--include-tests` 一并扫描 `integration_test/`。

### Changed
- `catalog/components.yaml` 成为唯一来源：`gen_catalog` 同时生成 `catalog.g.dart` 与 `docs/modules/components.md` 的 §1~§9 表格；`catalog_test` 校验表格新鲜度与**每个别名**可被 `explain` 找到（补上 `WStepFlow`）。
- 子包约束表同步 `ui 3.1.0` / `form 2.1.0` / `api 1.0.2` / `map 1.3.0`。

## 1.8.1

### Changed
- device/E2E AI 入口明确：`w_tools_e2e` 只放 `tool/main_e2e.dart`，生产 `main.dart` 不 import。
- `.w_tools_init.json` 在普通 init 时始终更新（不受 --force 限制）；--check 只比对。
- 旧版无 marker toolkit 首次 --force 迁移时，自动把模板外的 export 追加到 `w_tools:end` 之后，并保留 `.bak`。

## 1.8.0

### 新增
- `init --device`：生成设备验证脚手架（`integration_test/app_smoke_test.dart`、`tool/device_smoke.dart`、`docs/agents/device-testing.md`、`tool/gradle-mirror.init.gradle`）。
- `init --force-starters`（`--force-ui` 别名）：显式覆盖 UI / device starter，覆盖前写 `.bak`。

### 修复
- `init --force` 不再覆盖 UI / device starter；只刷新生成物与配置。
- `init --force` 覆盖 `.w_tools_doctor.yaml` 前先备份 `.bak`。
- doctor R2 / ProjectFacts 的包名正则支持数字（如 `w_tools_e2e`）。
- doctor 的 `// w_tools:ignore` / `ignore-file` 支持 R2~R9；R3 只在未被忽略的命中上计阈值，R1 暂不支持。

### Changed
- 设备 starter 的 `--force` 语义改为 `--force-starters`。
- `toolkit.dart` 使用 `w_tools:begin/end` 标记块；`--force` 只更新块内，保留项目追加项。
- 新增 `.w_tools_init.json` 记录 init flags；`--check` 默认回放上次参数，避免参数不同导致假 drift。

## 1.7.5

### Changed
- `--figma` 模板补充 frames 过滤、多画板 spec、node-only 和自动缓存选择说明。

## 1.7.4

### Changed
- 没有 `w_tools_figma` 依赖时，模板生成 `dart pub add dev:w_tools_figma`，不再写死兜底版本。

## 1.7.3

### Changed
- `figmaConstraint` 默认值更新为 `^0.4.0`。

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
