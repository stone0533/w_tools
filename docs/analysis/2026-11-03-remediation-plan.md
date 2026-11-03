# w_tools 修复路线图（2026-11-03）

> 配套：[全仓代码评审](2026-11-03-codebase-review.md)（问题地图 + 证据）。
> 本文只回答一件事：**按什么顺序修、每步怎么验收、什么时候必须停。**
> 基线 `main @ 38d54b0`，14 个包全部已发布，工作区干净。

## 进度

阶段 0 / 1：

| 步 | 状态 | 落点 |
| --- | --- | --- |
| 0.1 CI 补齐 async / figma / device / e2e | 完成 | `.github/workflows/ci.yml`：`matrix.include` + `kind` |
| 0.2 首次基线 | 完成 | 本地全绿：ui 358、form 285、api 45、map 34、async 110、e2e 14、cli 205、figma 83、device 58；期间清掉了 Flutter 升级后残留的 `build/unit_test_assets` 旧 shader |
| 0.3 弃用到期守护 | 完成 | `scripts/check_deprecations.py` + 3 处 `remove-in` |
| 0.4 文档版本守护 | 完成 | `scripts/check_docs_versions.py` + 修掉 6 处漂移 |
| 1.1 表单校验错误默认可见 | 完成 | 先做契约修复（只传 borderConfig 时默认 `showBorderError`），4.0d 再把默认 `borderConfig` 切到 `fromTheme`，P1-5 完整关闭 |
| 1.2 WAppBar 默认图标 / 标题 | 完成 | `IconTheme.merge` + `AppBarTheme.titleTextStyle → titleLarge` 回退；3 个回归用例（红→绿） |
| 1.3 WImage 预设改为合并 | 完成 | `WImageStyle.merge`；`avatar`/`thumbnail`/`cover` 不再丢尺寸与圆角；8 个用例 |
| 1.4 form 所有权 | 完成 | `didChange` 卸载保护（有红→绿用例）、多选弹层 mounted 保护、重名字段可读报错 + `removeBorderKey(owner:)` |
| 1.5 401 竞态 | 完成 | 晚到 401 直接用新 token 重试，不清不刷；并发用例（修复前 `[200,-1]`） |
| 1.6 map 入口 | 完成 | `initialCamera` / `isValid`、缺失坐标跳过、非 `WMapItem` 可读 `ArgumentError` |
| 1.7 WButton 默认跟随主题 | 未做 | 属于品牌视觉变更，按评审建议放到 ui 4.0（3.4）一起做 |
| 1.8 WRowButtons 文档降级 | 完成 | `components.md` / `agents/button.md` 改成「分段选择」，纯动作行用 `Row + WButton` |
| 子包版本 / CHANGELOG | 完成 | ui 3.2.0、form 2.1.0、api 1.0.2、map 1.3.0；`release_check` 剩 4 条预期提醒（根约束下界低于本地版本） |
| D1 落地（ui 3.2.0） | 完成 | `WTextStyles.toTextTheme()` / `ThemeData.withWTextStyles()`；11 角色 ↔ 11 槽位严格互逆，兜底按 `TextTheme` 缓存；form/toast 的 Theme 派生留给 4.0 |
| 根包约束 / 根版本 | 待发布 | **不能提前抬高**：根 `example/` 依赖 `w_tools` path → 未发布的 `^3.1.0` 会让本地解析失败；按 `docs/releasing.md` 在子包发布后再抬 |

阶段 2（工具链，与 Flutter 包零重叠）：

| 步 | 状态 | 落点 |
| --- | --- | --- |
| 2.2 `doctor --write-config --force` 备份 | 完成 | 覆盖前写 `.bak` 并提示；有进程级用例 |
| 2.3 R2 放行 dev-only 工具包 | 完成 | `test/` `tool/` `integration_test/` 放行 `w_tools_{cli,figma,device,e2e}`；`lib/` 仍报错 |
| 2.4 `--stale-days=0` 真正关闭 | 完成 | 规则改为 `staleDays > 0` 才检查；非法值 exit 2（不再静默回退 30） |
| 2.6 figma Windows 路径 | 完成 | `nodes-*.json` 识别改为归一化分隔符；补 POSIX / Windows 用例 |
| 2.8 device 标定 freshness | 完成 | 先取截图尺寸再判缓存，尺寸 / 方向 / `--scale` 变化都会失效；补 4 个 store 用例 |
| 2.9 device 进程超时 | 完成 | `ProcessShell(timeout: 120s)`，`run` / `runBytes` 超时抛 `ProcessException`；`Uint8List.fromList` 去掉不安全 cast |
| 2.1 init/doctor 路径单一来源 + `--check` 契约 | 完成 | 新增 `ProjectLayout`；init 读 `toolkit_entry`；`--check` 不再把内部 manifest / 可选配置当缺失，也不因 CLI 升级假红 |
| 2.5 catalog 单一真相 | 完成 | `gen_catalog` 同时生成 docs §1~§9 表格；YAML 吸收文档文案；`catalog_test` 校验表格新鲜度 + **每个别名**都能 explain（补上 WStepFlow） |
| 2.7 figma BudgetGuard | 完成 | `fetch` / `diff` 请求前检查本月额度；用尽默认拒绝（退出码 3），`--ignore-budget` 放行；缓存命中与 spec/tokens 不受影响 |
| 工具包版本 / CHANGELOG | 完成 | cli 1.9.10 / figma 0.11.0 / device 0.1.2，CHANGELOG 已写；`release_check` 只剩 4 条 Flutter 子包的预期提醒 |

阶段 4（进行中，D1 = 不引入 ui）：

| 步 | 状态 | 落点 |
| --- | --- | --- |
| 4.0a form 主题派生 | 完成 | `WFormBorderConfig.fromTheme(ThemeData)`：边框/背景/聚焦/错误/只读取 `ColorScheme`，hint/error 取 `bodySmall`；`standard()` 标注为显式浅色预设 |
| 4.0b toast 主题派生 | 完成 | 文本气泡 `inverseSurface` + `onInverseSurface`，默认内容取 `textTheme.bodyMedium`；`backgroundColor` 默认改 `null`；文本提示改 `showCustomText` 以便在 Overlay 里取 Theme |
| 4.0c 字面量守卫 | 完成 | `scripts/check_style_literals.py` 扫 form/toast/async，CI umbrella job 已接入；历史预设行内标 `style-literal-ok` |
| 4.0d `WForm` 默认 `borderConfig` 切到 `fromTheme` | 完成 | form 3.0.0：默认主题边框 + `showBorderError`；显式 `const WFormBorderConfig()` 关闭外观；`WFormTheme` 优先级改为显式 > 祖先；`WFormBorderConfig`/`Decoration` 补 `==` 并删除快照缓存；根约束 `^3.0.0`、根 example 加 dependency_overrides |
| 4.1 async 执行核收敛（2.0.0） | 完成 | `WAsyncConfig`→`WAsyncOptions`（纯数据，删 7 个转发）、新增 `WAsyncLoading` 显式合并、方法改名 `retry/timeout/parallel/pool/first/serial`、删除 `WAsyncBuilder`；控制器接 `options` 并取消上次 token |
| 4.2 async 视图/defaults 合并 | 完成（2.1.0） | 新增 `WAsyncTheme`（普通 + `sliver*Builder`）；旧两个 defaults 弃用、仍识别（优先级更低），3.0 移除 |
| 4.4 form 删 Config 公开层 | 进行中（第一批） | 图标收成 `WFormIcons`（3.1.0，完成）； 已弃用 `WFormBorderConfig.builder()` / `WFormBorderConfigBuilder` / `Row.withFormBorder`（4.0 删除）；修掉 `bordered:false` 时 text field 不下发只读作用域、`message` 被静默丢弃。删 7 个 `build()` 与 `*Core` 公开面（需把实现移出 Config，属 4.0 破坏性步骤） |

## 0. 三条排序原则

评审列了 13 个运行时 P1 + 9 个工具 P1 + 30 多条 P2。**按严重度排序是错的**，按下面三条排：

1. **先建验证网，再动代码。** `async` 和 3 个工具包没有 CI（评审 P1-10）；在这之前动 async 等于盲改。
   验证网的优先级高于任何 P1。
2. **先止血，后结构。** 「会崩 / 静默失败 / 默认值错」用补丁版本就能修，不需要大版本；
   结构性重构（删 Config 层、删布局糖）必须走大版本 + 弃用期，不能混在一起做。
3. **按依赖层分批，不按包分批。** `core → ui → form/async/toast` 是有向链；
   先改 ui 的样式/默认值，再让上层依赖它，能避免同一处改两遍。

一条硬规则：**每个大版本改动都要两段式**——先 `@Deprecated` 一个版本 + 迁移表，再删除。
评审已经看到反例：`WConfig.assetImagePath` 注释写"下个大版本移除"，跨过 3.0 还在。
所以阶段 0 要先加一个"弃用到期"守护，否则新加的弃用会重蹈覆辙。

## 1. 先做 5 个决策（不做决策就会返工）

| # | 决策 | 我的建议 | 影响 |
| --- | --- | --- | --- |
| **D1** | form / toast / async 是否允许依赖 ui？ | **已定：不依赖**，见 [ADR-0003](../adr/0003-subpackage-typography-without-ui.md)。排版通过 `ThemeData.textTheme` 共享，ui 提供 `WTextStyles.toTextTheme` + `ThemeData.withWTextStyles`；三包只读 Theme，`pubspec` 不变 | 避免把 50 个传递依赖 / 10 个原生插件拖进 async / form / toast，也不绑死发布顺序；代价是三包默认样式必须从 `ColorScheme` / `TextTheme` 派生并禁止字面量色值 |
| **D2** | 断代方式 | **两段式**：2.x/3.x 先弃用 + 迁移文档，下一大版本删 | 一次性破窗只适合 0.x 内部项目；这里是 pub 上的库 |
| **D3** | form 是否继续基于 `flutter_form_builder` | **继续用，但真封装**：barrel 显式 re-export FFB 类型，README 声明它是公开依赖 | 换掉 FFB 等于重写 form（约 5,000 行）；真暴露是 1 小时的事 |
| **D4** | cli 是否合并成单入口 | **合并**（`w_tools <subcommand>`），旧 6 个 bin 留一版薄壳 | 决定 `--check` 契约重定与退出码统一的时间点 |
| **D5** | `WRowButtons` 怎么处理 | **先改文档撤下推荐**（1.8），拆分类放进 ui 4.0（3.7） | 避免一边修模型一边被文档继续推荐 |

D1 必须在阶段 3 之前定，D3 在 4.6 之前定，D4 在 2.1 之前定。其余可以边走边定。

## 2. 阶段 0：验证网（1–2 人日）

| 步 | 动作 | 关键点 | 验收 | 大小 |
| --- | --- | --- | --- | --- |
| **0.1** | CI 矩阵补齐 `async` / `figma` / `device` / `e2e` | 现在靠 `if: matrix.package != 'cli'` 区分 Flutter/Dart，**加包会串**。改成 `matrix.include` 带 `kind: flutter\|dart`，用 `matrix.kind` 驱动 analyze/test/publish 三条命令 | 只改 `ci.yml` 的 PR，13 个包（+ cli）全绿 | M |
| **0.2** | 本地先跑一遍这 4 个包的测试 | 从未在 CI 跑过，**很可能第一次就红**。红了先修测试，别急着动实现 | 4 包 `test` 全绿并写入 CI | M |
| **0.3** | 加"弃用到期"守护 | 约定注释 `// remove-in: 4.0.0`；`release_check.sh` 在包版本 ≥ remove-in 时 fail | 守护能挡住 `WConfig.assetImagePath` 这类陈年弃用 | S |
| **0.4** | `check_docs.sh` 增加"禁止 prose 版本号" | 现在 `docs/agents/figma.md` 写 0.9.2（实际 0.10.0）、README 写 `^1.x`（实际 ^2/^3） | 规则能报出已知的 5 处漂移 | S |

> 0.1 是**唯一的前置**。0.2–0.4 可与阶段 1 并行。
> 这一步不改任何库代码，风险为零；但它决定了后面每一步能不能被证明"没变坏"。

## 3. 阶段 1：止血（4–6 人日，全部补丁版本）

目标：让"默认用法"不再骗人。全部是兼容改动，可以随 3.0.x / 2.0.x 发。

| 步 | 关闭 | 动作 | 必带测试 | 大小 |
| --- | --- | --- | --- | --- |
| **1.1** | P1-5 | `WFormBorder` 在 `hintBuilder/errorBuilder == null` 时兜底 `Text(list.join('；'))`；`showBorderError` 默认 `true`。**先不动 `WForm.borderConfig` 默认值**——兜底文案 + 不换装饰，视觉零变化 | 默认 `WForm` + `message` + `validate()` → `find.text('请输入邮箱')` | M |
| **1.2** | P1-1 | `IconTheme.merge`；标题回退 `appBarTheme.titleTextStyle ?? textTheme.titleLarge` | golden：默认 `WAppBar` + `BackButton` | M |
| **1.3** | P1-3 | `WImage.avatar` 用 `avatar(size).merge(style)`（没有 `merge` 就先加，按非空字段覆盖） | 传 `style: const WImageStyle(fit: BoxFit.cover)` 后仍是 40×40 + 圆角 | S |
| **1.4** | P1-6 | 三处所有权：`safeDidChange`（判 `mounted`）、`WFormPopup.show` 返回 handle 并在字段 `dispose` 关闭、重名 `ArgumentError` | 三个用例，各能独立红→绿 | M–L |
| **1.5** | P1-8 | **先写红用例**（两条请求并发 401、刷新已完成），再改：只在刷新失败/放弃时清 token；清之前比对 `tokenGetter()` 与本次请求用的 token | 并发 401 后 `getToken()` 仍是新 token | M |
| **1.6** | P1-13 | 默认 mapper 抛可读 `ArgumentError`；`WMapZone` 加 `initialCamera`；null 经纬度跳过 + debug 日志 | 非 `WMapItem` 模型报错信息含类型名与修法 | M |
| **1.7** | P1-2 | `WButtonStyles.of(context)` 从 `colorScheme` 派生；`WButtonStyles.primary` 保留为显式预设 | golden：`colorScheme.primary` 换色后按钮跟色 | M |
| **1.8** | P1-4 | 文档撤下 `WRowButtons` 的"一行多个按钮"推荐，改成"分段选择" | `check_docs` 通过 | S |

**阶段 1 的顺序有讲究**：1.1 用户感知最强（表单错误看不见）且改动最小，先做；
1.2/1.3 是"加个参数就坏"的陷阱，排在后面但都要 golden；
1.5 必须测试先行，它是唯一有并发不确定性的；
1.7 是**视觉变更**（默认色随主题），放最后并单独发一版 + CHANGELOG 明示。

## 4. 阶段 2：工具链契约（6–9 人日，可与阶段 3 并行）

工具链和 Flutter 包没有任何代码重叠，**可以两个人同时推进**。

| 步 | 关闭 | 动作 | 验收 | 大小 |
| --- | --- | --- | --- | --- |
| **2.1** | P1-T1、P1-T2 | 定 `check` 契约：只检查"用户可见生成物"，`.w_tools_doctor.yaml` / `.w_tools/init.json` 不参与 `missing`；路径收敛到 `ProjectLayout`，init 从它取 | 没有 yaml、没有 manifest 的项目 `init --check` 退出 0；自定义 `toolkit_entry` 后 init/doctor 一致 | M |
| **2.2** | P1-T3 | `doctor --write-config` 复用带时间戳的 `backup()`；或只允许写不存在的文件 | `--force` 后 `.bak` 存在且内容等于原文件 | S |
| **2.3** | P1-T8 | R2 对 `test/ tool/ integration_test/` 白名单 dev 工具包（`w_tools_device/e2e/figma/cli`） | `--include-tests` + `tool/main_e2e.dart` 不报 R2 | S |
| **2.4** | P1-T9 | `staleDays <= 0` 跳过；`--stale-days` 严格解析 | `--stale-days=0` 无警告；`abc` exit 2 | S |
| **2.5** | P1-T7 | catalog 单一真相：YAML 加 `aliases`；`gen_catalog.dart` 同时生成 `catalog.g.dart` **和** `components.md` 的表格（用 `<!-- CATALOG:START/END -->` 标记）；测试做全别名比对 | `explain WStepFlow` 成功；docs 表格改一处即红 | L |
| **2.6** | P1-T5 | figma 路径统一 `package:path` 的 `p.basename` | 用 Windows 风格字符串的单测通过 | S |
| **2.7** | P1-T4 | `BudgetGuard.check()` 前置到 fetch/diff：≥80% 警告、≥100% 拒绝（`--ignore-budget` 放行；缓存命中/spec/tokens 不触发） | 设 limit=1 后第二次 fetch 被拒 | M |
| **2.8** | P1-T6 | 标定 freshness key 加 `deviceWidth/deviceHeight/orientation`；CLI 先取尺寸再判缓存 | 旋转/换窗口后强制重标定；`_calibrate` 有用例 | M |
| **2.9** | P2-T14 | device 子进程统一超时（默认 30s，可配）；`adb` 文本转义 `%&;`；`runBytes` 用 `Uint8List.fromList` | 假 `adb` 挂起时命令按时失败 | M |

**2.5 是本阶段唯一的大件**，但收益也最大：它把"三份真相"变成"一份源 + 两个生成物"，
之后每次加组件都不会再漂移。建议 2.5 单独一个 PR，其余按包拆。

## 5. 阶段 3：基座重构 core + ui（8–12 人日，大版本）

先落两个 ADR（各 S）：
**ADR-0004 组件配置模型**（不可变 + `copyWith` + 后缀 `Style`/`Options` + 布尔改 enum）。
依赖方向已由 [ADR-0003](../adr/0003-subpackage-typography-without-ui.md) 定案（不引入 ui），无需再写。

然后按"弃用 → 删除"两段走。**先只加弃用与迁移表（一个小版本），下一版再删**：

| 步 | 关闭 | 动作 | 弃用期产物 | 大小 |
| --- | --- | --- | --- | --- |
| **3.1** | P2-8 | core：`WConfig` 三个键名并入 `WToken`，删 `assetImagePath` | 迁移表 | M |
| **3.2** | P2-1/2/3 | core：`WValidator` 全部改用 `WRegExp`；删 `WRegExpPattern/Preset`、`escapeSql`、`stripHtml`、`hashPassword` | 迁移表（含"服务端做密码哈希"的理由） | M |
| **3.3** | P2-4/5/6/7 | core：`WStorage` 读写语义统一；`WUx` 拆 `WDebounce/WThrottle` 并把滚动移 ui；`WCountdown` → `ValueListenable`；`WPlatform` 收窄 | L | L |
| **3.4** | P1-2/P1-9 | ui：按钮 10 文件收敛为 `WButton` + `WButtonStyle` + `WButtonStyles.of(context)`；默认完全跟随主题 | `WButtonStyle.withoutX()` 迁移到 `copyWith` | L |
| **3.5** | P2-25/26、P1-9 | ui：图片 31 个公开类型 → 约 8 个（`WImage` + `WImageStyle` + `WImageLoadConfig` + `WImageSource` + 错误基类）；12 个命名构造 → 4 个 | 旧构造 `@Deprecated` 一版 | L |
| **3.6** | P2-21/22 | ui：删布局糖 4 类；5 个必填 Config 改可选；`HexColor`→`WHexColor`；两个 String 扩展合并 | 迁移表（`WRow`→`Row`、`WSizeBox.height(8)`→`8.verticalSpace`） | M |
| **3.7** | P1-4、P2-19/20/23/24 | ui：`WRowButtons` 拆 `WActionRow` + `WSelectableRow`；`WScreen` 改读树内 `MediaQuery`；`WTextStyles` 缓存；`WImageFrame` padding 语义修正 | — | M |

> 阶段 3 完成后单独发 `core 3.0` + `ui 4.0`，并在阶段 4 之前让上层先"改依赖、不改代码"，
> 这样上层重构时 ui 已经是稳定的。

## 6. 阶段 4：上层 async / toast / form（10–14 人日，大版本）

D1 已定为「不依赖 ui」。顺序是 **4.0 去硬编码/改读 Theme → 4.1/4.2/4.3 各自收敛**；
`ui 3.2.0` 的 `withWTextStyles` 已完成，应用侧装一次即可让三包跟随品牌排版。

| 步 | 关闭 | 动作 | 大小 |
| --- | --- | --- | --- |
| **4.0** | P1-9 | 三个包**不加** `w_tools_ui`：删除默认样式里的 `Color(0x…)` / `Colors.white`，改从 `ColorScheme` 派生；文字改读 `Theme.textTheme`；保留各自 `xxxTheme` 注入点 | M |
| **4.1** | P2-15 | async：删 `WAsyncConfig`（7 个方法转发 ~300 行），回调作为 `WAsync.run` 参数；`WAsyncController` 接收同一组回调；`wait/any/sequence/...` 改名 `parallel/first/serial/pool` | L |
| **4.2** | P2-16/17/18 | async：三个视图统一收 `ValueListenable`；`onRetry` 统一类型；两套 defaults 合一个；`WAsyncStrings` | M |
| **4.3** | P1-12、P2-40/41 | ~~toast 门面/样式拆分~~ **完成（1.2.0）**：`WToast` 静态门面 + `WToastStyle`（不可变，`copyWith` 可清空）；`WToastConfig` 弃用保留一版；`showLoading` 用 `style.align`。剩余：~~`WToastTheme` / `runWithLoading`~~ 已完成（1.3.0）；评估去 `bot_toast` | L |
| **4.4** | P2-27、P2-29/37/38 | form：删 7 个 Config 的 `build()` 公开面与 `*Core`；7 份 bordered 分支随之消失；删 `WFormBorderConfigBuilder`/`withFormBorder`/`WFormBorderLayout`/`WFormFieldCleanup` | L |
| **4.5** | P2-28/30/31/32/33 | form：图标三合一（`WFormIcons`）；`WFormBorderConfig` 加 `==` 并删 snapshot 缓存；嵌套 `borderConfig` 优先级修正；日期下划线；`lastDate` 计算时机 | L |
| **4.6** | P1-7 | ~~form：按 D3 落地~~ **完成**：barrel 显式 `export … show FormBuilderField, FormBuilderFieldState, FormBuilderFields, FormBuilderState`；README 声明公开依赖；`ffb_export_test.dart` 契约测试 | L |
| **4.7** | P1-5、P2-34/35/36 | form：默认 `borderConfig` 换主题派生版本（替换阶段 1 的兜底方案）；`formEntered` 改 `ChangeNotifier`；`autovalidate` 单通道 | M |

> 4.4 是 form 最大的单步，但它让 P2-27 那一整类"两层行为分歧"从根上消失。
> 建议 4.4 在前、4.5/4.6 在后，因为 4.5 的图标收敛依赖 4.4 删掉 Config 层。

## 7. 阶段 5：api / app / map / qr（8–10 人日，大版本）

| 步 | 关闭 | 动作 | 大小 |
| --- | --- | --- | --- |
| **5.1** | P2-9/10/11 | api：删 5 个装饰性类型；`WLogInterceptor` 7 bool → level/parts 且默认走 `WLogger`；`DioRegistry` 命中但配置不同要报错；401 重试复用发起请求的 Dio | L |
| **5.2** | P1-11、P2-12/13/14 | app：`WApp` 单配置面（字段或 `WAppOptions`）；`WLocaleConfig`；`WBottomSheet` 透传；`WRoute` 去全局静态 | L |
| **5.3** | P1-9、P7.3 | app：4 个一等公民插件 `WToastPlugin` / `WScreenPlugin` / `WAsyncDefaultsPlugin` / `WFormIconsPlugin` | M |
| **5.4** | P1-13、P2-44/45/46 | map：552 行拆 4 文件；`config` 可空删 `build()`；`maps` 私有 + `update()` 唯一入口；marker 按 id 复用；`dispose` 清 controller；await 后判 mounted | L |
| **5.5** | P2-42/43 | qr：`onScanned` 可空 + assert；`scanInterval` 默认 400ms；`WQrController.restartScan()`；`onError` 走 logger；overlay `==` | S–M |

## 8. 阶段 6：收口（2–3 人日）

1. 根包 `4.0.0`，抬高 9 个 `^` 约束（`release_check.sh` 会挡漂移）。
2. `docs/conventions.md` 增补一条"库内自查"：本仓库组件同样受 §6 约束，`WForm*` 的参数数需在 ADR-0004 里豁免说明。
3. `components.md` 改为生成物（2.5 已完成）；`docs/migrations/` 收齐各包迁移表。
4. golden 补齐：AppBar / Button / Step / FormBorder（对应 P3-5）。
5. 把本次评审 + 修复过程按 `docs/feedback/` 模板记 3–5 条真正卡住的点，形成闭环。
6. 发布顺序：`core → ui → async/toast/form → api/app → map/qr → 根包`，每步
   `bash scripts/publish_package.sh packages/<pkg>`，不要直接 `flutter pub publish`。

## 9. 依赖顺序与并行

```text
0.1 CI ──┬─► 1.1 ─ 1.2 ─ 1.3 ─ 1.4 ─ 1.5 ─ 1.6 ─ 1.7 ─ 1.8
         │                                        │
         └─► 2.1 ─ 2.2 ─ 2.3 ─ 2.4 ─ 2.5 ─ 2.6 ─ 2.7 ─ 2.8 ─ 2.9
                                                  │
    ADR-0004 / ADR-0003(已定) ─► 3.1..3.7 ──► 4.0 ─► 4.1..4.7 ──► 5.1..5.5 ─► 6.x
```

可并行的三条线（互不碰同一包）：

- **A 线（运行时止血）**：阶段 0.1 → 阶段 1；
- **B 线（工具链）**：阶段 2，与 A 完全独立；
- **C 线（结构重构）**：阶段 3，可与 A/B 并行（不同包），但**必须等 0.1**。

阶段 4 依赖阶段 3 的 ui 4.0（4.0 那一步依赖 D1）；阶段 5 可与阶段 4 并行（不同包）。

## 10. 工作量与最小路径

| 路径 | 范围 | 人日 | 关闭的问题 |
| --- | --- | --- | --- |
| **最小止血** | 阶段 0 + 1 + 2 | **7–10** | 8/13 运行时 P1 + 9/9 工具 P1；用户能感知的坑基本清零 |
| 基座 | + 阶段 3 | 15–22 | 加 P1-2/4/9 的根因、P2 的 15 条 |
| 全量 | + 阶段 4/5/6 | **30–45** | 214 → 约 130 个公开类型，跨包样式统一 |

（"人日"= 单人全职、熟悉代码库；不含评审往返与发版等待。阶段 4 若坚持"包间零依赖"，
每个包要各加一套主题，额外 +3–5 人日且一致性更差。）

## 11. 风险登记

| 风险 | 触发步 | 缓解 |
| --- | --- | --- |
| 4 个包首次进 CI 直接红 | 0.2 | 预留半天；先修测试再继续，别把红当噪声 |
| `WForm` 错误开始显示，消费者"多出一行字" | 1.1 | CHANGELOG 写"视觉变更"；提供 `WFormBorderConfig()` 显式退路 |
| 401 修复改变登出时机 | 1.5 | 先写用例固定语义：**只有刷新失败才清 token** |
| `WButton` 默认变主题色，品牌项目变样 | 1.7 | 单独发版；`WButtonStyles.primary` 作为显式预设保留 |
| 大版本删除引发下游编译错 | 3.x/4.x | 两段式 + 迁移表 + `// remove-in:` 守护；每包一个 PR |
| form 4.4 删 Config 波及其它字段 | 4.4 | 先删 7 个 `build()` 的公开签名，实现全部转私有；测试不改断言 |
| map/qr 依赖插件版本 | 5.4/5.5 | 这些包没有内部 CI 到 0.1 完成前，先只做 0.1 |
| 重构期间有新需求 | 全程 | 新需求只进"当前发布版"（A/B 线），结构改动只进 C 线分支 |

## 12. 每一步的验收清单（PR 模板）

```text
- [ ] 只动一个包、一个主题（1 PR = 1 步）
- [ ] 新增/修改的测试能独立说明行为（不是快照）
- [ ] dart analyze 无新增 issue
- [ ] 该包 test 全绿（CI 矩阵里能看到）
- [ ] bash scripts/release_check.sh（版本 / CHANGELOG / 根约束）
- [ ] 破坏性改动：CHANGELOG 有 **Breaking** 段 + docs/migrations/<pkg>.md 迁移表
- [ ] 改了 catalog/components.yaml → dart run tool/gen_catalog.dart
- [ ] 改了 docs/ → bash scripts/check_docs.sh
- [ ] 发版只走 bash scripts/publish_package.sh
```

## 13. 不要做什么（反模式）

1. **不要先重构 form。** 它最大、最复杂，且依赖 D1/D3 两个决策；先动它必然返工。
2. **不要在 0.1 之前动 async。** 1,923 行测试从没跑过，你没有安全网。
3. **不要把 214 → 130 当 KPI。** 删掉的每个类型都要能用"行为等价"证明；
   只删"零调用 + 有替代"的（评审 §4.3 已标出）。
4. **不要一次性破窗。** 14 个已发布包、真实消费者，断代必须两段式。
5. **不要同时改 5 个包。** 独立发版会互相阻塞，且失败时无法定位。
6. **不要为了"顺手"改无关文件。** 重构 PR 混入格式/重命名会让 review 失效。

## 14. 如果只做三件事

1. **0.1 补 CI**（半天）——让后面每一步都能被证明没变坏。
2. **1.1 修表单默认错误不可见**（半天）——用户感知最强、改动最小。
3. **2.5 catalog 单一真相**（2–3 天）——止住"docs 推荐了 CLI 查不到的组件"这类持续漂移。

这三件事合计约 1 周，不产生任何破坏性变更，却能把"这库能不能放心用"的答案从"看运气"变成"有守护"。
