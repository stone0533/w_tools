# 发版流程（Flutter 子包 + 工具包 + 聚合包）

> 发布历史见各包 `CHANGELOG.md` 与 [`docs/migrations/`](migrations/README.md)（breaking 变更）；
> 协调发布波次的版本矩阵记在根 `CHANGELOG.md` 的对应版本段。
>
> **本文是发布流程的唯一操作来源**；[`ai-maintainer-prompts.md`](ai-maintainer-prompts.md) 的 K 场景
> 只是给 AI 的任务卡与边界，脚本参数、顺序、常见坑以本文为准。

包清单的唯一来源是 [`scripts/packages.manifest`](../scripts/packages.manifest)；
`preflight.sh` / `release_check.sh` 都从这里取包名、路径、runner 和 example 测试。

发布前一条命令跑门禁：

```bash
bash scripts/preflight.sh --all     # 静态检查 + 全部测试 + 全部子包/根包 dry-run
bash scripts/preflight.sh           # 只跑静态检查（最快）
```

> `--all` 里的**根包 dry-run 也计入失败**：它要求根包依赖的版本都已经在 pub.dev 上。
> 发布子包阶段先用 `--with-tests`（静态 + 测试）；子包全部上线后再跑 `--all`，
> 或者在根包发布前单独跑 `bash scripts/publish_package.sh . --dry-run`。
>
> **镜像滞后**：如果本机 / CI 设置了 `PUB_HOSTED_URL` 指向镜像（如 `pub.flutter-io.cn`），
> 刚发布的版本可能暂时不可见。验证时显式 `PUB_HOSTED_URL=https://pub.dev`，并换一个全新的
> `PUB_CACHE`，否则 pub 会复用旧的版本元数据。

`w_tools` 是 11 个库子包（10 个 Flutter + 1 个纯 Dart 地图接口）+ 工具包（`w_tools_cli` / `w_tools_figma` / `w_tools_device` / `w_tools_e2e`）+ 1 个聚合包。版本各自演进，所以「仓库里有什么」和
「pub.dev 上用户能装到什么」很容易分叉 —— 例如 `w_tools_map` 曾经是仓库 1.1.0、
pub.dev 1.0.0，聚合包用户拿不到 1.1.0 的地图改进。

下面这套流程把这种分叉变成可执行检查。

## 版本规则

- **子包**：各自独立发版，版本号写在 `packages/<pkg>/pubspec.yaml`。破坏性改动 → major；
  新能力 → minor；修 bug / 文档 → patch。`CHANGELOG.md` 必须有与 pubspec 版本**完全一致**的
  `## x.y.z` 段。

### 发布窗口判断（先看 pub.dev）

决定 `remove-in` 或 breaking 版本前，先查 pub.dev 最新版本：

```bash
curl -s https://pub.dev/api/packages/w_tools_ui | jq -r .latest.version
# 或（脚本直接查 https://pub.dev，不读本地的 PUB_HOSTED_URL）
bash scripts/release_check.sh --package ui --online
```

- 本地版本 **高于** pub.dev 且该本地版本尚未发布时，这个本地 major 就是 breaking 窗口；
  `remove-in` 写这个 major，不写下一个 major。
- 例：本地 `ui 7.1.0`、pub.dev `ui 7.0.0`，7.1 就是 breaking 窗口；
  7.1 的删除/改名不应写成 `remove-in: 8.0.0`。
- `--online` 在目标版本尚未发布时会显示「仓库 X > pub.dev Y —— 待发布」并以非 0 退出；
  这是预期的「待发布」状态，不是内容已验证。
- **聚合包**：`w_tools` 按聚合层独立发版。它对各子包的 caret 约束下界应取**子包当前版本**
  （例如 `^1.2.0`，而不是 `^1.0.0`）：`^1.0.0` 虽然能接受 1.2.0，但已有 lockfile 的用户
  不会自动升级，新装用户也可能停在旧版。日常 `preflight` 只提醒；发布根包前的
  `release_check --strict` 会把「能接受但下界落后」判成失败。
- **版本语义**：`Fixed` → patch；`Added` / 兼容的 `Changed` → minor；
  `Removed` / 破坏性行为变更 → **major**。发布脚本会在「版本不是 X.0.0 但 CHANGELOG
  含 Removed/breaking」时给出警告。
- **发布顺序**：先子包，后聚合包。聚合包约束抬高到新子包版本之后才能发。
- **已发布版本不回滚、不重发**：有外部使用者时 fix-forward —— 先发 patch 恢复兼容
  （通常是 `@Deprecated` 垫片），下个 major 再删；确认没有外部使用者时不回滚、不加垫片，
  记录例外，后续破坏性改动一律按 major 发。
- **工具包独立发布**：`cli` / `figma` / `device`（纯 Dart）与 `e2e`（Flutter）都不被根包依赖，
  版本自己走，不需要跟子包/根包同批。发布命令一样用 `publish_package.sh`
  （脚本检测到没有 Flutter 依赖时会改用 `dart pub publish`）。
- **历史例外**：`w_tools_ui 1.1.0` 删除了 `WNetworkImageWithRetry`，按 semver 应为 2.0.0；
  当时无外部使用者，未回滚、未加兼容垫片。今后破坏性改动一律按 major 发。

## 消费方 AGENTS 更新

`w_tools_cli` 的 AGENTS / 文档模板变更后，消费方不会自动更新已有 `AGENTS.md`。
发版说明中需要提醒消费方升级 CLI 后：

```bash
dart run w_tools_cli:w_tools init              # 重新生成，拿到最新模板
dart run w_tools_cli:w_tools init --check-drift # 只检查是否过期，不改文件
```

模板变更只影响后续 `init` 生成内容；已有项目必须重新 `init` 才会拿到新的 Form / UI / Button 规则。

## 发版步骤

下面以 `map` 为例，换成你要发的包即可。

1. 确认子包 `version` + `CHANGELOG.md` 的 `## x.y.z` 段：功能 PR 里已经抬过就沿用；
   还没抬时才在这里抬（版本号决定 semver，拿不准先和人工确认）。
2. 需要聚合包跟上的，确认根 `pubspec.yaml` 里对应的 `w_tools_<pkg>: ^x.y.z` 下界已抬
   （功能 PR 里改过就不动；`release_check` 会校验下界是否落后）。
3. 改根 `version` + 写根 `CHANGELOG.md`。
4. 本地预检（不要求工作区干净）：
   ```bash
   bash scripts/release_check.sh --package map
   ```
5. 提交到 feature 分支并 push，开 PR；等 Required checks 通过后**合并到 main**
   （合并方式固定 **Merge commit**，见 [CONTRIBUTING §6](../CONTRIBUTING.md#6-git--pr-流程)）。
6. 在 main 上复核 + 发布预演（**必须走发布脚本**，原因见下一节）：
   ```bash
   # Required checks 在 PR 分支上确认：gh pr checks 需要一个 PR，
   # 合并后在 main 上跑会找不到 PR（有 PR 号就直接传）。
   bash scripts/check_pr_checks.sh <PR号>
   # --strict 要求当前分支有 upstream，且 ahead/behind 都为 0（见 scripts/check_git_sync.sh）
   bash scripts/release_check.sh --strict --package map
   bash scripts/publish_package.sh packages/map --dry-run
   ```
   第 7 步的正式发布会**自己再跑一遍**这些保护（干净工作区 / `main` 且 HEAD == `origin/main` /
   `release_check --strict`），漏跑第 6 步不会把未提交改动发出去；例外情况用脚本的 `--force`。
7. 发布子包：
   ```bash
   bash scripts/publish_package.sh packages/map
   # 其余需要发布的子包同理
   ```
   发布成功后脚本会把该版本写成 `scripts/api_snapshots/w_tools_<pkg>-<version>.txt`。
   **这个文件必须提交**：否则基线漂移，且下次 `release_check --strict` 会因“未跟踪文件”失败。
   ```bash
   git add scripts/api_snapshots
   git commit -m "chore(release): w_tools_map <version> API 基线"
   git push
   ```
8. 需要聚合包跟上时，先跑**完整** `--strict`（会校验根包下界），最后发聚合包：
   ```bash
   bash scripts/release_check.sh --strict          # 含根包 caret 下界检查
   bash scripts/publish_package.sh . --dry-run     # 预演
   bash scripts/publish_package.sh .               # 正式发布
   ```
9. 发布后确认（这一步才会把「待发布」判成通过）：
   ```bash
   bash scripts/release_check.sh --package map --online
   # 发布多个包/聚合包时去掉 --package，做全量比对
   # 状态总表（线上 / 快照 / 根约束一眼看完）
   python3 scripts/release_status.py --online
   ```
   `release-status.yml` 每周一也会跑 `release_status.py --online --check`：
   「待发布」不算错，只有「仓库落后 / 快照与线上不一致」才会红；网络不可达（一个包都没取到）
   返回退出码 2，周检按「本次跳过」处理，不会因外网抖动误报发布事故。

> `--online` 在**发布前**跑必然报「待发布」，它只用于发布后核对线上版本；
> 发布前的门禁是第 4、6 步。

### 看版本变更列表

合并方式固定为 Merge commit（见 [CONTRIBUTING §6](../CONTRIBUTING.md#6-git--pr-流程)），
所以用 **first-parent** 取「PR 级」历史，不会被 PR 内部的中间 commit 干扰：

```bash
git log --first-parent --oneline <上一次发版的 commit>..HEAD
```

写 CHANGELOG / 发版说明时用这一条；`git log`（不带 `--first-parent`）留着看每个 PR 的细节。

## 发布前真机 / 消费方检查

自动测试覆盖不到的，发布前人工过一遍：

- **qr**：真机扫码一次（单次模式暂停、`restartScan` 后可再扫）、拒绝相机权限走 `noPermissionCallback`；
- **map**：真机打开地图 → 选中 marker（相机 + InfoWindow）→ 关闭 → 退出页面（无 controller 悬空）；
- **消费方**：临时 app 用 `path:` 依赖子包，跑一屏「按钮 + 图片 + 表单 + async + toast」，
  确认 `flutter analyze` 与运行都正常（参考 `docs/migrations/README.md` 的版本约束）。
- **发布形态冒烟**：`scripts/publish_package.sh packages/<pkg> --stage-only` 生成暂存副本，
  临时 app 用 `path:` + `dependency_overrides` 指向这些副本（去掉 workspace），
  `flutter pub get && flutter analyze` —— 验证真正会发布出去的文件，而不是仓库内形态。

## 为什么用 `publish_package.sh` 而不是直接 `flutter pub publish`

仓库根的 `pubspec.yaml` 为了本地开发写着 `workspace:`，子包写着 `resolution: workspace`。
pub 会把 pubspec **原样**发布；消费方把包装进 pub 缓存后，`dart pub deps`
（以及依赖它的 IDE / 工具）会去读依赖的 `workspace:`，然后找不到
`~/.pub-cache/.../w_tools-x.y.z/packages/core` 而直接失败：

```
Could not find a file named "pubspec.yaml" in ".../w_tools-2.0.0/packages/core".
That was included in the workspace of ".../w_tools-2.0.0/pubspec.yaml".
Failed to update packages.        # 退出码 66
```

`scripts/publish_package.sh` 会先把包复制到仓库外的临时目录，去掉 `workspace:` 与
`resolution: workspace`，排除 `test/`、`docs/`、`scripts/` 等仓库内容（根包还排除 `packages/`），
确认暂存 pubspec 干净后再执行 `pub publish`。CI 的发布预演也走它。

暂存副本直接来自**工作区**，而暂存目录在 git 之外：`pub publish` 看不到未提交改动、错误分支、
落后 main，也看不到 CHANGELOG 缺段。所以正式发布（非 `--dry-run` / `--stage-only`）前脚本会
fail-closed 地检查：工作区干净、当前分支是 `main` 且 `HEAD == origin/main`、
`release_check.sh --strict` 通过；确实需要例外时用 `--force`。

发布目标**默认是 `https://pub.dev`**，不会继承本地 shell 里的 `PUB_HOSTED_URL`
（那通常是只读镜像，元数据还会滞后）。需要发到其它 host 时用：

```bash
PUBLISH_HOSTED_URL=https://your.pub.host bash scripts/publish_package.sh packages/map
```

> `w_tools 2.0.0` 就是这样把 `workspace:` 发出去的，而已发布版本无法修改：
> 用 2.0.0 的项目 `flutter pub get` / `flutter analyze` 仍可用，但 `dart pub deps`
> 会报上面的错误；升级到修复版本即可。

## 只发一个子包时

- 用 `--package <pkg>` 收窄检查范围：根包版本、其他子包的漂移都不再阻塞你。
- 但要确认根包对该子包的 caret 约束仍覆盖新版本（脚本在 `--package` 模式下也会检查这一条），
  否则聚合包用户装不到新版本。
- 已发布的聚合包不会自动升级依赖，需要一次新的聚合版本才会带上它。

## `scripts/release_check.sh` 检查项

| 检查 | 说明 |
|---|---|
| 包名 / `resolution: workspace` | 目录与包名一致，否则 pub workspace 解析异常 |
| 发布物料 | 每个包有 `README.md` / `CHANGELOG.md` / `LICENSE` |
| 版本 ↔ CHANGELOG | `## <pubspec version>` 必须存在（点号按字面匹配） |
| 根包约束 | 每个 `w_tools_<pkg>: ^x.y.z` 必须接受子包本地版本 |
| 根包版本 ↔ CHANGELOG | 同上 |
| README 版本声明 | 禁止出现「当前 `x.y.z`」这种会漂移的硬编码 |
| 弃用到期 | `@Deprecated` 的 `remove-in` 是否到期（复用 `check_deprecations.py`） |
| `## Unreleased` 条目 | 只提醒：说明有已记录但未发版的改动 |
| `--strict` | 已跟踪文件无未提交改动、无未跟踪文件 |
| `--online` | 与 pub.dev API 对比最新版本，指出待发布 / 落后 |
| `--package <pkg>` | 只检查指定子包；根包与其他子包不参与 |

## 常见坑

- **`pub publish` 提示工作区不干净**：先提交再跑（具体退出码看 pub 输出；历史上
  `pub publish --dry-run` 报过 65）。
- **只发子包不发聚合包**：已发布过的聚合包不会自动更新依赖约束；想让它带上新子包必须发一次
  新的聚合版本。
- **忘记抬约束**：子包发了 1.1.0，但根包还写 `^1.0.0`，用户拿到的是 1.0.0。脚本会直接报错。
- **CHANGELOG 写成 `## v1.1.0`**：脚本按 `## 1.1.0` 精确匹配，不要带 `v`。
- **直接在包目录敲 `flutter pub publish`**：会把 `workspace:` / `resolution: workspace`
  带进发布物，消费方 `dart pub deps` 会失败（当时观察到的退出码是 66）。统一用
  `scripts/publish_package.sh`。
- **`## Unreleased` 一直挂着**：先确认这些改动是不是已经随已发布版本出去了——
  是就折叠进对应版本（已发布版本的 CHANGELOG 会原样显示在 pub.dev 上，改不了旧版本，
  只能发新版本修正）；只有真正未发的才继续留在 Unreleased。
