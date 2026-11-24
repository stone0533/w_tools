# w_tools_form 反馈

## 待处理

### [待处理] form: form 8.2：WFormFieldStyle.height 作为最小高度时，字段在有界父级里铺满整个高度（应为按内容收缩）

- 包/版本：w_tools_form 8.2.0（override 到本地检出，pub 8.2.0 同源）
- 环境：Flutter / macOS，项目 ureward_member_app；`flutter test` 375×812
- 命令 / 输入：`WForm` + `WFormFieldStyle(height: 40)` + `WFormTextField`（dart 片段见下）
  ```dart
  Scaffold(
    body: WForm(
      controller: WFormController(),
      fieldStyle: WFormFieldStyle(height: 40),
      child: WFormTextField(name: 'a', bordered: false),
    ),
  )
  ```
- 期望：字段高度 = max(40, 内容高度)，即 40（`heightIsMinimum` 的语义是「内容更高时才长高」）。
- 实际：`WFormFieldFrame` 高度 = 812（父级可用高度全占），TextField 在 812 高里垂直居中；`WFormFieldFrame` 尺寸 375×812，`Align` 343×812，`ConstrainedBox` 约束 `40<=h<=812`。
- 影响：字段放进**有界但非紧约束**的父级（Scaffold body、固定高 Container、bottom sheet 主体等）会被拉成整屏高，布局看起来像「字段不见了 / 表单中间一大片空白」。本项目的 OTP 输入框回归测试就是按 40.w 找字段容器而失败（`test/register/otp_field_padding_test.dart`）。真实页面里字段都在 SingleChildScrollView（无界高度）里，所以没炸，但这是个很容易踩的隐性契约。
- 建议：`lib/src/components/field_frame.dart` 的 `heightIsMinimum` 分支不要用 `Container(alignment: center, constraints: minHeight)`（Container 带 alignment 时内部 Align 会撑满 max 约束）。改成 `ConstrainedBox(minHeight: height) > Align(heightFactor: 1, child: ...)`（与 `WNavBar` 的最小高度写法一致），就能「按内容收缩、再被 minHeight 抬起」。
- 复现数据：`WFormFieldStyle(height: 40)` + `WFormTextField(bordered: false)`，375×812；`tester.getRect(WFormFieldFrame)` = 0,0,375,812。
- 状态变更：2026-11-24 待处理

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
