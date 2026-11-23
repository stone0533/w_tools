# w_tools_form 反馈

## 待处理

### [待处理] form: WFormFieldShell 的 Focus 包装抢走 Tab / next 焦点，键盘落到不可输入的壳上

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward（dependency_overrides 指到本地 w_tools）
- 命令 / 输入：两个 WFormTextField + TextInputAction.next；flutter test 里 Tab / receiveAction 模拟

```dart
WForm(
  controller: form,
  child: const Column(children: [
    WFormTextField(name: 'a', hintText: 'A', textInputAction: TextInputAction.next),
    WFormTextField(name: 'b', hintText: 'B'),
  ]),
)
// flutter_test：
await tester.showKeyboard(find.byType(TextField).first);
await tester.testTextInput.receiveAction(TextInputAction.next);
```

- 期望：按键盘「下一项」或 Tab 后焦点直接落到第二个输入框，键盘保持。
- 实际：`receiveAction(next)` 后 `testTextInput.isVisible` 从 true 变 false；primaryFocus 的 context 是 `Focus`，其祖先 `WFormFieldShell.name == 'b'`，不是 b 的输入框。Tab 从 a 出发要按 2 次才进 b（第一次落到 b 的壳）；把 b 的 `enableFocusBorder: false` 后只需 1 次，说明多出来的焦点站就是 `WFormFieldShell` 里包 child 的 `Focus`。
- 影响：页面里第一个 `textInputAction: next` 字段一按「下一项」键盘就收起，用户必须再点第二个字段；桌面 / Web 每个字段多一个不可见焦点站，键盘 / 读屏用户会以为字段已聚焦但输入无效。form example 的 `profile_page.dart` 昵称字段正好用了 next。
- 建议：`WFormFieldShell.build` 里包 child 的 `Focus(onFocusChange: _onFocusChange)` 加 `skipTraversal: true`（仍能收到后代焦点变化），或 `canRequestFocus: false`；补「Tab / next 一步到下一字段」的回归测试（现有 `field_focus_test.dart` 只测 `field.focus()`）。
- 复现数据：tabsToB=2（默认）/ 1（enableFocusBorder: false）；next 后 keyboard=false，primaryFocus 在 shell b

```text
focusBorderA=true focusBorderB=true  tabsToB=2
focusBorderA=true focusBorderB=false tabsToB=1
keyboard before: true
keyboard after: false
primary in shell: b
```
对应代码：`packages/form/lib/src/components/border/field_shell.dart`（`Focus(onFocusChange: _onFocusChange, child: child)`）。
- 状态变更：2026-11-23 待处理

### [待处理] form: WFormFieldStyleScope 只传 height 时会整体丢掉页面 fieldStyle（padding/文字/占位样式）

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward（dependency_overrides 指到本地 w_tools）
- 命令 / 输入：页面 fieldStyle + WFormFieldStyleScope(height: 72)，读 TextField.style / hint / rect

```dart
const page = WFormFieldStyle(
  height: 40,
  containerPadding: EdgeInsets.symmetric(horizontal: 16),
  textStyle: TextStyle(fontSize: 17, color: Color(0xFF123456)),
  placeholderStyle: TextStyle(fontSize: 17, color: Color(0xFF654321)),
);
WForm(controller: form, fieldStyle: page, child: Column(children: [
  const WFormTextField(name: 'a', hintText: 'A'),
  WFormFieldStyleScope(
    style: const WFormFieldStyle(height: 72), // catalog / README 的多行字段示例
    child: const WFormTextField(name: 'b', hintText: 'B', maxLines: 3),
  ),
]));
```

- 期望：单字段 scope 只覆盖 `height`，其余（containerPadding / textStyle / placeholderStyle）沿用页面 `WForm(fieldStyle:)`；至少文档说明这是整体替换。
- 实际：`WFormFieldStyle.of(context)` 返回最近 scope 的 style，不做合并；scoped 字段的 `TextField.style` / `hintStyle` 变成 null，左边缘从 16 变 0。catalog 里 `WFormFieldStyleScope` 的示例只有 `height: 72`，照抄就会丢页面样式，且不报错。
- 影响：只要某字段改高度（多行文本、搜索框、紧凑行），就得把页面 style 的 4 个字段全部复制一遍；漏一个就是静默视觉错误。消费方目前就是这么绕的：`lib/app/ui/app_form.dart` 的注释写「作用域会整体遮住页面的 WForm(fieldStyle:)，未覆盖的项要显式沿用」，`lib/app/modules/component/app_search_bar.dart` 也确实复制了全部字段。
- 建议：给 `WFormFieldStyle` 增加 `copyWith` / `merge`，并让 scope 支持显式 `mergeWithParent: true`（或反过来把「整体替换」写进 catalog / README / 类注释，并在示例里给完整写法）；`style: null` 的现有「清空页面样式」用法要保留。
- 复现数据：scoped textStyle / hintStyle = null；a.left=16，b.left=0

```text
page field style: TextStyle(fontSize: 17, color: #123456) hint: TextStyle(fontSize: 17, color: #654321)
scoped field style: null hint: null
a rect: Rect.fromLTRB(16.0, 7.0, 784.0, 33.0)
b rect: Rect.fromLTRB(0.0, 64.0, 800.0, 88.0)
```
对应实现：`packages/form/lib/src/components/form_field_style.dart`（`of` 直接返回最近 scope）。
- 状态变更：2026-11-23 待处理

### [待处理] form: WFormDatePicker 空值打开后直接点 OK 不写值（initialDate=null），且无法从 UI 清空

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：空 WFormDatePicker 打开 showDatePicker，直接点 OK

```dart
WForm(
  controller: form,
  child: const WFormDatePicker(name: 'birthday', hintText: '生日'),
)
// 打开空字段的日期弹窗，什么都不选，直接点 OK
await tester.tap(find.text('生日'));
await tester.pumpAndSettle();
await tester.tap(find.text('OK'));
await tester.pumpAndSettle();
expect(form.value['birthday'], isNull); // 当前实际
```

- 期望：空日期字段打开时默认选中今天（并 clamp 到 firstDate/lastDate），点 OK 写入今天；或者至少 OK 不可点 / 有明确提示。既然是可选的日期字段，还应能清空已选日期。
- 实际：`WFormDatePickerCore.openPicker` 把 `initialDate: initDate` 直接传给 `showDatePicker`，空字段时 initDate 是 null；Flutter 3.44 的 DatePickerDialog 在 initialDate 为 null 时 `_selectedDate` 也是 null，点 OK 会 `Navigator.pop(context, null)`，弹窗关闭但字段值仍是 null、没有错误提示。弹窗头部显示 "Select date"（未选中）。有 `initialValue` 时正常。
- 影响：用户想选「今天」直接点 OK，界面关闭但值没写入，提交时日期为空且不知道哪里错了；`firstDate` 在未来的字段（生日上限、预约日期）同样中招。现有测试 `form_lifecycle_test.dart: 日期字段 firstDate 在未来时也能打开选择器` 只断言弹窗打开，没有断言 OK 后写值。
- 建议：`initialDate: initDate ?? _clamp(DateTime.now(), firstDate, lastDate)`；补「空字段 → OK → 写入今天」和「firstDate 在未来 → OK → 写入 firstDate」的断言。清空能力可同时考虑：字段级 clear action 或日期弹窗加「清除」（当前只能 `resetValue` / `setValue(null)`，UI 没有入口）。
- 复现数据：dialog 打开后点 OK → form.value = {birthday: null}；有 initialValue 时正常

```text
dialog open: 1
OK count: 1
dialog after OK: 0
form.value: {birthday: null}
```
相关测试（现有）会打印 tap 命中警告：`form_lifecycle_test.dart` 里 `tester.tap(find.text('未来'))` 没有真正命中 hint，只是弹窗仍被打开。
- 状态变更：2026-11-23 待处理

### [待处理] form: WForm(readOnly:true) / 字段 readOnly 实际设成 enabled:false，只读内容无法聚焦/选中/复制

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：WForm(readOnly:true) + WFormTextField，读内部 TextField 并 tap

```dart
WForm(
  controller: form,
  readOnly: true,
  child: const WFormTextField(name: 'name', hintText: '姓名', initialValue: '张三'),
)
// 读取内部 TextField，并尝试聚焦
final tf = tester.widget<TextField>(find.byType(TextField));
// tf.enabled == false, tf.readOnly == true
await tester.tap(find.byType(TextField));
// focusNode.hasFocus == false; controller.selection == TextSelection.invalid
```

- 期望：只读字段仍可聚焦、选中、复制（Flutter `TextField.readOnly: true` 的语义），只是不能编辑；详情页的只读邮箱 / 卡号 / 订单号可以长按复制。
- 实际：`text_field.dart` 里 `isEnabled = widget.enabled && !inheritedReadOnly`，然后把 `enabled: isEnabled` 传给 `FormBuilderTextField`；`WForm(readOnly: true)` 和字段级 `readOnly: true` 都会走到 `enabled=false, readOnly=true`。点击不聚焦、长按无法选择，和 `enabled: false` 的禁用态无法区分。
- 影响：只读详情页 / 确认页无法复制字段内容；读屏也会按 disabled 处理。项目里 `memberEdit` 的邮箱、`mCardExchangeDetail` 的会员编号都用只读展示。
- 建议：只读时保持 `enabled: true` + `readOnly: true`（Flutter 只读输入不会弹键盘），把 `enabled: false` 留给真正禁用；如果禁用态视觉依赖 `readOnlyDecoration`，可以拆成独立的 disabled 配置。补一个「只读字段可聚焦 / 可选中」的测试。
- 复现数据：enabled=false, readOnly=true；focused=false、selection=TextSelection.invalid

```text
enabled=false readOnly=true
selection: TextSelection.invalid focused=false
```

- 状态变更：2026-11-23 待处理

### [待处理] form: 固定 fieldStyle.height 时原生 validate/autovalidate 错误文案画进字段内，遮住输入并裁掉 hint

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：fieldStyle.height=40 + autovalidateMode / formKey.validate()

```dart
WForm(
  controller: form,
  fieldStyle: const WFormFieldStyle(height: 40, containerPadding: EdgeInsets.symmetric(horizontal: 16)),
  autovalidateMode: AutovalidateMode.onUserInteraction, // 或 form.formKey.currentState!.validate()
  child: WFormTextField(
    name: 'email',
    hintText: '请输入邮箱',
    validator: (_) => '邮箱格式不正确，请重新输入',
  ),
)
```

- 期望：固定高度 40 时，校验错误文案仍然在字段外（边框下方）显示，输入内容不被裁切。
- 实际：`WFormTextField` 的 `rendersInlineError: true` 让 `WFormBorder` 跳过错误文案，交给 `InputDecoration` 在 40px 内渲染。实测 hint rect 是 `(20,-4)-(780,20)`、error rect 是 `(20,20)-(168.8,36)`，字段本身是 `(16,0)-(784,40)`：hint 被推到字段外上方，error 占掉输入区；渲图里第一行文字在上边框被切掉、错误文案盖在输入位置上。`autovalidateMode` 和 `formKey.currentState!.validate()` 都会触发（catalog 只写了「不要同时用 formKey.validate」）。
- 影响：任何按设计稿固定 40 高度的表单，一旦用 `WForm.autovalidateMode` 或原生 `formKey.validate()`，错误态直接视觉损坏；用户看不清自己输入了什么，也看不出错误文案和输入的关系。
- 建议：固定 `height` 时改走边框错误通道（让直接字段按 height 决定 `rendersInlineError`），或把错误布局到 `WFormFieldFrame` 之外；至少文档明确「fixed height + 原生 validate 不兼容」。补一个带 rect 断言的回归测试（现有 `autovalidateMode` 测试只断言属性透传）。
- 复现数据：hint y=-4..20，error y=20..36，field 0..40

```text
field a: Rect.fromLTRB(16.0, 0.0, 784.0, 40.0)
hintRect: Rect.fromLTRB(20.0, -4.0, 780.0, 20.0)
errorRect: Rect.fromLTRB(20.0, 20.0, 168.8, 36.0)
```
（40 高 + 红色 error 边框；测试跑完因原生 validate 默认聚焦 + 光标闪烁，`pumpAndSettle` 会一直转，需要 `pump` 而不是 `pumpAndSettle`。）
- 状态变更：2026-11-23 待处理

### [待处理] form: WFormMultiDropdown 弹层选项行高只有 24，且公开字段没有 itemPadding 等入口

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：WFormMultiDropdown 4 个短选项，打开弹层量每个选项 rect

```dart
WForm(
  controller: form,
  child: const WFormMultiDropdown<String>(
    name: 'tags',
    hintText: '标签',
    items: {'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D'},
  ),
)
await tester.tap(find.text('标签'));
await tester.pumpAndSettle();
// 实测每个选项 Text 的 rect 高 24（A: (32,50)-(46,70)，B: (32,74)-(46,94)…）
```

- 期望：弹层选项行至少 48 高（或可通过直接字段参数加 padding），符合项目里按钮 48 点击下限的约定。
- 实际：`_WFormMultiDropdownItem` 的 Container 没有默认 padding，行高就是复选框图标 24；同时 `WFormMultiDropdown` 直接字段没有转发内部 core 已有的 `itemPadding` / `itemTitlePadding` / `popUpLayerPadding` / `popUpLayerElevation` / `popUpLayerShadowColor` / `decoration`，公开 API 无法调整行高或弹层外观。
- 影响：移动端多选弹层每一行只有 24px，手指容易点到相邻项；想修只能绕开直接字段、或用外框 padding hack，但这些参数明明在 core 里存在。与 `WButtonSize.tapTargetSize=48`、`WFormFieldShell` 的焦点/无障碍投入不一致。
- 建议：选项默认加垂直 padding 到 48（或至少 40），并把 `itemPadding` / `itemTitlePadding` / 弹层参数透传到直接字段；补「选项行高 >= 48」的布局测试。
- 复现数据：每个选项高 24（A 50..70，B 74..94…）；直接字段没有 itemPadding

```text
A: Rect.fromLTRB(32.0, 50.0, 46.3, 70.0)
B: Rect.fromLTRB(32.0, 74.0, 46.3, 94.0)
C: Rect.fromLTRB(32.0, 98.0, 46.3, 118.0)
D: Rect.fromLTRB(32.0, 122.0, 46.3, 142.0)
popup region: Rect.fromLTRB(0.0, 48.0, 400.0, 144.0)
```

- 状态变更：2026-11-23 待处理

### [待处理] form: WFormTextField.maxLength 的计数器超出固定高度字段，压到下边框/下一元素

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：fieldStyle.height=40 + maxLength: 6，量计数器 rect

```dart
WForm(
  controller: form,
  fieldStyle: const WFormFieldStyle(height: 40, containerPadding: EdgeInsets.symmetric(horizontal: 16)),
  child: const WFormTextField(name: 'code', hintText: '验证码', maxLength: 6),
)
```

- 期望：`maxLength` 的 `0/6` 计数器可见且不越界；固定高度时应把计数器算进高度，或放到边框消息区。
- 实际：字段 rect 是 `(0,0)-(800,40)`，计数器 `0/6` 的 rect 是 `(758.8,28)-(796,44)`，底部超出 4px；渲图里计数器压在字段下边框上，和下一个元素重叠。`maxLength` 是 7.0 新增的直接参数，catalog 只写了 `maxLines` 需要加高，没有提计数器。
- 影响：设计稿固定 40 的验证码 / 手机号 / 昵称等字段，计数器会盖住边框或下一行；因为不抛异常，review 很容易漏。
- 建议：固定 `height` 时把计数器渲染到边框消息区（或 `InputDecoration.counterText` 放进 `hint/error` 区），或提供 `buildCounter` 入口 / 文档要求 `maxLength` 字段额外加高。补一个 rect 断言（当前 `form_gaps_test.dart` 只断言 `field.maxLength == 5`）。
- 复现数据：counter 28..44，field 0..40，底部超出 4px

```text
counter found: 1
counter rect: Rect.fromLTRB(758.8, 28.0, 796.0, 44.0)
field rect: Rect.fromLTRB(0.0, 0.0, 800.0, 40.0)
```

- 状态变更：2026-11-23 待处理

### [待处理] form: 字段回填：initialValue 变更不更新字段但会更新 action 状态；setValue 挂载前静默丢失

- 包/版本：w_tools_form 8.1.0（本地 main 6e5423d）
- 环境：macOS / Flutter 3.44.9 / Dart 3.12.2；消费方 ureward
- 命令 / 输入：A: initialValue null→abc rebuild；B: 挂载前 setValue

```dart
// A. 首帧空、数据到了以后 rebuild 传 initialValue
Widget build(String? initial) => WForm(
  controller: form,
  child: WFormTextField(
    name: 'q',
    hintText: '搜索',
    initialValue: initial,
    actions: const [WFormTextFieldClearButton()],
  ),
);
await tester.pumpWidget(build(null));
await tester.pumpWidget(build('abc'));
// TextField.controller.text == ''，form.value['q'] == null，但清空按钮出现了

// B. 挂载前 setValue
final form = WFormController();
form.setValue('q', 'abc'); // 静默 no-op
await tester.pumpWidget(build('abc')); // 值仍为空
```

- 期望：异步数据回填有确定的入口（挂载前 `setValue` 排队，或 `initialValue` 变更同步字段值），且 `WFormTextFieldClearButton` 的可见性与字段真实值一致。
- 实际：A 中 `_WFormTextFieldState._valueNotifier` 在 `didUpdateWidget` 随 `initialValue` 更新，所以清空按钮出现；但 `FormBuilderField.initialValue` 只在 initState 读取，TextField 文本和表单值仍是空。B 中 `WFormController.setValue` 在 `formKey.currentState == null` 时直接 `return`（`_assertFieldExists` 也因未挂载跳过），不报错、不缓存。
- 影响：常见「先渲染表单、接口返回后 rebuild」的页面回填失败；用户能看到清除按钮但输入框是空的，点一下清空还没效果。GetX / 缓存同步返回时，`onInit` 里的 `setValue` 会静默丢数据；排查成本很高。
- 建议：文档明确 `initialValue` 只在首次挂载生效，异步回填用 `setValue`；`setValue` 未挂载时 assert 或先把值缓存在 controller、挂载后 replay；同时让 `_valueNotifier` 与字段值同步（initialValue 变更时不要把 action 状态单独改掉）。可考虑 `WForm(initialValues: ...)`。
- 复现数据：A: text=""、value=null 但清空按钮出现；B: 挂载后仍为 null

```text
initial null: clear visible=0
after rebuild initial='abc': text="" value={q: null} clear visible=1
setValue before mount: value after mount={q: null} controller text=""
```

- 状态变更：2026-11-23 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
