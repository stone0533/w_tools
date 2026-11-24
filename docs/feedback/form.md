# w_tools_form 反馈

## 待处理

（暂无）

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-23 | WFormFieldShell 的 Focus 包装抢走 Tab / next 焦点，键盘落到不可输入的壳上 | ✅ 8.2.0：`Focus(skipTraversal: true)`；Tab / `TextInputAction.next` 一步进入下一字段，补回归测试 |
| 2026-11-23 | WFormFieldStyleScope 只传 height 时整体丢掉页面 fieldStyle | ✅ 8.2.0：新增 `mergeWithParent` + `copyWith`；默认整体替换写成文档与示例；`WForm(fieldStyle: null)` 不再清空外层作用域 |
| 2026-11-23 | WFormDatePicker 空值打开后点 OK 不写值，且无法从 UI 清空 | ✅ 8.2.0：空值默认选中今天（clamp 到区间）；新增 `clearable` |
| 2026-11-23 | WForm(readOnly: true) / 字段 readOnly 实际设成 enabled: false | ✅ 8.2.0：文本字段只读保持可聚焦 / 复制；非文本只读的禁用态语义写入文档（统一方案待产品决策） |
| 2026-11-23 | 固定 fieldStyle.height 时原生 validate 错误文案画进字段内 | ✅ 8.2.0：文本 / 下拉的 height 改为最小高度，错误 / 多行撑高字段 |
| 2026-11-23 | WFormMultiDropdown 选项行高 24，且没有 itemPadding 等入口 | ✅ 8.2.0：默认行高 48；转发 `itemPadding` / `itemTitlePadding` / 弹层参数 / `decoration` |
| 2026-11-23 | WFormTextField.maxLength 计数器超出固定高度字段 | ✅ 8.2.0：最小高度下计数器留在字段内，补 rect 断言 |
| 2026-11-23 | 字段回填：initialValue 变更不更新字段但更新 action 状态；setValue 挂载前静默丢失 | ✅ 8.2.0：initialValue 不再单独改 action 状态；setValue 挂载前断言；文档写明异步回填用 setValue |
| 2026-11-24 | `WFormFieldStyle.height` 作为最小高度时，字段在有界父级里铺满整个高度 | ✅ 8.2.1：`ConstrainedBox(minHeight)` + `Align(heightFactor: 1)`；有界父级按内容收缩，补 375×812 回归 |
