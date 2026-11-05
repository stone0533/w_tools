> 发布记录：某次发布的快照，不代表当前版本。

> 历史发布记录：不代表当前版本。
# 发布前门禁记录（2026-11-04）

- 范围：13 个子包 + 根包 `w_tools`（A 方案：本次发布为“弃用版”）
- 代码状态：`main`，工作树干净（提交以 `git log -1` 为准）
- 结论：**门禁通过，可发布**；仅缺 pub 凭证

## 版本

| 包 | 版本 | 包 | 版本 |
| --- | --- | --- | --- |
| core | 2.4.0 | app | 1.2.0 |
| async | 2.1.0 | toast | 1.3.0 |
| ui | 4.7.0 | map | 1.3.1 |
| form | 3.2.0 | qr | 1.1.0 |
| api | 2.0.0 | cli | 1.9.10 |
| figma | 0.11.0 | device | 0.1.2 |
| e2e | 0.1.1 | 根包 | 4.0.0 |

## 门禁结果

| 检查 | 结果 |
| --- | --- |
| `dart format --set-exit-if-changed` | 0 漂移（410 文件） |
| `dart analyze` | 0 issues |
| `scripts/check_docs.sh` | 通过 |
| `scripts/check_style_literals.py` | 通过 |
| `scripts/check_deprecations.py` | 0 缺失、0 到期未删 |
| `scripts/check_feedback.sh` | 通过 |
| `scripts/release_check.sh` | 0 错误、0 提醒 |
| 包测试（core/async/ui/form/api/app/toast/map/qr/cli/figma/device/e2e） | 约 1550 条全绿 |
| example 测试（8 个包） | 全绿 |
| 根契约 | 14 ✓ |
| 13 个子包 `publish --dry-run` | 全 OK |
| 根包 dry-run | 子包上线后已通过（0 warning） |
| LICENSE / README / CHANGELOG | 13 个包齐全；CHANGELOG 顶部版本与 pubspec 一致 |
| 暂存副本 | `workspace` / `resolution` 已移除；`test/`、`docs/` 排除；`example/` 保留 |
| pub 凭证 | 本机缺失（`~/.config/dart/pub-credentials.json`） |

## 发布进度（检查时 pub.dev）

| 状态 | 包 |
| --- | --- |
| 已发布到目标版本 | core 2.4.0、async 2.1.0、ui 4.7.0、form 3.2.0、api 2.0.0、app 1.2.0、toast 1.3.0、map 1.3.1、qr 1.1.0、cli 1.9.10、figma 0.11.0、device 0.1.2 |
| 待发布 | e2e 0.1.1（0.1.0 已存在，本次有修复）、根包 4.0.0 |

## 发布后验证（已完成）

| 检查 | 结果 |
| --- | --- |
| e2e / 根包版本 | pub.dev：e2e 0.1.1、w_tools 4.0.0（其余 12 包均到目标版本） |
| 子包消费方（pub.dev 依赖） | `flutter pub get` ✓，`flutter analyze` 0 issue |
| 根包消费方（`w_tools: ^4.0.0`） | 解析到 w_tools 4.0.0 + 9 个子包目标版本，`analyze` 0 issue |
| `dart pub deps` | 无 `workspace` 残留 |
| 缓存问题 | 本机 `PUB_HOSTED_URL` 指向镜像，首次验证看不到新版本；显式 pub.dev + 新 `PUB_CACHE` 后通过 |

## 发布形态冒烟

用 `scripts/publish_package.sh <pkg> --stage-only` 生成 9 个包的暂存副本，临时 app 以
`path:` + `dependency_overrides` 指向它们，执行 `flutter pub get && flutter analyze`。

- 首次冒烟发现：`WApiConfig.baseOptions` / `DioRegistry.dio` 使用 dio 类型，但 barrel 未重导出，
  消费方被迫额外依赖 dio；
- 已修：`w_tools_api` 重导出 `BaseOptions` / `Dio` / `Response` / `Options` / `Interceptor` 等，
  冒烟 app 随后 `analyze` 0 issue；api 测试 52 条通过。

## 发布顺序

```bash
git push

bash scripts/publish_package.sh packages/core
bash scripts/publish_package.sh packages/ui
bash scripts/publish_package.sh packages/async
bash scripts/publish_package.sh packages/toast
bash scripts/publish_package.sh packages/form
bash scripts/publish_package.sh packages/api
bash scripts/publish_package.sh packages/app
bash scripts/publish_package.sh packages/map
bash scripts/publish_package.sh packages/qr
bash scripts/publish_package.sh packages/cli
bash scripts/publish_package.sh packages/figma
bash scripts/publish_package.sh packages/device
bash scripts/publish_package.sh packages/e2e

# 13 个子包全部上线后
bash scripts/publish_package.sh .
```

## 发布后验证

```bash
# 消费方 / 冒烟 app
flutter pub get
dart pub deps     # 无 workspace 残留
flutter analyze
```

- 检查 pub.dev 上 13 个包的版本与 README 渲染；
- 按 [`docs/releasing.md`](../releasing.md) 跑 qr / map 真机 checklist；
- 根包发布后再次 `pub get`，确认 `^x.y.z` 约束解析到刚发布的子包版本。

## 已知遗留（不阻塞本次发布）

- api 401 重试的隐式 registry 所有权（结构性，P2）；
- ui `image.dart` 拆分、`WRowButtons` 删除（5.0）；
- map `zoneId`/`name` 清理、qr `flipCamera` 重建回退；
- app 三套配置入口的三重回退（2.0 收敛）；
- golden 基础设施、feedback 复盘。

详见 [`docs/analysis/2026-11-03-remediation-plan.md`](../analysis/2026-11-03-remediation-plan.md) §8.1。

## 增量（发布后 P2）

| 包 | 版本 | 内容 |
| --- | --- | --- |
| api | 2.1.0 | 401 重试只复用已知 Dio：registry 自动绑定；裸 `Dio()` 需传 `dio:`，不再隐式注册（✅ 已发布） |
| ui | 4.7.1 | 内部重构：`image.dart` 拆分（公开 API 不变，✅ 已发布） |
| 根包 | 4.0.1 | 抬高 `w_tools_api` 约束到 `^2.1.0`（✅ 已发布） |

发布命令：

```bash
bash scripts/publish_package.sh .   # 根包 4.0.1；已完成
```

## 增量发布后验证

- pub.dev：`w_tools_api 2.1.0`、`w_tools_ui 4.7.1`、`w_tools 4.0.1`；
- 根包消费方（`w_tools: ^4.0.1` + pub.dev）：`pub get` ✓、`analyze` 0 issue；
- `dart pub deps`：无 `workspace` 残留。
