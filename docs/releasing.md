# 发版流程（8 个 Flutter 子包 + w_tools_cli + 聚合包）

`w_tools` 是 8 个 Flutter 子包 + 1 个纯 Dart 工具包（`w_tools_cli`）+ 1 个聚合包。版本各自演进，所以「仓库里有什么」和
「pub.dev 上用户能装到什么」很容易分叉 —— 例如 `w_tools_map` 曾经是仓库 1.1.0、
pub.dev 1.0.0，聚合包用户拿不到 1.1.0 的地图改进。

下面这套流程把这种分叉变成可执行检查。

## 版本规则

- **子包**：各自独立发版，版本号写在 `packages/<pkg>/pubspec.yaml`。破坏性改动 → major；
  新能力 → minor；修 bug / 文档 → patch。`CHANGELOG.md` 必须有与 pubspec 版本**完全一致**的
  `## x.y.z` 段。
- **聚合包**：`w_tools` 按聚合层独立发版。它对各子包的 caret 约束下界应取**子包当前版本**
  （例如 `^1.2.0`，而不是 `^1.0.0`）：`^1.0.0` 虽然能接受 1.2.0，但已有 lockfile 的用户
  不会自动升级，新装用户也可能停在旧版。`release_check` 在「能接受但下界落后」时会给出提醒。
- **版本语义**：`Fixed` → patch；`Added` / 兼容的 `Changed` → minor；
  `Removed` / 破坏性行为变更 → **major**。发布脚本会在「版本不是 X.0.0 但 CHANGELOG
  含 Removed/breaking」时给出警告。
- **发布顺序**：先子包，后聚合包。聚合包约束抬高到新子包版本之后才能发。
- **`w_tools_cli` 独立发布**：它是纯 Dart 工具包（`packages/cli`），不被根包依赖，
  版本自己走。发布命令一样用 `bash scripts/publish_package.sh packages/cli`
  （脚本检测到没有 Flutter 依赖时会改用 `dart pub publish`），不需要跟子包/根包同批。
- **历史例外**：`w_tools_ui 1.1.0` 删除了 `WNetworkImageWithRetry`，按 semver 应为 2.0.0；
  当时无外部使用者，未回滚、未加兼容垫片。今后破坏性改动一律按 major 发。

## 发版步骤

1. 改子包 `version` + 写 `CHANGELOG.md`（`## x.y.z`）。
2. 需要聚合包跟上的，改根 `pubspec.yaml` 里对应的 `w_tools_<pkg>: ^x.y.z`。
3. 改根 `version` + 写根 `CHANGELOG.md`。
4. 本地预检（不要求工作区干净）：
   ```bash
   bash scripts/release_check.sh --package map
   ```
5. 提交（`pub publish` 只有在干净工作区才不会报 65）。
6. 干净工作区复核 + 发布预演（**必须走发布脚本**，原因见下一节）：
   ```bash
   bash scripts/release_check.sh --strict --package map
   bash scripts/publish_package.sh packages/map --dry-run
   ```
7. 发布子包：
   ```bash
   bash scripts/publish_package.sh packages/map
   # 其余需要发布的子包同理
   ```
8. 需要聚合包跟上时，最后发聚合包：
   ```bash
   bash scripts/publish_package.sh . --dry-run   # 预演
   bash scripts/publish_package.sh .             # 正式发布
   ```
9. 发布后确认（这一步才会把「待发布」判成通过）：
   ```bash
   bash scripts/release_check.sh --package map --online
   # 发布多个包/聚合包时去掉 --package，做全量比对
   ```

> `--online` 在**发布前**跑必然报「待发布」，它只用于发布后核对线上版本；
> 发布前的门禁是第 4、6 步。

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
| `## Unreleased` 条目 | 只提醒：说明有已记录但未发版的改动 |
| `--strict` | 已跟踪文件无未提交改动、无未跟踪文件 |
| `--online` | 与 pub.dev API 对比最新版本，指出待发布 / 落后 |
| `--package <pkg>` | 只检查指定子包；根包与其他子包不参与 |

## 常见坑

- **`pub publish --dry-run` 返回 65**：多半是工作区不干净。先提交再跑。
- **只发子包不发聚合包**：已发布过的聚合包不会自动更新依赖约束；想让它带上新子包必须发一次
  新的聚合版本。
- **忘记抬约束**：子包发了 1.1.0，但根包还写 `^1.0.0`，用户拿到的是 1.0.0。脚本会直接报错。
- **CHANGELOG 写成 `## v1.1.0`**：脚本按 `## 1.1.0` 精确匹配，不要带 `v`。
- **直接在包目录敲 `flutter pub publish`**：会把 `workspace:` / `resolution: workspace`
  带进发布物，消费方 `dart pub deps` 会以退出码 66 失败。统一用
  `scripts/publish_package.sh`。
- **`## Unreleased` 一直挂着**：先确认这些改动是不是已经随已发布版本出去了——
  是就折叠进对应版本（已发布版本的 CHANGELOG 会原样显示在 pub.dev 上，改不了旧版本，
  只能发新版本修正）；只有真正未发的才继续留在 Unreleased。
