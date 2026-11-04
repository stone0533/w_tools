> 分析记录：带日期的历史评审，不代表当前状态。

# w_tools 全仓代码评审（2026-11-03）

> 基线：`main` @ `38d54b0`，工作区干净。方式：**只读评审**，未修改任何代码。
> 范围：聚合包 `w_tools` + 9 个运行时子包（core / async / ui / form / api / app / toast / qr / map）
> + 4 个工具包（cli / figma / device / e2e）。
> 维度：是否臃肿、功能是否合理、是否正确、命名是否合理、不考虑兼容是否该重构、开发者是否易用。

## 0. 基线

```text
git status                     → clean，main 与 origin/main 一致
git log --oneline -5           → 38d54b0 feat(cli): manifest 记生成器版本 …（1.9.9）
bash scripts/release_check.sh --online
                              → 14 个包版本 / CHANGELOG / 根约束 / pub.dev 状态全部 ✓，0 提醒
dart analyze（Flutter 3.44.9）  → 1 info：form/popup.dart:195 使用已弃用的 axisAlignment
```

| 项 | 数量 | 备注 |
| --- | --- | --- |
| 运行时子包 `lib/` | 27,342 行 | 9 个包 |
| 生成代码 | 2,223 行 | 仅 cli 的 `templates.g.dart` / `catalog.g.dart` |
| 测试 | 23,013 行 | 103 个测试文件，测试/代码 = 0.84 |
| 文档 | 7,900 行 | 文档/代码 = 0.29，另有 4 条 ADR |
| 公开类型 | 214 个 | ui 89 / form 60 / async 18 / core 18 / api 9 / app 7 / map 7 / qr 4 / toast 2 |

评审过程：我读了全部 14 个包的入口、公开 API 与关键实现（core / async / api / app / cli 为主要自读），
另用 3 个并行只读评审做了 ui、form+toast+qr+map、tooling 的深审。下文每条都带 `file:line` 证据；
标「推断」的是代码推演而非运行验证（本次没有跑 Flutter 测试，原因见 §9.2）。

## 1. 结论

1. **工程骨架是一流水准**：workspace 单次解析、子包独立发版、`publish_package.sh` 的暂存副本、
   doctor 的 R1~R9、反馈闭环脚本、文档密度。这部分不用动。
2. **代码不脏**：analyze 只有 1 条 info，注释密度高，异常语义（`Error` vs `Exception`）、
   生命周期、取消语义明显是认真设计过的。问题不是"写得糙"，是**同一个能力被做成了多套入口**。
3. **四个结构性冗余**（"臃肿"的真正来源）：
   - 同一字段三层公开入口：`WFormTextField` / `WFormTextFieldConfig().build()` / `WFormTextFieldCore`；
   - 同一配置三套载体：静态 `WFormDefaults` / `WFormTheme` / `WForm` 参数（8 个图标 × 3）；
   - 同一能力两套抽象：`WAsync`（执行器）与 `WAsyncController`（UI 状态）互不组合；
   - 同一检查两套实现：cli 的 `init` 与 `doctor` 各自维护路径、pubspec 解析与文本扫描。
4. **默认值偏离主题/不可用是最高频的真实缺陷**（违反自家 `docs/conventions.md` §6）：
   `WButton` 默认靛蓝、`WAppBar` 默认黑图标+正文字号、`WImage.avatar(style:)` 丢预设、
   **`WForm` 默认 `validate()` 失败时界面零反馈**、`WRowButtons` 点击必选中、`map` 空数据时相机在 (0,0)。
5. **设计系统只覆盖 ui 一个包**：`WText` / `WButton` 在 ui 之外**零使用**，form / toast / async
   各自写死字号与颜色（含 `Color(0xFF6B7280)`、`Colors.white`），跨包视觉必然漂移。
6. **包装层没包住**：`w_tools_form` 的 `WFormController.formKey` / `fields` 直接暴露
   `flutter_form_builder` 类型，却既没 re-export 也没在 README 声明 —— 消费者被迫自己加依赖。
7. **有一处高风险并发缺陷嫌疑**：`WTokenInterceptor` 收到 401 时**先无条件清 token**，再走
   single-flight 刷新，可能与刚完成的刷新竞争把新 token 清掉（P1-8，需补用例确认）。
8. **工具链的"单一真相"已经破了**：`catalog/components.yaml` 与 `docs/modules/components.md`
   实际漂移（docs 有 `WStepFlow`，catalog 没有，`explain WStepFlow` 查不到）；figma 的额度预算
   只展示不拦截；device 的标定缓存不随设备尺寸/方向失效。
9. **流程缺口**：CI 矩阵只跑 13 个包中的 9 个 —— `async`（1,719 行代码 + 1,923 行测试）与
   3 个工具包**完全没有 CI**；子包声明 `flutter >=3.27` 但只测 3.38。

**要不要重构？** 要，但**不是推倒重来**。包边界基本正确（§2.2），需要的是
「收敛入口 + 统一配置模型 + 让设计系统跨包可用 + 让工具链只有一份真相」。
这是**一个大版本内的结构性重构**（§6），不是重写：约 4,000–5,000 行公开面可净删而不损失行为。

## 2. 现状盘点

### 2.1 体量与最大文件

| 包 | lib 行 | 最大文件 | 公开类型 | 关键第三方依赖 |
| --- | --- | --- | --- | --- |
| ui | 6,999 | `common/image/image.dart` 827 | 89 | cached_network_image / badges |
| form | 5,352 | `fields/text_field.dart` 488 | 60 | flutter_form_builder / intl |
| core | 1,909 | `utils/reg_exp.dart` 358 | 18 | encrypt / crypto / logger / shared_preferences |
| async | 1,719 | `task/async_task.dart` 779 | 18 | 无（纯 Flutter） |
| app | 677 | `app.dart` 347 | 7 | get（GetX，不可替换） |
| api | 596 | `interceptors/token.dart` 225 | 9 | dio |
| qr | 555 | `qr_view.dart` 416 | 4 | qr_code_scanner_plus |
| map | 553 | `map.dart` 552（整包一个文件） | 7 | google_maps_flutter |
| toast | 476 | `toast_config.dart` 320 | 2 | bot_toast |

内部占比最失衡的三处：

- ui：图片子系统 **2,137 行（31%）** + 按钮子系统 **1,095 行（16%）** = 46%；
- async：`async_task.dart` **779 行（45%）**，其中约 300 行是 `WAsyncConfig` 对 `WAsync` 的逐方法转发；
- core：`reg_exp.dart` 358 + `validator.dart` 243 = **601 行（31%）**，两套正则常数互不同步（P2-1）。

### 2.2 依赖图：子包之间真的互不依赖

```text
w_tools（聚合，只 re-export 9 个包）
  ├─ core     encrypt crypto convert logger shared_preferences synchronized
  ├─ async    （无第三方）
  ├─ ui       cached_network_image badges
  ├─ form     flutter_form_builder form_builder_validators intl
  ├─ api      dio
  ├─ app      get
  ├─ toast    bot_toast
  ├─ qr       qr_code_scanner_plus
  └─ map      google_maps_flutter
```

`grep package:w_tools_*` 在 9 个包的 `lib/` 里**零命中**（33 处命中全在 cli 生成的模板字符串中）。
这是很好的性质（任意子包可单独发布/测试），但也直接导致 P1-9 的重复实现 ——
**独立性是靠设计系统的重复换来的**。这是本次评审最需要维护者拍板的取舍。

### 2.3 公开 API 面：widget : 配置/辅助 ≈ 1 : 2

- ui 89 个里有 **31 个与 `WImage` 相关**（5 个 Source 子类、8 个 Error 子类、Style/Config/Loader/Frame…）；
- form 60 个里有 **13 个与 border 相关**；6 个字段 × (`Xxx` + `XxxConfig` + `XxxCore`) = 18；
- 参数数：`WFormTextField` 23、`WForm` 15（含 8 个图标）、`WMapZone` 10、`WFormPopup.show` 10
   —— 对照自家 §6「参数 ≤ 3 个，> 3 个说明是两个组件」。

### 2.4 配置模型有三种流派，彼此不兼容

| 流派 | 代表 | 问题 |
| --- | --- | --- |
| 可变 Config | `WFormTextFieldConfig`、`WFormBorderConfig`、`WToastConfig` | 不能 `const`；共享会串味；`build()` 成了公开入口 |
| 不可变 Style + copyWith | `WButtonStyle`、`WImageStyle`、`WTextStyles` | 用 `Object?` 哨兵表达"清空"，`WButtonStyle` 为此写 10 个 `withoutX()` |
| 静态全局 | `WConfig`、`WApiConfig`、`WFormDefaults`、`WScreen`、`WAssets` | 不可测试、跨测试污染（`WFormDefaults.reset()` 就是为此存在） |

## 3. 做得好的地方（重构时不要动）

1. **`WAsync` 的异常语义**：业务异常 → 回调 + 返回 null；编程错误 → 原样上抛，文档与实现严格一致。
2. **`WCancelToken`**：协作式取消、取消不触发 `onError`、`cancel()` 后统一清空监听。
3. **`WTextStyles`**：标准的 `ThemeExtension`（11 个语义角色 + `copyWith` + `lerp` + 从 `TextTheme` 兜底）。
4. **`WScaffold` / `WStep` / `WButton` 的断言即契约**：构造/构建期失败，而不是运行时错位。
5. **`WQrController` 的"单订阅流 → 广播流"包装**，以及 `WQrView` 的 pause/resume/热重载处理
   —— qr 是 4 个包中最干净的一个。
6. **`WMapItemMapper.position` 返回 record 而不是 `LatLng`**，业务层不必依赖 `google_maps_flutter`。
7. **发布工程**：暂存副本解决 `workspace:` 外泄（2.0.0 的坑）、`--online` 能定位"仓库领先"、
   doctor 豁免必须写 `reason:`。
8. **测试组织**：测试在子包内、自带 `dev_dependencies`，根 `test/` 只留聚合契约。

## 4. 问题清单

> **P1** = 默认路径错误 / 可能崩溃 / 契约被破坏 / 发布质量受影响；
> **P2** = 结构性冗余（每次改动都在付利息）；**P3** = 卫生、文档与一致性。
> 行号基于本次基线，重构后会漂移。§4.1 是运行时包，§4.2 是工具包。

### 4.1 运行时包 P1

#### P1-1 `WAppBar` 默认图标变黑、标题变正文字号，且全包不读 `AppBarTheme`

- 证据：`packages/ui/lib/src/components/layout/appbar.dart:112-124`
  `IconTheme(data: foreground == null ? const IconThemeData() : IconThemeData(color: foreground))`
  是**替换**而非 merge；`foreground` 默认 null，子树拿到空 `IconThemeData`，
  `IconTheme.of` 回填 Flutter fallback（黑 / 24px），`ThemeData.iconTheme` 与上层 `IconTheme` 全丢。
  深色主题下就是黑底黑图标。
- 证据：`appbar.dart:160-178` `_buildTitle()` 只用 `style.titleStyle`，为 null 时把 `style: null`
  交给 `Text`，落在 `Scaffold` 的 `Material` 默认文本样式（≈ bodyMedium 14sp）；不读 `AppBarTheme.titleTextStyle`。
- 为什么是问题：`WScaffold(title:)` 是最常用入口，默认外观就是错的，消费者会整组弃用。
- 改法：`IconTheme.merge`；标题按 `style.titleStyle ?? appBarTheme.titleTextStyle ?? textTheme.titleLarge` 回退。

#### P1-2 `WButton` 无 style 时硬编码品牌色，完全脱离 `ColorScheme`

- 证据：`button.dart:142` `final base = widget.style ?? WButtonStyles.primary;`；
  `button_styles.dart:9-27` 写死 `#3949AB` / `#D32F2F`。
- 为什么是问题：Material 3 的 `FilledButton` 跟随 `colorScheme.primary`，`WButton` 不跟随；
  消费者只能给每个按钮传 style，于是有了 `packages/ui/example/lib/app_buttons.dart` 这种二次封装。
- 改法：`WButtonStyles.of(context)` 从 `colorScheme` 派生；品牌色改为显式可选预设。

#### P1-3 `WImage.avatar(url, style: …)` 静默丢掉尺寸与圆角

- 证据：`packages/ui/lib/src/components/common/image/image.dart:250-271`
  ```dart
  assert(style == null || size == 40, '传了 style 时 size 会被忽略…');
  style: style ?? WImageStyle.avatar(size),
  ```
  `size` 默认正好 40，所以"只想加个 fit/semanticLabel 而传 style"时**断言放行**，
  但 `style ?? preset` 让整个 avatar 预设（40×40 + 全圆角）被替换，图片按内在尺寸渲染。
- 改法：预设 merge 而非替换（`WImageStyle.avatar(size).merge(style)`），或拆成
  `WImage.avatar(size:)` + `WImage.circle(style:)`。

#### P1-4 `WRowButtons` 模型不成立，却被两份文档推荐为"一行多个按钮"

- 证据：`packages/ui/lib/src/components/common/row_buttons.dart:240-246`
  点击回调里无条件 `onTap?.call(index); controller.animateTo(index);` —— 点任何按钮都改选中；
  `:266` `final int length`（不可变且要求 >0），无法表达 0 个按钮；
  `:181,343` 同一 controller 挂两处 → 同一批 `GlobalKey` 冲突直接崩。
- 文档冲突：`docs/modules/components.md` §3、`docs/agents/button.md` 都把它写成"一行多个按钮"。
- 改法：拆 `WActionRow`（无选中）与 `WSelectableRow`（分段选择），并改文档。

#### P1-5 默认 `WForm` 不渲染任何 message / error，`validate()` 静默失败

- 证据链：`form_container.dart:28`（`borderConfig` 默认 null）→ `border.dart:117-119`
  `widget.config ?? scope ?? const WFormBorderConfig()` → `border.dart:199-207`
  `config.errorBuilder?.call(...) ?? const SizedBox.shrink()` → `WFormBorderConfig.standard()`
  才会设置 `hintBuilder/errorBuilder`（`border.dart:247-292`）；再叠加
  `validator.dart:189` `bool showBorderError = false`。
- 为什么是问题：`WFormTextField(name:'email', message:'请输入邮箱')` + `WForm(controller: form)` 时
  message 永不出现；`form.validate()` 返回 false 但屏幕无任何变化。**这是 pub 上默认用法的第一屏体验。**
  测试脚手架自己也得先造 `borderConfig` 才能断言文案（`packages/form/test/_helpers/form_test_scaffold.dart:41-56`）。
- 改法：`WForm.borderConfig` 默认 `WFormBorderConfig.standard()`；hint/error builder 兜底
  `Text(list.join('；'))`；`WForm` 未传 settings 时默认 `showBorderError = true`。

#### P1-6 回调与弹层的所有权缺失（3 个可崩溃点）

1. `field_button.dart:229-233` 把 `didChange` 闭包交给消费方，`_WFormScopeButtonState` 无 `mounted` 保护，
   而 `docs/modules/form_module.md` §5.7 正推荐"打开选择器后调用 didChange" → await 期间退页面 → setState after dispose。
   对照 `date_picker.dart:83` 自己做了 `state.mounted` 保护，属同类不一致。
2. `multi_dropdown_field.dart:124-181`：`WFormPopup.show(...)` 的返回值被丢弃，弹层没有 owner；
   字段被列表回收后弹层仍在，点选项 → `state.didChange` on disposed state。
3. 同名字段：`form_controller.dart:127-129` `putIfAbsent(name, …)` + `field_shell.dart:159-167`
   把同一个 `GlobalKey` 交给 `WFormBorder`；空 name 有校验（`field_shell.dart:29-31`），**重名没有** →
   两个 tab/两段表单同时挂载即 "Multiple widgets used the same GlobalKey"，错误信息不可读。
- 改法：`safeDidChange`（判 mounted）、`WFormPopup.show` 返回 handle 并在字段 dispose 时关闭、
  `ensureBorderKey` 记录 owner，重复注册直接 `ArgumentError('字段 name 重复: $name')`。

#### P1-7 `w_tools_form` 把 `flutter_form_builder` 的类型泄漏进公开 API

- 证据：`form_controller.dart:19,25`
  ```dart
  final formKey = GlobalKey<FormBuilderState>();
  FormBuilderFields? get fields => formKey.currentState?.fields;
  ```
  两个类型都来自 FFB，而 `components.dart` / `w_tools_form.dart` **没有** re-export
  （对比 `w_tools_qr.dart` 会显式 `export … show Barcode, CameraFacing…`）。
- 为什么是问题：用到 `fields` / `formKey`（动态字段、手动校验几乎都要用）就必须自己加 FFB 依赖；
  FFB 大版本升级时消费方被迫跟着动。这是"既不封装也不声明"的最差组合。
- 改法（二选一）：真封装（`WFormKey` / `Map<String, dynamic> get values`），
  或真暴露（barrel 显式 `export … show FormBuilderState, FormBuilderFields, FormBuilderField`）+ README 声明。

#### P1-8 401 处理：先无条件清 token，再 single-flight 刷新，可能清掉新 token（推断，需用例）

- 证据：`packages/api/lib/src/interceptors/token.dart:132-145`
  ```dart
  final retryCount = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;
  await tokenClearer?.call();               // ← 无条件、且在刷新之前
  if (retryCount >= maxAuthRetries) { … return; }
  …
  final newToken = await _refreshToken();    // single-flight（:177-186）
  ```
- 推演：R1、R2 持旧 token 并发 401。R1 清 token → 刷新得 T1 → 重试成功；R2 的 401 若在刷新之后到达，
  会把已持久化的 T1 清掉，然后 `_refreshFuture` 已置空 → 发起**第二次刷新**。若 refresh token
  一次性/已轮换，第二次失败 → 用户被登出。当前测试未覆盖"并发 401 且刷新已完成"。
- 改法：只在刷新失败/放弃重试时清 token，或给刷新加代次（generation）判断。
  **先补两条请求并发 401 的用例再改。**

#### P1-9 设计系统只在 ui 内自用，form / toast / async 各写一套样式

- 证据：`WText(` / `WButton(` 在 ui 之外 **0 次**调用（grep 全仓，命中仅在 cli 模板字符串）。取而代之：
  - `packages/form/lib/src/components/border/border.dart:263` `TextStyle(fontSize: 12, color: Color(0xFF6B7280))`；
    `border.dart:243-247` 调色板还写死 `#E5E7EB` / `#10B981` / `#EF4444` / `#F9FAFB` / `Colors.white`；
  - `packages/toast/lib/src/toast.dart:22` `TextStyle(fontSize: 17, color: Colors.white)`；
    `toast_config.dart:288,313` `fontSize: 14`；
  - `packages/async/lib/src/view/async_error_view.dart:29-48` 直接 `Icon` + `Text` + `FilledButton`。
- 为什么是问题：同时用 `WText(variant: title)` 与 `WFormTextField(label:)` 会看到两种字号、两种灰色；
  form 的 hint 色没有主题入口，深色主题下不可读。
- 改法：让 form / toast / async 依赖 ui（ui 不反向依赖，无环），或至少各自提供
  `TextStyle` / `ColorScheme` 注入点并禁止 `Color(0x…)` 字面量。这是产品决策（§6.1）。

#### P1-10 `w_tools_async` 与 3 个工具包不在 CI 矩阵里

- 证据：`.github/workflows/ci.yml:88`
  `matrix.package: [core, ui, form, api, app, toast, map, qr, cli]` —— 没有 `async`、`figma`、`device`、`e2e`；
  全文 `grep async|figma|device|e2e` 无命中。
- 为什么是问题：`w_tools_async` 已发布 1.0.0、被根包依赖、有 1,923 行测试却**从未在 CI 跑过**；
  3 个工具包同理（`release_check.sh` 只校验版本号，不跑测试/analyze/发布预检）。
- 改法：矩阵补 `async` + 3 个工具包；顺手更新 `ci.yml:26` 注释（仍写着已移除的"WConfig 兼容层"）。

#### P1-11 `WApp` 有两套并行配置面：`start()` 的 9 个参数与 9 个字段一一重复

- 证据：`app.dart:17-69`（字段）与 `app.dart:173-198`（`start()` 再写 9 个，语义是"参数覆盖字段"）。
- 为什么是问题：同一个值两个入口，写错不报错、静默用错；`start()` 已 11 个参数，超自家"≤3"三倍。
- 改法：只留一套（字段或 `WAppOptions` 值对象），`start()` 不接配置；
  或彻底函数式 `await WApp.start(const WAppOptions(...))`。

#### P1-12 toast：成功提示会全屏吞点击 2 秒，且同名 API 两个入口默认不同

- 证据 1：`toast.dart:47-62` 的 `showSuccess/showError/showWarning` 全部走
  `BotToast.showCustomLoading(...)`，未传 `allowClick/clickClose/crossPage`；
  bot_toast 默认 `CustomLoadingOption{allowClick=false, clickClose=false, crossPage=false}`。
  → `toast.showSuccess('已保存')` 后 2 秒内页面所有按钮点不动，换页提示还会被清理。
- 证据 2：`toast.dart:18-24,103` 静态 `showText` 是 17sp / 屏幕下方 `Alignment(0,0.8)`；
  `toast_config.dart:29,187` 的 `WToastConfig.showText` 默认 `Alignment.center`，
  `:283-292` 的默认文案是 14sp；`docs/modules/toast_module.md:95,119` 说"默认屏幕下方"。
- 为什么是问题：`WToastConfig` 名字是配置，实际是门面（6 个 `show*` + 2 个 `hide*` + 全局 static
  `_loadingCancelFunc`），没有全局安装点，每个调用点都得自己持有实例。
- 改法：门面静态化（`WToast`）+ 样式不可变（`WToastStyle`）；success/error/warning 用
  `showEnhancedWidget(allowClick: true, crossPage: true)`；补 `WToastTheme` 与 `WToastPlugin`（§7.3）。

#### P1-13 map：默认 mapper 在构造函数抛裸 `_TypeError`；空数据时相机停在 (0,0)/zoom 1

- 证据 1：`packages/map/lib/src/map.dart:202-204` 构造体内立即 `initMap()` →
  `:50-63` 默认 mapper `item as WMapItem` → `WMapZone<_PlainShop>(maps: shops)` 直接炸，
  堆栈落在 `initMap`，错误只是类型转换。而 `docs/modules/map_module.md` 明写"`T` 不要求实现 `WMapItem`"，
  `map.dart:133` 的类注释又写"泛型 T 约束为 `WMapItem`"——两份文档互相矛盾。
- 证据 2：`:277-285` 在 `maps` 为 null/空时把 `cameraPosition = null`；`:495-496`
  回退 `CameraPosition(target: LatLng(0,0), zoom: 1)`；`WMapZone` 构造没有 `initialCamera` 入口
  （`cameraPosition` 是公开可变字段，每次 `initMap()` 被覆盖）→ 异步加载门店的页面首帧是大西洋。
- 改法：构造期给出可读 `ArgumentError`；增加 `initialCamera`，`cameraPosition` 改只读；
  null 坐标跳过 + debug 告警（而不是落到几内亚湾，`:55,60,233-236`）。

### 4.2 工具包 P1（cli / figma / device）

#### P1-T1 `init --check` 把"可选配置"和"内部 manifest"当缺失，CI 会假红

- 证据：`bin/init.dart:161`（check 模式才加载 manifest）、`:227-235`、`:302-304`（有 `missing` 即 exit 1）；
  `lib/src/init/init_project.dart:277` 把 `.w_tools_doctor.yaml` 当普通生成物。
- 为什么是问题：docs 明确说 `.w_tools_doctor.yaml` **可选**（不写按默认运行），但 check 会因它缺失失败；
  旧项目没有 `.w_tools/init.json` 也会永久失败（check 不写文件，只能先手工跑一次 init）。
- 注意：`packages/cli/test/init_test.dart` 有一条用例**期望** `missing` 含 `init.json`，
  所以这可能是有意设计。但契约应重定为"只检查用户可见生成物"，内部 metadata 不进 CI gate。

#### P1-T2 init 与 doctor 的路径规则是两套，`toolkit_entry` 实际无效

- 证据：`lib/src/doctor/config.dart:13-18` 有 `projectUiDirPath/designSystemDirPath/toolkitEntry`；
  但 `lib/src/init/init_project.dart:258-273` 全部硬编码 `lib/app/w/toolkit.dart` 等，
  `:327-335` 的 `_uiStarterFiles` 又抄一遍。`docs/conventions.md:146` 却写"init 与 doctor 使用同一套路径"。
- 为什么是问题：用户改 `toolkit_entry` 后 doctor 按新路径检查并报"没有入口（未运行 init）"，init 永远写默认路径。
- 改法：收敛到单个 `ProjectLayout`，init 全部从它取；加一条"自定义 toolkit_entry 后 init/doctor 一致"的测试。

#### P1-T3 `doctor --write-config --force` 覆盖项目配置且不备份

- 证据：`bin/doctor.dart:74-82` 直接 `writeAsStringSync(renderDefaultConfig())`，没有 `.bak`；
  对比 `init_project.dart:184-198` 至少写 `.bak`。
- 为什么是问题：`.w_tools_doctor.yaml` 是手工维护的 palette/banned/ignore，一次 `--force` 静默抹掉；
  `docs/feedback/cli.md` 记录过同类事故（`--force` 丢了 12 条 banned），init 路径修了，doctor 又留了一个入口。
- 改法：复用带时间戳的 `backup()`；或 `--write-config` 只允许写不存在的文件，覆盖必须显式 `--force --backup`。

#### P1-T4 figma 的额度预算只展示、不拦截

- 证据：`lib/src/commands/fetch_command.dart:126-131`、`diff_command.dart:91-97` 只 `logUsage`；
  只有 `usage_command.dart:18,27-30` 读 `isNearLimit`。而 `docs/figma-cli.md:83,221` 说 80% 要警告、budget 用来"解决只能等 429"。
- 为什么是问题：真正消耗额度的 `fetch`/`diff` 完全不看预算，设了 `budget --set=15` 仍可烧到 429。
- 改法：在 fetch/diff 发请求前统一 `BudgetGuard.check()`（≥80% 警告、≥100% 默认拒绝，`--ignore-budget` 放行；
  缓存命中与 spec/tokens 不触发）。

#### P1-T5 figma 在 Windows 上找不到 nodes 缓存（spec/tokens/frames 全坏）

- 证据：`lib/src/cli/cache_data.dart:159-161` 用 `f.path.split('/').last`；而
  `lib/src/cache/cache_store.dart:60-68` 明确支持 `LOCALAPPDATA`。Windows 路径
  `C:\...\nodes-x.json` 经 `split('/')` 得到整条路径，`startsWith('nodes-')` 为 false。
- 改法：统一 `package:path` 的 `p.basename`，补一条 Windows 风格路径单测。

#### P1-T6 device 标定缓存不随设备尺寸/方向失效，可能静默点错坐标

- 证据：`lib/src/cli/device_ios_commands.dart:299-303` 命中缓存时只传 `scale`，
  `isFreshCalibration` 的注释（`lib/src/calibration_store.dart:39-47,66-70`）却明确要求
  "设备尺寸 / 方向变化时也必须失效"；CLI 在缓存检查之后才 `screenshotSize`（`:306`）。
- 为什么是问题：旋转设备/换窗口/分辨率变化后旧 `deviceRect` 继续映射，`tap`/`drag` 不校验，
  `verify` 只能事后发现"没变化"。
- 改法：先取尺寸再判 freshness（key 含 udid + window + deviceWidth/Height + scale + orientation），
  并把 `_calibrate` 纳入测试（现在只测 `CalibrationStore`）。

#### P1-T7 catalog / catalog.g.dart / docs 三份真相已漂移

- 证据：`docs/modules/components.md:16` 写 `WStep` / `WStepFlow`，`packages/cli/catalog/components.yaml:25`
  只有 `WStep`，`catalog.g.dart` 里没有 `WStepFlow`；`packages/cli/test/catalog_test.dart:56-65`
  只取 docs 单元格的**第一个**反引号名比较，所以 `WStepFlow` 永远不被检查。
  `catalog.dart:7` 还把 schema 版本当 `catalogVersion` 展示（`components.yaml:3` 的 `version: 1`）。
- 为什么是问题：docs 是人和 AI 的入口，`explain WStepFlow` 却查不到；三份文件的描述文本也已不同。
- 改法：以 YAML 为唯一源，生成 g.dart **和** docs 的组件表格；测试做全字段/全别名比对；
  schema 版本与内容版本分开（`catalogSchemaVersion` / `catalogRevision`）。

#### P1-T8 `doctor --include-tests` 会把文档要求的 dev 工具包误报成 R2 error

- 证据：`lib/src/doctor/rules/r2_direct_subpackage_import.dart:13-15,23-27` 匹配所有 `w_tools_*`，
  只豁免 toolkit / `lib/app/ui` / 设计系统；`doctor/context.dart:44-45` 在 `--include-tests` 时扫描 `test/`、`tool/`。
  而 `docs/agents/device-testing.md:51,91` 明确要求 `tool/main_e2e.dart` 直接 import `package:w_tools_e2e/…`。
- 改法：对 `test/`、`tool/`、`integration_test/` 增加 dev-only 包白名单
  （`w_tools_device` / `w_tools_e2e` / `w_tools_figma` / `w_tools_cli`）；补回归用例。

#### P1-T9 `feedback lint --stale-days=0` 与文档相反，0 不会关闭警告

- 证据：`lib/src/feedback/feedback_lint.dart:199-207` 用 `if (age > staleDays)`；`staleDays=0`
  时任何 `age>0` 都命中。`bin/feedback.dart:26` 与 `packages/cli/README.md:283` 都写"0 关闭"。
- 改法：`staleDays <= 0` 直接跳过；`--stale-days` 严格解析，非法值 exit 2。

### 4.3 P2：结构冗余

#### 运行时包

| # | 包 | 问题 | 证据 | 建议 |
| --- | --- | --- | --- | --- |
| P2-1 | core | 同一批正则有 4 种表示（`WValidator`/`WRegExpPattern`/`WRegExpPreset`/`WRegExp`），9 个校验器只有 password 复用常量，其余 8 个各自内联编译 `RegExp` | `validator.dart:15,21,43,62,72,81,173` vs `reg_exp.dart:16-71` | 只留编译好的 `WRegExp` + 调用它的 `WValidator` |
| P2-2 | core | 同一语义两个规则：`isValidUrl`（`Uri`）vs `WRegExpPattern.url`（正则）；`isPositive('1e3')` 为 true 而 `WRegExp.positiveNumber` 不匹配 | `validator.dart:48-57,160-163`；`reg_exp.dart:34,51` | 每个语义只留一处，标明"业务校验 vs 纯格式" |
| P2-3 | core | 不该由客户端库提供：`escapeSql`/`stripHtml`（自认"不能作为安全防线"）、`hashPassword`（单轮加盐 SHA-256） | `validator.dart:109-135`；`hash.dart:60-71` | 删除或 `@Deprecated`；密码哈希必须服务端 |
| P2-4 | core | `WStorage` 读写语义不对称（写懒初始化、读抛 `StateError`）；`setObject(k,'a')` 存裸字符串，`getObject<String>(k)` 却 `jsonDecode('a')` 抛异常返回默认值 | `storage.dart:37-47,71-73,132-161` | 读写统一；`setObject` 不接受 String 裸存 |
| P2-5 | core | `WUx` 名不副实（防抖/节流/延迟/下一帧/滚动/3 个时长常量），单例无状态；`debounce` 写在 `build`/`onTap:` 里等于没防抖；`throttle` 在 `function()` 抛异常后永久锁死 | `ux.dart:8-18,24-67` | 拆 `WDebounce`/`WThrottle`/`WScroll`；静态化；`try/finally` |
| P2-6 | core | `WCountdown` 公开可变 `isRunning`/`isPaused`；`dispose()` 就是 `stop()`（之后还能 `start`）；不是 `Listenable` | `countdown.dart:16-20,130-132` | getter + 私有 setter；`dispose` 后禁止复用；实现 `ValueListenable<int>` |
| P2-7 | core | `WPlatform.getPlatformValue` 5 个必填参数；`WPlatformType` 与 `TargetPlatform` 重复 | `platform.dart:102-123` | 只留 `platformType` / `isMobile` / `isDesktop` |
| P2-8 | core | `WConfig` 只剩 3 个 token 键名 + 1 个已弃用字段（注释说"下个大版本移除"，已跨过 3.0） | `config.dart:1-27` | 键名并入 `WToken`；删 `assetImagePath` |
| P2-9 | api | `DioRegistry.forBaseUrl` 命中缓存后静默忽略 options/interceptors；401 重试会先创建"裸 Dio"，永久占位真正的配置 | `clients/dio_registry.dart:51-63`；`interceptors/token.dart:219` | 命中但配置不同要报错；重试复用发起请求的 Dio |
| P2-10 | api | `WLogInterceptor` 7 个 bool（`requestBody=true`、`responseHeader=false`）；默认无条件打印响应体；出口是 `WApiConfig` 两个全局 hook，不接就静默丢日志 | `interceptors/log.dart:9-52,198-204` | `WLogLevel`/`Set<WLogPart>`；默认走 `WLogger`；release 默认关 body |
| P2-11 | api | 装饰性基类：`BaseRepository`/`BaseLocalDataSource`/`BaseRemoteDataSource` 零行为；`IApiPath`/`ApiClientId` 无内部使用，`ApiClientId` 无 `==`/`hashCode` | `repositories/base_repository.dart:1-24`；`common.dart:6-19` | 全删，不损失能力 |
| P2-12 | app | `WBottomSheet.show(Widget)` 只有 1 个参数，吞掉 `Get.bottomSheet` 的 barrierColor/isDismissible/enableDrag/backgroundColor/shape | `utils/bottom_sheet.dart:9-28` | 透传可选参数或提供 `WBottomSheetTheme` |
| P2-13 | app | `WLanguage.languageStream` 类型是 `RxString` 不是 Stream；`WAppConfig.currentLanguage` 是公开可写静态（"唯一真源"却不该写）；`WConfig`/`WApiConfig`/`WAppConfig` 三名撞车 | `utils/language.dart:17-23`；`utils/app_config.dart:20-21` | 改名 `language` 或返回真 Stream；setter 私有 |
| P2-14 | app | `WApp` 是实例类但 `WRoute`/`WAppConfig` 是全局静态；`run()` 里 `title ?? ''` 是死分支（前面已断言非空） | `app.dart:277-292` | 统一实例态或静态态 |
| P2-15 | async | `WAsyncConfig` 逐方法转发 `WAsync`（7 个方法、约 300 行），任何新特性改两处；`WAsyncController` 完全不用 `WAsync` | `task/async_task.dart:100-283`；`state/async_controller.dart:45-61` | 删 `WAsyncConfig`，回调直接作为 `WAsync.run` 参数；Controller 接执行器 |
| P2-16 | async | 三个视图输入形状不一致（`WAsyncStateSliver` 收裸 state，另两个收 `ValueListenable`）；`onRetry` 一处 `Future<void> Function()`、一处 `VoidCallback` | `view/async_view.dart:44-45`；`view/async_state_sliver.dart:37-39` | 统一输入与签名 |
| P2-17 | async | 默认文案双份：`'暂无数据'`×2、`'加载失败'/'重试'`×2 | `async_view.dart:147`；`async_state_sliver.dart:82`；`async_error_view.dart:12-13`；`async_error_banner.dart:9-10` | 抽 `WAsyncStrings` |
| P2-18 | async | `WAsyncStateSliver` 的 `else if (state.isReady)` 与 `switch` 的 `ready` 分支只在 `T` 可空且 `ready(null)` 时可达 | `async_state_sliver.dart:70-71,93` | 删分支或断言禁止 `ready(null)` |
| P2-19 | ui | `WTextStyles.of` 未安装扩展时**每次调用**重建 11 个 `TextStyle`（每个 `WText` 每次 build） | `components/text/w_text_styles.dart:84-88` | 按 `TextTheme` 缓存或强制安装 |
| P2-20 | ui | `WScreen` 用 `MediaQueryData.fromView(views.first)` 绕开组件树 MediaQuery（多窗口/分屏/`removePadding` 失效），每次访问新分配；无 delegate 时静默不缩放 | `utils/screen.dart:55-67`；`extensions/widget.dart:19-34` | 设备信息用 `MediaQuery.of(context)`；缺 delegate 时首帧 assert |
| P2-21 | ui | 布局糖三重冗余：`WRow/WColumn/WPadding/WSizeBox`（4 文件 172 行）+ `WNumExtension` + `WWidgetExtension.with*Padding` = 28 个入口包 Flutter 4 个类，全丢 `const` 与 `mainAxisAlignment` | `utils/{row,column,padding,size_box}.dart`；`extensions/{num,widget}.dart` | 只留扩展，删 4 个静态工厂 |
| P2-22 | ui | 5 个组件仍强制"必填 Config + `.build()`"（`WTabBarConfig`/`WNavBarConfig`/`WClipRRectConfig`/`WBadgeConfig`/`WStepFlow`），与 3.0 删 `WTextConfig` 的方向相反 | `navigation/tab_bar.dart:185`；`navigation/nav_bar.dart:129`；`common/{clip,badge}.dart`；`layout/step.dart:96,126` | 配置可选、组件直接构造 |
| P2-23 | ui | `WImageFrame` 的 `margin` 与 `padding` 都在装饰层外，语义完全等价（文件头注释说的相反，`ui_module.md:866` 也承认） | `common/image/image_frame.dart:35-55` | `padding` 移进装饰层，或删 |
| P2-24 | ui | `WNetworkImageSource` 的 `==` 用 `mapEquals`（顺序无关）而 `hashCode` 用 `Object.hashAll(entries)`（顺序相关） | `common/image/image_source.dart:126-138` | 同一口径 |
| P2-25 | ui | barrel 导出内部实现（`WImageLoader` 可变状态机），而它的依赖 `WImageLoadState`（注释写"公开只为测试"）不在 barrel；测试直连 `src/` 20 处 | `w_tools_ui.dart`；`common/image/image{,_load_state}.dart` | 公开就导出、内部就私有 |
| P2-26 | ui | `WImageStyleIO.buildFile` 从未被 export（死代码），注释还指向 2.0 已删的 `config.buildFile` | `common/image/_image_file_native.dart:13-36` | 删除 |
| P2-27 | form | 同一字段两条公开路径，7 份 `build()` 各复制一遍"清空 decoration + 包 Shell + 拼 readOnly"，已产生真实行为分歧（`bordered` 默认 true/false 不一致、unbordered 是否插 `WFormReadOnlyScope` 不一致、`message` 在 `bordered:false` 下静默丢弃） | `direct_fields.dart:16-27,41,130,190,251,312,365,424`；`text_field.dart:287,297,317-327`；`dropdown.dart:188,194-218` | 删 Config 的 `build()` 公开面，direct widget 成唯一入口 |
| P2-28 | form | 图标 3 套机制（8 个图标 × 3），优先级靠人肉记忆，静态那套是可变全局 | `form_defaults.dart:20-41`；`form_theme.dart:18-32,59-71`；`form_container.dart:29-40` | 只留 `WFormTheme` + 不可变 `WFormIcons` |
| P2-29 | form | `WFormFieldBaseConfig` 只省了字段声明，7 个 Config 各自重复构造转发 + copyWith 里 10 个基类参数 | `field_base_config.dart:10-20`；`text_field.dart:275-285,332-384` | 组合不可变 layout 值对象，或随 Config 层一起删 |
| P2-30 | form | `WFormBorderState` 有 50 行 snapshot/cache，只为弥补 `WFormBorderConfig` 没有 `==` | `border.dart:63-75,116-135,138-170` | 给 Config 实现 `==`/`hashCode`，删缓存 |
| P2-31 | form | 嵌套表单时显式 `borderConfig` 被外层 theme 吞掉（祖先优先） | `form_theme.dart:46-52` | 改 `borderConfig ?? inherited` |
| P2-32 | form | 日期字段在统一边框内多画一条下划线（`decoration` 默认 `InputDecoration()`，`border` 为 null → 主题默认 `UnderlineInputBorder`） | `date_picker.dart:60,185` vs `dropdown.dart:119-124` | 默认 `InputBorder.none` |
| P2-33 | form | `lastDate: DateTime.now()` 在 build 里求值 → 页面挂过夜后"今天"选不了；且 direct 层可选、Config 层 required | `direct_fields.dart:287`；`date_picker.dart:214-215` | 挪到 onTap 计算，两层签名一致 |
| P2-34 | form | `setValue` 文档说"不更新 `formEntered`"，实际 FFB 的 `didChange` 会回调 `onChanged` → `handleChange` | `form_controller.dart:53-59`；`text_field.dart:147-151` | 改文档或删 `updateValue` |
| P2-35 | form | `formEntered` 不是 `Listenable`，文档却建议用它驱动按钮启用 | `form_controller.dart:31,37-44` | `WFormController extends ChangeNotifier` |
| P2-36 | form | `autovalidateMode`（FFB → `InputDecoration`）与 `WFormValidator`（border `setError`）是两条错误通道，会同时出字 | `text_field.dart:179`；`validator.dart:101-103`；`field_frame.dart:63-69` | 直接字段不再把 validator 传给内层 FFB |
| P2-37 | form | 5 处悬空注释引用不存在的 `builder`；`form_module.md:443` 的"统一 Config + build"与 `docs/agents/form.md` 的"不要从 Config.build 开始"直接矛盾 | `text_field.dart:232`；`dropdown.dart:259`；`checkbox.dart:244`；`date_picker.dart:302`；`radio_group.dart:304` | 删 Config 层或删注释并统一文档 |
| P2-38 | form | 公开但零调用：`Row.withFormBorder`、`WFormBorderLayout.builder`、`WFormBorderConfigBuilder` | `field_shell.dart:20-43`；`border_layout.dart:44-46`；`border.dart:327-358` | 删除 |
| P2-39 | form | `WFormPopup` 锚定弹层不跟随滚动（文档已知），但每次 build 重算位置、无 handle 可关闭 | `popup.dart`；`multi_dropdown_field.dart:124-181` | 返回 handle + 跟随锚点 |
| P2-40 | toast | `showLoading` 忽略 `WToastConfig.align`（硬编码居中）；`dismissible` 在默认样式下无效；全局 static `_loadingCancelFunc` 不跟页面；`hideAll` 全库清屏 | `toast_config.dart:79,222-247,257,294-319` | 统一 align；删无效参数；`runWithLoading` |
| P2-41 | toast | 依赖 `bot_toast`（2023 年后无更新），且必须由消费者自己 `BotToastInit()`，库无安装点 | `pubspec.yaml`；`toast.dart:38-124` | 提供 `WToastPlugin`；评估自绘 Overlay |
| P2-42 | qr | `onScanned` 必填（只用流的人被迫写空回调）；`scanOnce=true` 后只能靠 `GlobalKey.restartScan()`（`resumeCamera` 不解除锁）；`scanInterval` 默认 `Duration.zero` 等于不去重；无 `onError` 时走 `FlutterError.reportError` | `qr_view.dart:49,78,97,102,246-258,315-332,342-345,396-415`；`qr_controller.dart:48-49` | 可空 + assert；`WQrController.restartScan()`；默认 400ms；默认 `WLogger.e` |
| P2-43 | qr | `WQrViewOverlayShape` 无 `==`/`copyWith`，`didUpdateWidget` 按引用比较 | `qr_view.dart:167`；`qr_overlay_shape.dart` | 加 `==`/`copyWith` |
| P2-44 | map | 每次 `update()` 都把相机拽回第一个条目（分页/筛选时用户手势被弹回）；marker 全量重建（`Marker` 无值相等），`onTap` 捕获旧 element | `map.dart:260-283,440-456` | 只在空→非空或显式 `recenter()` 时移动；marker 按 id 复用 |
| P2-45 | map | `dispose()` 不清 `zone.googleMapController`；`closeSelection` await 后无 `mounted` 检查；相机操作无 try/catch 且 `_appliedCamera` 在 await 前写死 | `map.dart:388-392,426-437,476-489` | 清引用、判 mounted、成功后再写缓存、catch 上报 |
| P2-46 | map | 整包 552 行挤在单个 `map.dart`（8 个公开类型）；`WMapConfig` 必填但 5 个字段全有默认；`WMapConfig.build()` 是第二入口（只有测试用） | `packages/map/lib/src/map.dart` | 拆 4 文件；`config` 可空；删 `build()` |

#### 工具包

| # | 包 | 问题 | 证据 | 建议 |
| --- | --- | --- | --- | --- |
| P2-T1 | cli | 文本扫描有 5 套变体，且不处理块注释/raw string（块注释里的 `Color(0x…)` 仍命中 R3，与 `docs/conventions.md:101`"注释会跳过"不符） | `doctor/text_scan.dart:10-57`；`r2:29-34`；`r4:32-36`；`r6:28-32`；`r9:56-61`；`feedback_lint.dart:109-211` | 一个 `SourceIndex` 一次读、去注释，规则只写 matcher |
| P2-T2 | cli | init 里 pubspec 被解析 4 次；`_subpackageConstraints` 是第四份版本真相（只在仓库内测试校验） | `bin/init.dart:78-93`；`init_project.dart:14-27,360-370,435-465` | 抽 `ProjectPubspec` 缓存 |
| P2-T3 | cli | ignore/glob 语义不完整：`**` 被 `replaceAll('*','')` 变成 `//` 永不匹配；不支持 `!` 反选；`\` 不归一化；R9 的 `paths/ignore` 是另一套实现 | `doctor/context.dart:68-75`；`banned_rule.dart:74-98` | 一个 glob 编译器（`*`/`**`/`?`/`!`），两处共用 |
| P2-T4 | cli | `enabledRules` 只对 R6/R9 生效，R7/R8 无法关闭，配置写了也不提示 | `config.dart:73-81`；`r6:18`；`r9:17`；`run.dart:118-124` | `runDoctor` 统一按 `enabledRules` 过滤 |
| P2-T5 | cli | R8 绕过 `ProjectFacts.packages` 自己读 lock，且只查版本号不查内容新鲜度（doctor 绿、`init --check-drift` 红） | `r8_generated_stale.dart:25,68-93`；`doctor/context.dart:109` | 用 `facts.packages`；R8 拆版本 + 内容哈希 |
| P2-T6 | cli | R4 只查 `import`，`export`/`part` 可绕过（R2 两者都查） | `r4_design_system_boundary.dart:19-21`；`r2:14` | 复用 R2 的 import/export 正则 |
| P2-T7 | cli | 往已有 cursor 规则文件追加时丢 YAML frontmatter | `init_project.dart:285-312,385-392,431` | 追加时补 frontmatter |
| P2-T8 | cli | manifest 里非法 `profile` 让 `init` 抛裸 `StateError`（`firstWhere` 无 `orElse`） | `bin/init.dart:184-189`；`manifest.dart:63-82` | `orElse` + 可读报错 |
| P2-T9 | cli | 文件系统边界：`listSync(recursive)` 默认跟随符号链接；`readAsStringSync` 无异常处理（坏编码即崩）；全部直接写、无原子写 | `doctor/context.dart:51-66`；`init_project.dart:135,158,195,223,232` | 跳过并警告；`followLinks: false`；`atomicWrite` |
| P2-T10 | cli | `--json` 契约不统一：doctor/init 无 `schema`/`schemaVersion`，context/feedback 有；figma 部分命令有 | `doctor/reporter.dart:44-76`；`context_project.dart:57-59`；`feedback_lint.dart:49-51`；figma `cli/url_command.dart:17-18` | bin 层统一 envelope；schema 测试用真实输出 |
| P2-T11 | cli | `context` 的 token 预算按 4 字符/token 估算（中文约 1 字符/token，可超 4 倍）；"已安装"拼上 lock 里所有包；无 `--json` 别名 | `context_project.dart:162-177`；`bin/context.dart:30-34` | 按字符/语言估算；默认只列 `w_tools_*`；补 `--json` |
| P2-T12 | figma/device | 参数解析只认 `--opt=value`，标准 `--out path` 直接报错；figma/device 无 `--version` | figma `cli/args.dart:83-158`；device `options.dart:62-108` | 换 `package:args` 或支持下一个 token |
| P2-T13 | figma | `commands/` 与 `cli/` 双层，`init/url/usage` 三个薄命令基本只被对应 `cli/*.dart` 调用，却作为稳定 API 从 barrel 导出 | `lib/w_tools_figma.dart:8-12`；`commands/{init,url,usage}_command.dart` | 折叠进 `cli/`，barrel 只导出 client/spec/token |
| P2-T14 | device | 子进程无超时（`Process.run`、`bootstatus -b` 可无限等）；`adb` 文本只转义空格；`runBytes` 用 `r.stdout as Uint8List` 依赖实现 | `shell.dart:13-40`；`android.dart:126-132`；`simctl.dart:89-93` | 统一 `--command-timeout`；转义 `%&;`；`Uint8List.fromList` |
| P2-T15 | device | 图片尺寸读取两套（`sips` 与 `package:image`）；`_calibrate` 里 `_resolveUdid` 重复两次 | `simctl.dart:124-133`；`device_hub.dart:75-81`；`device_ios_commands.dart:167,290` | 统一用 `image` 解码；复用 udid |
| P2-T16 | e2e | `afterLogin` 永远 `unawaited`，调用方无法知道完成时刻，集成测试只能固定 sleep | `lib/src/e2e_login.dart:26-30`；`docs/agents/device-testing.md:145-147` | 提供 `completion` / `afterLoginDone` |
| P2-T17 | 跨包 | 退出码不一致：cli 0/1/2、figma 0~5、device 0~3；`list` 未命中 0 而 `explain` 未命中 1 | `bin/list.dart:50-54`；`bin/explain.dart:74-78` | 定义一份 `ExitCode` 枚举复用 |
| P2-T18 | 跨包 | 同一"检查"语义四种名字：`--check` / `--check-drift` / `--check-stale` / `--if-stale`；`--json`/`--format` 各命令不一致；cli 是 6 个 bin 而 figma/device 是单 bin + 子命令 | 见左 | 统一 `--format`、`--check[=missing\|drift\|stale]`、单入口 |

### 4.4 P3：卫生与文档

| # | 问题 | 证据 | 建议 |
| --- | --- | --- | --- |
| P3-1 | lint 只 include `flutter_lints`，`rules:` 为空、无 `analyzer:` 严格模式 | `analysis_options.yaml` + 4 个工具包同名文件 | 开 `strict-casts`/`strict-raw-types`、`unawaited_futures`、`prefer_const_constructors`、`require_trailing_commas`；子包共用一份 |
| P3-2 | SDK 约束漂移且不可验证：7 个包写 `flutter >=3.27`，CI 只测 3.38.4；`form` 与根包写 `>=3.38` | 各 `pubspec.yaml`；`ci.yml:20` | 全仓统一到验证过的下界，或加"逐包最低版本"矩阵 |
| P3-3 | `form/popup.dart:195` 用已弃用 `axisAlignment`（3.41 后弃用，但最低版本 3.38 还不能换） | `dart analyze` info | 记 issue，等下界抬到 3.41 再改 |
| P3-4 | 文档版本漂移：`docs/agents/figma.md:3,92` 写 0.9.2（实际 0.10.0）、`docs/figma-cli.md:19` 写 0.8.0、`docs/modules/README.md` 写 device "0.1.1 待发布"（已发布）、README 写"根包依赖约束为各子包 `^1.x`"（实际 ^2/^3）、`packages/figma/README.md:3,46` 写 0.9.2 | 见左 | `check_docs.sh` 增加"禁止 prose 版本号"规则 |
| P3-5 | `CONTRIBUTING.md` 要求像素敏感组件加 golden，实际只有 1 个 golden 测试文件 | `grep -rl matchesGoldenFile packages/*/test` | 补 AppBar/Button/Step/FormBorder 的 golden，或把要求收窄 |
| P3-6 | `docs/modules/README.md` 说 core"零 UI 依赖"，但 `WUx` 依赖 `material` 的 `ScrollController`、`SchedulerBinding` | `ux.dart:2-3` | 把滚动/下一帧能力移到 ui，core 只依赖 `foundation` |
| P3-7 | `cli/README.md:383` 的退出码表与实现矛盾（`--check` 有 drift 仍 exit 0） | `bin/init.dart:302-304`；`cli/README.md:158` 自己又写"提示但不失败" | 以测试固定退出码，再改文档 |
| P3-8 | `docs/figma-cli.md:225` 的 `usage --json` 示例用 `"last"`，schema/实现用 `"recent"` | 见左 | 示例从真实输出生成 |
| P3-9 | `explain` 查不到返回 1、`list` 返回 0；`init` 固定打印"需要在 pubspec 加入"即使无需修改；R7 把"依赖未导出"标 info 却在有 issue 时 status=fail（人读 `✗` 但 exit 0） | `bin/explain.dart:74-78`；`bin/init.dart:298-299`；`r7:43-50,65-69` | 统一语义 |
| P3-10 | `WImageStyle` 不校验 `isFinite`（`aspectRatio: infinity` 能过 validate 后在 `AspectRatio` 断言炸），而 `WButtonStyle` 校验 | `image_style.dart:81-89` vs `button_style.dart:150-160` | 校验口径统一 |
| P3-11 | 主题无关默认值 4 处（图片灰占位、渐变 `#EEEEEE`、`WStep` 的 `Colors.blue`、按钮靛蓝），而包内已有正确写法（`image_error_view.dart:30` 用 `colorScheme.errorContainer`） | 见左 | 统一从 `Theme` 派生 |

## 5. 命名问题汇总

| 现名 | 问题 | 建议 |
| --- | --- | --- |
| `HexColor`（extension） | 全仓唯一不带 `W` 的公开名，且是兼容用 extension 而非类 | `WHexColor`，或 `Color.fromHex` |
| `WStringExtension` / `WUiStringExtension` | 同一类型两个扩展被拆名；`toImage` 有 12 个参数 | 合一个；`toImage` 拆成命名构造 |
| `WWidgetExtension` / `WUiWidgetExtension` | 同上，消费者必须记住哪个有哪个方法 | 合并 |
| `wMapItemMapper<T>()` | 全仓唯一小写 `w` 顶层公开符号；与类 `WMapItemMapper` 同名 | `WMapItemMapper.fromItem<T>()` |
| `map.dart` / `direct_fields.dart` | 以包名/实现策略命名，import 时看不出拿到什么 | `w_map_{item,zone,controller,config}.dart`；`w_form_fields.dart` |
| `WQrViewOverlayShape` | `View` 属组件、`Shape` 撞 Flutter 的 `Shape`，实际是纯数据 | `WQrScanFrameStyle` |
| `WToastConfig` | 名字是配置，实际是门面 + 全局 loading 状态持有者 | `WToast`（门面）+ `WToastStyle`（样式） |
| `WFormTextFieldConfig` / `WFormBorderConfig` / `WFormFieldStyle` | 同一 `Config` 后缀在 form 里既表示可变又表示不可变；`Style` 与 `Config` 混用 | 可变字段层改 `...Options`（或删）；不可变保留 `...Style` |
| `WImageConfig` / `WImageStyle` / `WImageLoader` / `WImageLoadState` | 视觉与加载职责混在 4 个类，31 个公开类型 | `WImageStyle`（视觉）+ `WImageLoadConfig`（加载） |
| `WFormDefaults` / `WFormTheme` / `WForm` 参数 | 同语义三种载体 | 只留 `WFormTheme` + `WFormIcons` |
| `label` / `message` / `hintTextList` | 三名都不符实：`label` 实际是占位符、`message` 是提示列表、`hintTextList` 兼承载 hint 与 error | `placeholder` / `helperText` / `messages` |
| `WFormFieldCleanup`（`field_lifecycle.dart`） | 类名与文件名不一致，存在本身是"字段是 StatelessWidget"的补偿 | 删 |
| `WFormFieldBaseConfig` | "Base"暗示模板方法，实际只是 8 个可变字段的容器 | 不可变 layout 值对象 |
| `WFormButton.onTap(String? value, ValueChanged<String> didChange)` | 第一个参数在上层被淹没，实际只需 `didChange` | 只留一个回调 |
| `IApiPath` | I 前缀是 Java 习惯 | 删除或 `ApiPath` |
| `DioRegistry` | 名字像注册表，实例其实是一个 Dio 包装 | `WDio` / `WDioRegistry.get(baseUrl)` |
| `WAsync.wait` / `any` / `sequence` / `runAllWithConcurrency` | 四个动词四种构词，`wait` 与 `Future.wait` 同名不同义 | `parallel` / `first` / `serial` / `pool` |
| `WListView` / `WListViewSliver` | 名字像两个组件，实际是同一列表的两种形态 | `WScrollView` + sliver 版，或只留 sliver |
| `WRowButtons` | 名字是"一排按钮"，行为是"分段选择" | `WActionRow` + `WSelectableRow` |
| `WQrViewState` / `WQrController` | 两者都能控相机 | 只留一个 |
| `WUx` | 不是类型名，是缩写口号 | 按能力拆名 |
| `WConfig` / `WApiConfig` / `WAppConfig` | 三个"配置"分别是 token 键名、网络、语言 | `WTokenKeys` / `WApiConfig` / `WLocaleConfig` |
| `--check` / `--check-drift` / `--check-stale` / `--if-stale` | 同一语义四种写法 | `--check[=missing\|drift\|stale]` |
| `WRowButtonsController` / `WNotificationListenerBuilder` / `WStepSemanticLabelBuilder` | 名后缀不是类型本身（不是 Widget 却叫 builder/listener） | 按实际类型命名，或做成 Widget |

## 6. 若不考虑兼容：重构方案

### 6.1 包边界（目标）

保持 9 个包不变（边界是对的），但允许三个有向依赖：

```text
core ──► ui ──► form
          ▲      ▲
          └── async
          └── toast
app（GetX，只依赖 flutter）      api（dio，只依赖 core）
qr / map（插件包装，不依赖任何 w_tools 包）
```

理由：form / async / toast 都是"带样式的控件"，视觉必须统一，而 ui 是唯一的样式真源。
若坚持"绝不互相依赖"，替代方案是给三者各加 `xxxTheme`（InheritedWidget）+ 样式注入点，
并禁止 `Color(0x…)` 字面量 —— 成本更高、一致性更差。

### 6.2 逐包动作

| 包 | 删除 | 合并 / 改短 | 新增 |
| --- | --- | --- | --- |
| core | `WConfig`、`WRegExpPattern`、`WRegExpPreset`、`escapeSql`、`stripHtml`、`hashPassword`、`WUx.smoothScroll*`（移 ui） | `WValidator` 全面改用 `WRegExp`；`WStorage` 读写语义统一；`WCountdown` → `ValueListenable` | `WTokenKeys`（若确需可配） |
| ui | 布局糖 4 类、`WClipRRect(Config)`、`WBadgeConfig`、`WImageFrame` 的 margin/padding 之一、`WImageStyleIO.buildFile`、`WImage.avatar/thumbnail/cover` 的替换式预设 | 按钮 10 文件 → `WButton` + `WButtonStyle`（+ theme 派生）；5 个必填 Config → 可选参数；图片 31 个公开类型 → 约 8 个 | `WButtonStyles.of(context)`；`WHexColor` |
| form | `WFormDefaults`、`WForm` 的 8 个图标参数、`*Core` 公开面、Config 的 `build()`、`WFormBorderConfigBuilder`、`withFormBorder`、`WFormBorderLayout`、`WFormFieldCleanup` | 13 个 border 类型 → `WFormBorderConfig` + `WFormBorderDecoration` + `WFormBorderTheme`；6 个字段三层 → 两层；图标收成 `WFormIcons` | `WFormIcons`；自有 `WFormKey`/values 类型（消除 FFB 泄漏） |
| async | `WAsyncConfig`、`WAsyncBuilder`、`WAsyncStateSliver` 死分支、重复默认文案 | `wait/any/sequence/runAllWithConcurrency` → `parallel/first/serial/pool`；两套 defaults → 一个 | `WAsyncController(config:)`；`WAsync.strings` |
| api | `BaseRepository`、`BaseLocalDataSource`、`BaseRemoteDataSource`、`IApiPath`、`ApiClientId` | 401 时序修正；`DioRegistry` 缓存冲突报错；日志 level 化并默认接 `WLogger` | 可选 `WApiClient`（registry + 拦截器 + 重试合成一个可注入对象） |
| app | `start()` 的 9 个参数、`WAppConfig.currentLanguage` 的公开 setter、`WRoute` 全局 list | `WAppConfig` → `WLocaleConfig`；`WBottomSheet.show` 透传参数 | `WToastPlugin` / `WScreenPlugin` / `WAsyncDefaultsPlugin` / `WFormIconsPlugin`（§7.3） |
| toast | `WToast.showText` 与 `WToastConfig.showText` 二选一；`dismissible` | `WToast`（门面）+ `WToastStyle`（不可变） | `WToastTheme`；success/error/warning 默认带图标且不吞点击 |
| qr | `WQrViewState.restartScan` 与 `WQrController` 二选一 | 默认值调整（`scanInterval` 400ms、`onError` 走 logger） | `WQrController.restartScan()`；overlay `==` |
| map | `WMapConfig.build()`、`onDataUpdated`（兼容字段） | 552 行拆 4 文件；`config` 可空；`maps` 私有 + `update()` 唯一入口；marker 按 id 复用 | `initialCamera`；`WMapItemMapper.fromItem` |
| cli | init 的 4 份 pubspec 解析、5 套文本扫描、init 内的路径硬编码 | 6 个 bin → 1 个 `w_tools <subcommand>`（旧入口薄壳）；`ProjectLayout`/`ProjectPubspec`/`SourceIndex`/`WorkspaceFileStore` | 统一 `--format`、退出码、JSON envelope；`check` 契约重定 |
| figma | `commands/{init,url,usage}` 薄层或 barrel 导出 | `package:args` 替换手写 parser；路径统一 `package:path` | `BudgetGuard`（fetch/diff 前置）；`--version` |
| device | `sips`/`image` 二选一；`_resolveUdid` 重复 | 平台适配收敛为 `PlatformAdapter`；标定 key 加尺寸/方向 | 进程超时；adb 转义；`--version` |
| e2e | — | — | `E2eLogin.completion` |

### 6.3 目标 API 形状（示意）

```dart
// async：一套入口，配置是参数
await WAsync.run(api.gifts, onSuccess: (l) => …);
final c = WAsyncController<List<Gift>>(api.gifts)..load();   // 内部复用 WAsync

// form：一层字段，配置可选且不可变；默认就能看到错误
WFormTextField(name: 'email', label: '邮箱', message: '请输入邮箱');

// ui：默认跟随主题
WButton(label: '保存');                                  // colorScheme.primary
WButton(label: '删除', style: WButtonStyle.danger(context));

// toast：门面 + 主题，成功提示不吞点击
WToast.success('已保存');

// cli：一个入口 + 统一输出
dart run w_tools_cli doctor --format json
```

### 6.4 代价与收益

| 项 | 估计 |
| --- | --- |
| 可净删代码 | 约 4,000–5,000 行（布局糖 172、`WAsyncConfig` ~300、form Config 层 ~900、ui 图片冗余构造 ~300、api 装饰类 ~50、cli 重复扫描/解析 ~300） |
| 公开类型 | 214 → 约 130（form 60→35、ui 89→60、async 18→14） |
| 破坏性 | 3~4 个子包升大版本 + 根包 `^` 约束同步；`release_check.sh` 会挡住漂移 |
| 风险 | 23k 行测试是安全网，但**必须先补 async / 工具包 CI**（P1-10）才能放心动 async |
| 不做会怎样 | 每加一个组件都要先决定"用哪种配置模型"；跨包视觉继续漂移；`WAsyncConfig` 每加特性写两遍；catalog/docs 继续漂移 |

## 7. 开发者易用性

### 7.1 不破坏 API 就能做的（建议先做）

1. **补 CI 矩阵**（P1-10）：`async` + 3 个工具包 —— 所有重构的前置条件。
2. **修默认值**（P1-1/2/3/5）：AppBar 的 `IconTheme.merge` 与标题回退、`WButtonStyles.of(context)`、
   `WImage.avatar` merge 预设、`WForm.borderConfig` 默认 `standard()` + `showBorderError=true`。
   四项都是小改动、有现成测试可写。
3. **日志默认接 `WLogger`**（P2-10）：`WApiConfig.logDebugHandler == null` 时走 `WLogger.d`，
   消费者不再需要"记得接两个 hook，否则日志静默消失"。
4. **`WLogger` 加输出 sink**：现在只能 print 到控制台，无法接 Sentry/Crashlytics；
   给一个 `WLogger.onLog(Level, String)` 即可（发布库必备）。顺带补 `measureAsync`
   （现在只有 `measureSync`，而 Flutter 里 async 更常用）。
5. **补 first-party `WAppPlugin`**（§7.3）。
6. **文档版本号**（P3-4）与 `check_docs.sh` 规则。
7. **`WForm` 加字段名唯一性早失败**（P1-6 第 3 点）：重名/空名在首帧就报，能省一类线上问题。

### 7.2 需要大版本的（放进 §6 一起做）

- 统一配置模型（不可变 + `copyWith` + `xxxStyle` 后缀）；
- 删 form 的 Config 层公开面与 `*Core`；
- `WApp` 单配置面；
- 让 form / toast / async 依赖 ui（或至少引入主题注入）。

### 7.3 建议补的"装配件"（当前最大的体验缺口）

`w_tools_app` 提供了插件系统，但**仓库内 0 个一等公民插件**（只有 example 和 test 里有）。
结果：消费方必须自己写 4~5 个插件，这套库才能"正常"工作：

| 必须做的事 | 现在谁做 | 建议 |
| --- | --- | --- |
| `BotToastInit()` + navigatorObserver | 消费方手写 `builderWrapper` | `WToastPlugin` |
| `BotToast` 之外，`WAsyncViewDefaults` 放根节点 | 消费方手写 `wrapApp` | `WAsyncDefaultsPlugin` |
| `WScreen.delegate*` 接 `ScreenUtil` | 消费方在 `ScreenUtilInit.builder` 里写 3 行 | `WScreenPlugin`（或 `WScreen.useScreenUtil()` 一行） |
| 表单 8 个图标 | 消费方静态赋值 `WFormDefaults` | 随 P2-28 由 `WFormTheme` 取代 |
| `WApiConfig.logDebugHandler = WLogger.d` | 消费方手写 | P2-10 默认值解决 |

## 8. 建议落地顺序

```text
阶段 0（本周，零破坏）
  ├─ CI 补 async + 3 个工具包                        → ci.yml
  ├─ 五个默认值修复（P1-1/2/3/5 + P1-4 或先撤文档）    → ui / form
  ├─ 401 并发用例（先红后绿）                          → api/test
  ├─ doctor --write-config 备份 + init --check 契约    → cli
  └─ 文档版本号 + check_docs 规则                      → docs

阶段 1（小版本，兼容）
  ├─ 日志默认接 WLogger + sink / measureAsync          → core / api
  ├─ 补 4 个 WAppPlugin                                → app / toast / async / ui
  ├─ WBottomSheet 透传、WLanguage 命名、WCountdown     → app / core
  ├─ form：WFormIcons、默认 borderConfig、弹层 handle   → form
  └─ figma：BudgetGuard 前置、Windows 路径、args 库      → figma

阶段 2（大版本，破坏性；按包独立发）
  ├─ core：删 WValidator 冗余正则 / WConfig / 危险 API
  ├─ async：删 WAsyncConfig，控制器接执行器，修命名
  ├─ ui：删布局糖、5 个必填 Config、图片收敛到 ~8 个类型
  ├─ form：删 Config 公开面 + *Core + FFB 泄漏
  ├─ api：删装饰基类，重试复用 Dio，日志 level 化
  └─ map / qr / toast：拆文件、收敛入口、修默认值

阶段 3（跨包）
  ├─ form / toast / async 依赖 ui，统一排版与按钮
  └─ catalog：YAML 生成 docs 表格 + g.dart，全别名校验
```

每阶段验证：`bash scripts/release_check.sh`（版本/CHANGELOG）、`dart analyze`（当前 1 info）、
逐包 `flutter test`、`bash scripts/check_docs.sh`、`bash scripts/check_feedback.sh`；
发版只用 `bash scripts/publish_package.sh <包目录>`。

## 9. 附录

### 9.1 需补测试 / 需维护者拍板

- **P1-8（401 竞态）**：从代码推演，未见"并发 401 且刷新已完成"的用例。改前先写用例。
- **P1-9（跨包样式）**：结论来自 `grep WText(`/`WButton(` 在 ui 之外 0 命中 + 硬编码色值；
  是否"必须"统一取决于维护者对"子包完全独立"的取舍，是产品决策。
- **P1-T1（init --check）**：现有测试**期望** `missing` 含 `init.json`，可能是有意设计；
  应重定契约而不是直接当 bug 修。
- **P2-25（barrel）**：`WImageLoader` 是否该公开，取决于是否有意提供受控加载入口。
- **a11y**：`WRowButtons` / `WNavBar` 的 `Semantics(button: true)` 没有 `onTap`，依赖子节点合并语义；
  与 `pressable.dart:138-146` 的显式写法不一致。建议真机 TalkBack/VoiceOver 验证后再定性。
- **P2-T13（figma 双层）**：若 `commands/` 是给库使用者的稳定 API 则不该删，需维护者确认定位。

### 9.2 本次评审的边界

- **没有运行 Flutter 测试**（本机 fvm 目录在沙箱外，`flutter` 无法写 engine stamp；
  `dart test` 因 telemetry 写 `~/.dart-tool` 被拒）。正确性结论均来自源码阅读 + `dart analyze`，
  标「推断」的条目未经运行验证。
- 一份并行评审对 form 的 config 层做过逐行核对，并注明"未跑测试、未逐行读 test/README/CHANGELOG"；
  tooling 评审注明 figma 的 `spec_renderer` / `token_renderer` / `spec_diff` 等格式化实现
  只核对了接口与调用点，未逐行审计。这两处若需定论应再补一轮。
- 行号基于 `38d54b0`，重构后会漂移；建议把本文当作"问题地图"，而不是逐行 patch 清单。
