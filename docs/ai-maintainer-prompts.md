# 维护者 AI 提示词手册

本文给 **w_tools 包维护者**使用：改代码、加组件、删 API、加包、整理目录时，直接复制对应提示词给 AI。

配套规则见 [`docs/ai-contract.md`](ai-contract.md)。

---

## 0. 固定前缀（每次先贴）

```text
你是 w_tools 的维护者，先读 docs/ai-contract.md、AGENTS.md 和
packages/<pkg>/README.md，再开始。

硬约束：
1. 先判断这是内部改动，还是公开 API / 行为变化。
2. 不要手改生成物：catalog.g.dart / templates.g.dart / components.md。
3. 不要为了让检查通过而降低测试、契约或文档标准。
4. 新增公开类型优先登记 catalog；不要直接塞进 uncataloged.yaml，除非说明它只是子 API。
5. 必须实际运行命令并贴结果；不能运行就明确说没运行，不要声称通过。
6. 不要改无关包、无关文档、无关测试。
7. 最后报告 changed files、实际命令结果、explain 输出、剩余风险。
```

然后从下面选一个任务块贴在后面。

---

## 1. 场景选择

| 你的改动 | 用哪个 |
|---|---|
| 私有方法、性能、内部重构 | A |
| 改现有公开组件 / API / 行为 | B |
| 新增公开组件 | C |
| 删除 / 废弃公开 API | D |
| 新增包 | E |
| 只整理 catalog / AGENTS / 文档 | F |
| 只让 AI 审查，不要改 | G |
| AI 不能访问仓库 / 不能跑命令 | H |

---

## A. 内部重构 / Bug 修复

适用：

```text
私有实现、性能、日志、内部命名
公开 API 和默认行为不变
```

```text
任务：对 <包/文件> 做内部重构 / 修 bug。

要求：
1. 先说明为什么这是内部改动：哪些 public API 和默认行为没有变。
2. 只改必要代码 + 测试。
3. 如果发现确实有公开行为变化，停下来，改用场景 B。
4. 不要改 catalog / AGENTS / README / example。
5. 运行该包测试和全仓 preflight。
6. 报告 changed files、为什么不需要文档更新、测试结果。
```

---

## B. 修改现有公开组件 / API / 行为

适用：

```text
改方法签名
改默认行为
改输入/输出
新增可选参数
新增公开方法
```

```text
任务：修改 <包/组件/API>，原因是 <...>。

要求：
1. 先列清楚公开变化：API、默认行为、错误语义。
2. 代码 + 测试。
3. 更新 catalog/components.yaml：
   - usage
   - pitfalls
   - related
   - aliases（保留旧名时）
   - teach（入口组件必须）
4. 更新对应 AGENTS 模板，确保不再推荐旧写法。
5. 更新 README；必要时更新 example。
6. 如果是 breaking，写 migration，并检查 docs/migrations/README.md。
7. 先改源文件，再跑：
   cd packages/cli
   dart run tool/gen_catalog.dart
   dart run tool/gen_templates.dart
8. 运行 explain <组件> --format=prompt，贴输出。
9. 运行 preflight --with-tests，贴结果。
```

---

## C. 新增公开组件

```text
任务：新增组件 <WXxx>，包是 <pkg>。

要求：
1. 先判断它是 teach 入口还是普通组件，并说明理由。
2. 实现 + 测试；如果需要 async / 状态，先查 async 规则。
3. 在 catalog/components.yaml 增加：
   - name / package / section
   - useFor / dontUseFor
   - teach（入口组件）
   - usage / pitfalls / related（teach 时）
   - aliases（有方法名查询需求时）
4. related 优先指向已有 catalog 组件；子 API 才考虑 uncataloged 基线。
5. 如果影响包级规则，更新 AGENTS 模板。
6. 更新 README；有真实场景就更新 example。
7. 跑生成器、ai_contract、cli 测试、preflight。
8. 用 explain <WXxx> --format=prompt 自测。
```

---

## D. 删除 / 废弃公开 API

```text
任务：删除或废弃 <包/API>，替代方案是 <...>。

要求：
1. 代码层删除或加 deprecated，写清 remove-in。
2. catalog：
   - 删除条目，或调整 usage / pitfalls / aliases；
   - 清理 related 中指向旧 API 的引用。
3. AGENTS 不能继续推荐旧入口。
4. README / migration / example 更新。
5. 运行 check_removed_api / check_public_catalog / preflight。
6. 如果只是 deprecated，明确告诉 AI 现在应该用什么。
```

---

## E. 新增包

```text
任务：新增包 <w_tools_xxx>，用途是 <...>。

要求：
1. 加入根 workspace 和根约束（如果属于聚合范围）。
2. pubspec / CHANGELOG / README / LICENSE / .pubignore。
3. 有真实入口就加 example，并加 smoke test。
4. catalog 增加入口组件；入口组件 teach: true。
5. 如果是 init feature，加 templates/agents/{zh,en}/<feature>.md 和 features.dart 映射。
6. 更新 context.capabilities、docs/modules/README.md、docs/release。
7. 跑 gen_templates / gen_catalog / check_public_catalog / preflight。
8. 报告发布顺序和依赖关系。
```

---

## F. 只整理 catalog / AGENTS / 文档

```text
任务：只整理 <catalog / AGENTS / README / docs>，不改业务代码。

要求：
1. 先确认不涉及公开 API 或行为变化。
2. 只改源文件：
   - catalog/components.yaml
   - templates/agents/**
   - README / docs
3. 不要手改生成物。
4. 跑：
   - gen_catalog
   - gen_templates
   - ai_contract
   - check_docs
   - check_public_catalog
5. 报告改了哪些事实、哪些是生成结果。
```

---

## G. 只审查，不要修改

```text
任务：审查本次改动，不要改任何文件。

请检查：
1. 是否有公开 API / 行为变化被漏掉？
2. catalog 的 usage / pitfalls / related / aliases 是否完整？
3. AGENTS 是否还推荐旧入口？
4. README / example 是否跟得上？
5. 是否有生成物被手改？
6. 是否有测试被削弱？
7. 运行 preflight --with-tests 并贴结果。

输出：
- 阻断问题
- 建议修复
- 可以保留的风险
- 相关文件路径
```

---

## H. AI 不能访问仓库 / 不能跑命令

```text
你不能直接访问仓库或运行命令。

请基于我提供的文件片段工作，并明确标注：
1. 哪些结论来自我贴的内容；
2. 哪些需要我运行命令确认；
3. 不要声称 preflight 已通过。

我提供：
- 改动 diff
- 相关 catalog 条目
- 相关 README 段落
- 测试输出
```

---

## 2. 提示词使用示例

### 改 WAsync 的超时行为

固定前缀 + 场景 B，把：

```text
<包/组件/API> → w_tools_async / WAsync.timeout
<...> → 超时错误需要显式区分
```

### 新增 WAsync 的 retry 辅助

固定前缀 + 场景 C，把：

```text
<WXxx> → WAsyncRetry
<pkg> → w_tools_async
```

### 删除 WImage 旧构造器

固定前缀 + 场景 D，把：

```text
<包/API> → w_tools_ui / WImage.network
<...> → WImageSource.network
```

---

## 3. AI 完成后你必须检查

```text
[ ] git diff 没有大范围无关改动
[ ] catalog 改的是 components.yaml，不是 catalog.g.dart
[ ] AGENTS 改的是 templates，不是 templates.g.dart
[ ] 新公开类型已进 catalog 或 uncataloged 基线（并说明理由）
[ ] teach 组件有 usage / pitfalls / related
[ ] explain <组件> --format=prompt 输出正确
[ ] README / example 已更新
[ ] preflight --with-tests 实际通过
[ ] 没有削弱测试
```

重点看 `explain` 输出，而不是只看“preflight 通过”。

---

## 4. 为什么不是一条万能提示词

一条提示词同时要求：

```text
改代码 + 改 catalog + 改 AGENTS + 改 README
+ 改 example + 跑全仓门禁 + 审查
```

容易导致：

- AI 为了完成清单而改无关文件；
- 文档先于代码定稿，产生假事实；
- 测试被顺手改弱；
- 大 diff 难以 review。

所以推荐：

```text
固定前缀
+ 一个场景块
+ 一次只做一类任务
```

复杂改动拆成：

```text
第 1 轮：代码 + 测试
第 2 轮：catalog + AGENTS
第 3 轮：README + example
第 4 轮：preflight + 审查
```

---

## 5. 这是最合适的方式吗？

对**人机协作**来说，这是当前最合适的方式：

```text
文档化提示词
+ 固定硬约束
+ 场景化任务块
+ 机器门禁
```

但它不是“万能保证”。

真正兜底的是：

```text
catalog 契约测试
explain prompt 契约测试
AGENTS 模板检查
公开类型反向检查
preflight
```

提示词负责让 AI 做对方向，测试负责防止它悄悄做错。

---

## 6. 维护这份文档

当以下内容变化时，更新本文件：

- CLI 命令；
- catalog 字段；
- AGENTS 模板规则；
- 完整性检查命令；
- 发布 / migration 流程。

保持它和 [`docs/ai-contract.md`](ai-contract.md) 一致。

---

## 7. 一句话

**固定前缀 + 场景块 + 证据要求 + preflight。**

这就是给维护者使用 AI 的最合适方式。
