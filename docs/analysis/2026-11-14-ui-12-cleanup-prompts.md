# ui 12.0 清理：维护者提示词与执行记录

> 本文是 2026-11-14 `w_tools_ui` 审计（不合理功能 / 建议去掉 / 过分封装三类问题）的落地提示词。
> 场景编号 / 固定前缀来自
> [`docs/ai-maintainer-prompts.md`](../ai-maintainer-prompts.md) §0 与 §1，本文只填占位符，
> 不新造流程。历史分析，**不是当前事实源**。

## 0. 固定前缀（每次先贴）

```text
你是 w_tools 的维护者，先读 docs/ai-contract.md、AGENTS.md 和
packages/<pkg>/README.md（存在时），再开始；改具体包时按 docs/agents/README.md 的索引
读规则页（app_getx → app.md、map_google → map.md、device / e2e → device-testing.md）；
新增 / 修改公开类型时，
再读 CONTRIBUTING.md 与 docs/naming.md。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 命令在正确目录跑：`dart run tool/*`、`dart test test/*` 只在 `packages/cli` 下成立；
   `scripts/*.sh` 会自己 cd 到仓库根。贴命令时带上 cd，别让下一个人复现失败。
7. 不要改无关包、无关文档、无关测试。
8. 默认只改工作区：不要 commit / push / 开 PR / 合并，除非任务块明确要求（如 K-2 / K-2M）；
   不要用 `git reset --hard` / `git clean` 清理未提交内容。
9. 公开变化：抬子包版本 + 在当前版本 CHANGELOG 段写变更；所有库子包都要同步
   `packages/cli/lib/src/init/versions.dart` 的 `subpackageConstraints`（工具包
   cli / figma / device / e2e 除外），聚合子包（core / async / ui / form / api / toast）
   还要抬根 pubspec 的 `^x.y.z` 下界 —— `check_versions.py` 要求下界 == 当前版本。
   根 pubspec 变了但根包版本没抬时，根 `CHANGELOG.md` 必须有非空 `## Unreleased`
   （CI 的 check_pr_scope 强制，K-2 折叠成版本段）。
   PR 正文保留「## 改动类型」段并至少勾选一项；勾了公开类别（公开变化 / 删除废弃 / 新增包）时，
   每个改了公开代码的包都要改自己的 CHANGELOG（空 body 也会失败）。
10. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

## 1. 批次划分（对应审计的「建议清理顺序」）

| 批次 | 场景 | 内容 | 版本影响 | 本轮 |
|---|---|---|---|---|
| 0 | A | 审计第四节「实现级问题」：重复 / 死代码、空 title 静默无顶栏、未使用 key、无绘制装饰 | 内部，无 API | 2026-11-14 上午 |
| 1 | D | 审计第二节「建议去掉」1–10、12–14 + `WScaffold.underlayWidget` + `WImageStyle.avatar/thumbnail` + `WStep` 恢复 `const` | ui major（11.0.0 → 12.0.0） | 2026-11-14 上午 |
| 2 | B/D | 收敛剩余封装：`WTabBar` / `WTabBarStyle` 删除（用 Material TabBar + TabBarTheme）、`WImageSlots` 五态 → 两槽、`WImageController` → error builder 的 `onRetry`、`WImageStyle` 去 margin/padding、删除 `WImageSource.parse` 与 `WAssets` 全局状态 | 仍写在 12.0.0（未发布） | 2026-11-14 下午 |
| 3 | B | `WButton` 迁 `ButtonStyle` / 主题通道统一、`WColorExtension` hex 字节序、数字格式化迁出 ui；`WTextStyles` 业务语义 variant 经评估保留 | 12.0.0（未发布）+ core 3.2.0 | 2026-11-14 下午 |

批次 2 仍是**纯减法 / 收敛**；批次 3 才新增公开类型（`WButtonTheme` / `WButtonVariant` 与
CSS hex helper）。`WTextStyles` 的 `price` / `number` / `badge` 经评估保留：它们是已发布语义、
被 form / toast 的 `textTheme` 投影依赖，删除收益低、迁移面大，审计结论也是「不建议现在动」。

## 2. 批次 0：A（内部重构 / Bug 修复）

```text
任务：对 ui 的 WScaffold / WSelectableRow / WButtonStyle 做内部修复，不改变公开 API 和默认行为。

要求：
1. 先说明为什么这是内部改动：哪些 public API 和默认行为没有变。
2. 只改必要代码 + 测试。
3. 如果发现确实有公开行为变化，停下来，改用场景 B。
4. 不要改 catalog / AGENTS / README / example。
5. 运行 cd packages/ui && flutter test 和 bash scripts/preflight.sh --package ui
   （没有 Flutter cache 时加 --sandbox）。
6. 报告 changed files、为什么不需要文档更新、测试结果。

本轮具体条目：
- WScaffold：删掉重复的 includeStatusBar 断言；删掉恒真的「appBar 与 title 互斥」断言（构造器已保证）；
  修正 WScaffold.basic(title: '') 静默不渲染顶栏（_needsDefaultAppBar 判空方式）。
- WSelectableRow：_rowKey 只被当作 scrollViewKey 透传、从未读取；删字段与未用参数。
- WButtonStyle：hasDecoration 只看 borderRadius 就包 DecoratedBox，删掉该分支条件。
```

## 3. 批次 1：D（ui 12.0.0 纯减法）

```text
任务：删除 w_tools_ui 12.0.0 的纯镜像 / 冗余公开 API，替代方案见每一条。

要求：
1. 先查已发布基线：删除 / 改名已发布 API 必须抬 major（ui 已发布 11.0.0 → 12.0.0）。
2. 代码层直接删除（这些入口没有过渡价值，不做 @Deprecated）；同步删测试与 example 用法。
3. 抬 packages/ui/pubspec.yaml 到 12.0.0，写 `## 12.0.0` 的 Breaking / Removed；
   同步 packages/cli/lib/src/init/versions.dart 的 subpackageConstraints 与根 pubspec 下界；
   根 pubspec 变了但根包版本没抬 → 根 CHANGELOG 写非空 `## Unreleased`。
4. 写 docs/migrations/ui-12.0.md，并在 docs/migrations/README.md 登记。
5. 把删除的公开名补进 scripts/check_removed_api.py。
6. catalog：删除 WStepFlow / WNavBarStyle / WGlobalKeyExtension 条目，调整 WStep / WNavBar /
   WImageStyle / WNumLayoutExtension / WStringExtension / WBoxDecorationExtension /
   WNotificationListener / WPressable / WImageErrorView 条目。
7. AGENTS / README / example / docs 不能继续推荐旧入口。
8. 在仓库根运行：
   python3 scripts/check_removed_api.py
   python3 scripts/check_deprecations.py
   python3 scripts/check_public_api_diff.py --package ui
   python3 scripts/check_public_catalog.py
   bash scripts/check_docs.sh
   bash scripts/preflight.sh --package ui
9. 报告 changed files、命令结果、explain 输出、剩余风险。

删除清单（替代 → 说明）：
- WStepFlow → WStep（参数镜像 + build()，零增量价值）
- WNavBarStyle → WNavBar(decoration:, padding:)
- WNavController.animation / offset / previousIndex / indexIsChanging / animateTo
  → currentIndex（动画从未被 WNavBar 消费；同时去掉 vsync 依赖）
- WGlobalKeyExtension → GlobalKey.currentContext.findRenderObject()
- WNumLayoutExtension.heightBox / widthBox / squareBox / horizontalPadding / verticalPadding / borderRadius
  → 原生 SizedBox / EdgeInsets / BorderRadius（保留 allPadding / borderSideOf）
- WStringExtension.toInt / toDouble / toNum / trimAll → 原生 tryParse / replaceAll
- WBoxDecorationExtension 12 个方法 → 只留 withBackground / circle
- WImageErrorView.compact + 4 个尺寸阈值 → 固定布局，重试按钮由 showAction 控制
- WNotificationListener.preventNotificationPropagation → onNotification 返回 false
- WPressable.hasChildSemanticsWhenDisabled → 禁用时保留 child 语义
- WScaffold.underlayWidget → 页面层 Stack
- WImageStyle.avatar / thumbnail → WImageStyle(width:, height:, borderRadius:)
- WStep 构造时复制 labels → 恢复 const，由调用方保证不可变
```

## 4. 批次 2：收敛剩余封装（仍写进未发布的 12.0.0）

```text
任务：收敛 w_tools_ui 的剩余封装层，仍然全用已有替代入口，不新增公开类型。
版本仍是未发布的 12.0.0（不另抬 minor），BREAKING 写进同一个 `## 12.0.0` 段。

要求：
1. 每删一个入口，先确认替代入口已存在并写进 migration。
2. 直接删除，不做 @Deprecated（12.0.0 尚未发布，没有过渡窗口）。
3. 同步 test / example / README / docs / catalog；跑生成器，不手改生成物。
4. 把删除的公开名补进 scripts/check_removed_api.py。
5. 跑 check_removed_api / check_deprecations / check_public_api_diff / check_public_catalog /
   check_docs / preflight --package ui，并单独跑 ui 与 example 的 flutter test。
6. 报告 changed files、命令结果、explain 输出、剩余风险。

删除清单（替代 → 说明）：
- WTabBar / WTabBarStyle → Material TabBar + TabBarTheme
  （WTabBar 只是 22 个参数的逐字镜像，零默认值）
- WImageSlots.emptyBuilder → placeholderBuilder（空 data 仍然不是错误）
- WImageSlots.progressBuilder → placeholderBuilder（进度细分交给业务自绘）
- WImageSlots.showRetryButton / retryLabel → errorWidgetBuilder 的 onRetry 参数
  + 现成的 WImageErrorView
- WImageController / WImageLoadSnapshot → errorWidgetBuilder 的 onRetry +
  WImage.onLoadStatusChanged / onProgress
- WImageStyle.margin / padding → 外层 Padding / Container
- WImageSource.parse → 显式 WImageSource.network / asset / file / base64 / provider
- WAssets / WStringExtension.assetImagePath / WImageSource.asset(prefix:) →
  显式传完整资源路径给 WImageSource.asset / AssetImage

仍然留到批次 3（需要新公开 API 设计）：
WButton 迁 ButtonStyle / 主题扩展统一 / WButtonResolvedStyle 收口 / WTextStyles 产品语义 /
WColorExtension hex 字节序 / 数字格式化迁出 ui
```

## 5. 批次 3 登记（未执行）

```text
WButton 迁 ButtonStyle + 统一主题通道（需要新的 WButtonTheme 设计）
WButtonResolvedStyle / WButtonContentBuilder 收口
WTextStyles 产品语义 variant 归属
WColorExtension hex 字节序（AARRGGBB ↔ RRGGBBAA）
数字格式化迁出 ui（迁 core 或直接用 intl）
```

## 6. 验收命令（每批）

```bash
cd packages/ui && flutter test
cd packages/ui/example && flutter test
cd packages/cli && dart run tool/gen_catalog.dart && dart run tool/gen_templates.dart
python3 scripts/check_removed_api.py
python3 scripts/check_deprecations.py
python3 scripts/check_public_api_diff.py --package ui
python3 scripts/check_public_catalog.py
bash scripts/check_docs.sh
bash scripts/preflight.sh --package ui
```

## 6. 执行记录（2026-11-14）

版本：`w_tools_ui` 11.0.0 → 12.0.0；根包约束 `^12.0.0`（根包版本未抬，根 CHANGELOG 写
`## Unreleased`）；CLI `versions.dart` 的 `w_tools_ui` 约束同步。

本轮完成：

- 批次 0：3 个内部修复（WScaffold 断言 / 空标题、WSelectableRow 未用 key、WButtonStyle
  无绘制装饰）。
- 批次 1：13 项删除 + `WStep` 恢复 `const`，公开 API 快照 diff 记录 59 条变化。
- catalog：ui 条目 67 → 65（删除 `WStepFlow` / `WNavBarStyle` / `WGlobalKeyExtension`，
  其余条目改 usage / pitfalls）。
- 文档：`docs/migrations/ui-12.0.md`、README / agents / modules / naming / 示例 README。
- 测试：`packages/ui` 459 passed；`packages/ui/example` 9 passed；根契约
  `test/configs_all_test.dart` 8 passed。

实际命令结果：

```text
bash scripts/preflight.sh --package ui --sandbox
  ✓ format / analyze / docs / naming / public catalog / catalog symbols
  ✓ public api diff / catalog fresh / versions / release check / ci parity
  - test w_tools_ui（--sandbox 跳过；本轮另用 flutter test 全量跑过）

python3 scripts/check_removed_api.py        ✓（148 个文件）
python3 scripts/check_public_api_diff.py --package ui  ✓（59 条变化均已记录）
```

### 批次 2（2026-11-14 下午，仍写进 12.0.0）

- 删除 `WTabBar` / `WTabBarStyle`（顶部 tab 用 Material `TabBar` + `TabBarTheme`）。
- `WImageSlots` 五态 → 两槽：`placeholderBuilder` + `errorWidgetBuilder`（第四参数 `onRetry`）；
  删除 `emptyBuilder` / `progressBuilder` / `showRetryButton` / `retryLabel`。
- 删除 `WImageController` / `WImageLoadSnapshot`；状态用 `onLoadStatusChanged` / `onProgress`。
- 删除 `WImageStyle.margin/padding`（留白在外层 `Padding`）。
- 删除 `WImageSource.parse`、`WImageSource.asset(prefix:)`、`WAssets` / `assetImagePath`。
- ui catalog 65 → 60；公开 API diff 累计 143 条变化。

执行结果：

```text
bash scripts/preflight.sh --package ui        ✓ 门禁通过（含 ui 422 + example 9 测试）
python3 scripts/check_removed_api.py          ✓（148 个文件）
python3 scripts/check_public_api_diff.py --package ui  ✓（143 条变化均已记录）
bash scripts/check_docs.sh                    ✓
dart analyze（仓库根）                         ✓
flutter test test/configs_all_test.dart       ✓ 7 passed
```

测试数从 459 降到 422 是删除了 controller / 五态插槽 / parse 的专属用例，
不是覆盖面收缩：对应行为已由 error slot 重试、loader 通知去重、显式来源工厂的新用例覆盖。
golden `wimage_retry.png` 因错误视图改为显式 `WImageErrorView` 重新生成。

仍未执行（批次 3，需要新的公开 API 设计）：`WButton` 迁 `ButtonStyle` / 主题通道统一 /
`WButtonResolvedStyle` 收口 / `WTextStyles` 产品语义 / hex 字节序 / 数字格式化迁出 ui。

### 批次 3（2026-11-14 下午）

- `WButton` 改为 `StatelessWidget`，直接渲染 Material `FilledButton` / `OutlinedButton` /
  `TextButton`：新增 `WButtonTheme`（四态 `ButtonStyle` ThemeExtension）、`WButtonVariant`；
  `style` 改为 Material `ButtonStyle`；删除 `WButtonStyle` / `WButtonStyleSet` /
  `WButtonMotion` / `WButtonSemantics` / `WButtonContentBuilder` / `WButtonResolvedStyle`；
  无障碍改直接参数 `semanticLabel` / `semanticHint` / `loadingLabel`。
- CLI 模板 `app_buttons.dart.tpl` 改为返回 `ButtonStyle`；`init_test` / `ai_contract_test`
  同步（含删掉过期的 `WGlobalKeyExtension` explain 用例）。
- `WColorExtension`：保留 `fromHex` / `toHex`（AARRGGBB，与 Flutter 一致），新增
  `fromCssHex` / `toCssHex` / `String.toCssColor`（RRGGBBAA）。不做静默翻转：8 位字符串
  无法判断字节序，翻转会悄悄改掉已有颜色；显式入口更安全。
- `WNumFormatExtension` 从 ui 迁到 core 3.2.0（方法名不变）；core / 根包约束与
  `versions.dart` 同步，测试迁到 `packages/core/test/num_format_test.dart`。
- `WTextStyles` 的 `price` / `number` / `badge` 保留（理由见上）。
- ui catalog 60 → 55；公开 API diff 累计 233 条变化。

执行结果：

```text
bash scripts/preflight.sh --package ui        ✓ 门禁通过（ui 393 + example 9）
bash scripts/preflight.sh --package core      ✓ 门禁通过（core 157 + example 4）
cd packages/cli && dart test test/internal/ai_contract_test.dart test/internal/init_test.dart  ✓ 155 passed
flutter test test/configs_all_test.dart       ✓ 7 passed
python3 scripts/check_removed_api.py          ✓
python3 scripts/check_public_api_diff.py --package ui  ✓（233 条）
bash scripts/check_docs.sh                    ✓
dart analyze（仓库根）                         ✓
```

golden `button_icon_text.png` 因切换到 Material 按钮重新生成。

## 7. 批次 4：发布波次（K-0 / K-2M / K-3~K-5）

```text
使用 docs/ai-maintainer-prompts.md 的场景 K-0（多包总控），执行顺序：
K-2M 版本准备 → K-3 dry-run → K-4 发布 → 快照 PR → K-5 验证。

范围（以 `python3 scripts/release_wave.py plan --all` 为准）：
- w_tools_core 3.1.2 → 3.2.0（WNumFormatExtension 迁入）
- w_tools_ui 11.0.0 → 12.0.0（三批封装收敛）
- w_tools_cli 1.20.42 → 1.21.0（模板/约束/catalog 同步）
- w_tools 16.0.3 → 16.1.0（聚合约束 core ^3.2.0 / ui ^12.0.0）

前置：
1. 功能改动合并进 main（分支 + PR + Required checks），工作区干净、HEAD == origin/main。
2. `bash scripts/preflight.sh --with-tests` 通过；CLI init/ai_contract 测试通过。
3. 版本 / CHANGELOG / README 安装约束一致（check_versions + release_check）。

执行：
`python3 scripts/release_wave.py plan --all --out .w_tools/release-plan.json`
`python3 scripts/release_wave.py run --plan .w_tools/release-plan.json --dry-run`
`python3 scripts/release_wave.py run --plan .w_tools/release-plan.json --yes`
（它负责逐包 publish、快照 PR 的创建/等 checks/合并、根包发布与验证；失败用 `--resume`。）

验收：
`python3 scripts/release_status.py --online --check`；`check_publish_drift.py` code drift 为零；
每包 CHANGELOG / pubspec / pub.dev 版本一致。
```

状态：完成（2026-11-14 15:03 CST）。

结果：

- `w_tools_core` 3.2.0、`w_tools_ui` 12.0.0、`w_tools_cli` 1.21.0、`w_tools` 16.1.0
  已发布到 pub.dev；快照 PR #232 已合并。
- `python3 scripts/release_status.py --online --check`：状态正常（16 个包）。
- `check_publish_drift.py --package core/ui/cli/w_tools --check`：全部无漂移。
- 波次 state：`.w_tools/release-wave-state.json`（gitignored）。
