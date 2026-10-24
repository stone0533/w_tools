# 贡献指南（新增/修改组件）

> 判据先看 [`docs/conventions.md`](docs/conventions.md)：这个组件**该不该**进包。
> 这里只写「决定进包之后，必须带齐什么」。

## 1. 新增组件的四条硬性要求

缺任何一条都不要提交：

- [ ] **设计稿实测尺寸写进注释**：宽/高/圆角/颜色/行距/间距，以及「为什么是这个值」
- [ ] **默认值可用**：不传任何参数也能渲染出一个合理的组件
- [ ] **至少一个测试**：`packages/<pkg>/test/` 下的 widget 测试；像素敏感的加上 golden
- [ ] **`CHANGELOG.md` 条目 + 版本号**：子包与根包的 `^x.y.z` 约束要一起改
      （改完跑 `bash scripts/release_check.sh`）

## 2. 接口设计

通用原则见 [`docs/conventions.md`](docs/conventions.md) §6；这里只写最容易违反的两条：

- **参数 ≤ 3 个**：合成一个组件；**> 3 个**：说明它们是两个组件，不要硬合并
  （教训：一个 311 宽的弹窗壳，因为要塞内容/按钮/内边距/标题色，最后变成 4 个参数——
  正确的做法是「只共用壳，内容和按钮各自组装」）
- **布尔参数**要么全部默认 `false`，要么用一个 enum（避免 `type: true, compact: false` 这种调用点）

## 3. 文档

- 组件加进 [`docs/modules/components.md`](docs/modules/components.md) 的对应表格：
  **用来做什么 / 不要用在哪 / 引入版本**
- 「不要用在哪」比「怎么用」更有价值——误用是主要故障源
- 该子包的 `docs/modules/<module>_module.md` 补一段说明（如果有行为细节）
- 改完 `docs/` 后跑 `bash scripts/check_docs.sh`（链接、旧命令、包清单）

## 4. 测试要求

- 行为测试放 `packages/<pkg>/test/`，并在该子包 `dev_dependencies` 声明依赖
  （子包要能脱离仓库根独立 `flutter test` / 发布）
- 像素敏感组件（卡片、弹窗、图标对齐）加 **golden**：
  ```bash
  flutter test --update-goldens packages/ui/test/golden/xxx_test.dart
  ```
- 根 `test/` 只放聚合契约（`w.dart` 的重导出、`WConfig` 兼容层）
- `packages/cli` 是纯 Dart 包：用 `dart test`，不要引入 `flutter_test`

## 5. 发布

- 实际发布用 `bash scripts/publish_package.sh <包目录>`（根包用 `.`），
  **不要**在包目录直接 `flutter pub publish` —— `workspace:` 字段会被原样发布，
  消费方 `dart pub deps` 会失败
- 版本策略与流程见 [`docs/releasing.md`](docs/releasing.md)

## 6. 组件从「消费方暂存层」上移时

1. 确认满足上面四条
2. 把消费方 `lib/app/design_system/` 里的文件删掉，引用改成 `package:w_tools_ui`
3. 该消费方的 `toolkit.dart`（聚合入口）里加一行 `export`
4. 在消费方的 issue/PR 里注明「已上移」，并更新它的 `docs/agents/w_tools.md` 待上移清单
