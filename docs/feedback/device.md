# w_tools_device 反馈

## 待处理






### [待处理] device: iOS 模拟器 tap/verify 坐标整体偏移 DeviceHub 窗口原点：点击落到空白处但仍报成功

- 包/版本：w_tools_device 0.4.0（本地检出 `packages/device`，pubspec_overrides 指向 `/Users/lei0533/flutter/github_w_tools/packages/device`）
- 环境：macOS 26（内置 1728×1117pt 主屏 + 3440×1440 外接屏）、Xcode 27 / Device Hub、cliclick 5.1、Dart 3.12.2；设备 iPhone 17 Pro（iOS 26.5 模拟器，DeviceHub 窗口在 (243,106)，872×1004）
- 命令 / 输入：`calibrate --json` + `tap 201 803 --json`（完整 JSON 见下）
  ```bash
  dart run w_tools_device:device calibrate --json --device=7665ACEB-E632-4D27-8138-80D002A54B8F
  # → deviceRect: x=395.392, y=145.77265671641794, w=333.216, h=724.4546865671641
  dart run w_tools_device:device tap 201 803 --json --device=7665ACEB-E632-4D27-8138-80D002A54B8F
  # → screen: {"x":562.0,"y":811.3757611940298}，exit 0
  ```
- 期望：`tap` 点在设备坐标 (201,803)（提醒事项欢迎页的「繼續」按钮中央），模拟器上按钮被按下、页面进入下一步。
- 实际：点击落在 DeviceHub 窗口的空白区域，模拟器画面完全没变，但命令返回 `ok:true` / `exit 0`，看起来像成功了。把同一目标手动点 (805,917)（= 命令给出的 screen 坐标 + 窗口原点 (243,106)）后按钮立刻被按下、页面进入「启用 iCloud 同步？」。
- 影响（我因此做错了什么 / 多花了什么）：iOS 模拟器的 tap / drag / verify 全部不可用，而且**静默**失败 —— 退出码 0、JSON 里看不出异常，冒烟脚本只会得到「画面没变化」，很容易误判成 App 卡住 / 坐标表过期 / 设备问题。0.3.x 时代的 `tool/device_smoke.dart` 在 iOS 上因此必然失败。
- 根因（读码定位）：`CalibrationDetector.detect` 用 `screencapture -R <window.x>,<window.y>,<w>,<h>` 截**窗口**（`device_hub.dart` 的 `capture`），得到的 bbox 是**窗口内**坐标（px），除以 scale 后仍是窗口局部坐标；但 `Calibration.toScreen`（`lib/src/calibration.dart:46-53`）在 a7ce8ef7「fix(device): tap 不再重复叠加 DeviceHub 窗口原点」里删掉了 `window.x/y +`，把 `deviceRect` 当成屏幕坐标用。实测对上：窗口截图里机身黑色连通域 bbox = 窗口内 (384,132,356,752)pt → 内缩 + 宽高比修正 = (395.39,143.39,333.22,724.46)pt，正是 `calibrate --json` 报的 `deviceRect`（y 差 2pt 来自降采样阈值），说明它确实是窗口局部坐标。
- 建议：`detect()` 里把 bbox 换算成屏幕坐标再加窗口原点（`DRect((rect.left/scale) + window.x, (rect.top/scale) + window.y, ...)`），或 `capture()` 改成整屏截图后再裁剪、保证坐标空间一致；同时把 `test/internal/calibration_test.dart:51-60` 的「回归 #145」期望值一起改掉（它现在把「少了 window.x/y」写成了期望）。建议补一条真实窗口位置（如 (243,106)）的端到端断言：`tap` 给出的 screen 坐标必须落在 `deviceRect` 内。
- 复现数据：挪窗口后 deviceRect 不变；窗口截图 bbox 与报出的 deviceRect 对得上（5 条见下）
  - 最直接的证据：把 DeviceHub 窗口从 (243,106) 挪到 (43,66) 后，`calibrate --json` 的 `window.x/y` 变了，`deviceRect` **一个数字都没变**（仍 `x=395.392,y=145.77`）—— 说明 `deviceRect` 是窗口局部坐标，而 `toScreen` 把它当屏幕坐标用；对 iPhone 17 和 iPhone 17 Pro 两台设备也给出完全相同的 `deviceRect`（工具没有核对窗口里显示的是哪台）。
  - `calibrate --json`：`window {x:243,y:106,w:872,h:1004,scale:2}`，`deviceRect {x:395.392,y:145.77265671641794,w:333.216,h:724.4546865671641}`，`screenshot {width:1206,height:2622,scale:3}`；
  - 窗口截图（`screencapture -x -R 243,106,872,1004`）里黑色机身 bbox 实测 = px (768,264,712,1504) → 窗口内 pt (384,132,356,752)；`395.392 = 384 + 11.392`（横向 inset），`333.216 = 356 - 2×11.392` —— 报出来的 `deviceRect` 就是这份**窗口内**矩形，没有加窗口原点 (243,106)；
  - 工具 `tap 201 803` → screen (562,811) 无反应；`cliclick c:805,917` → 按钮按下（截图对比：`/tmp/after_tool_tap.png` 未变、`/tmp/after_manual_tap.png` 变为 iCloud 同步弹窗）；
  - 手动点 `cliclick c:847,509` 打开「提醒事項」也证明 (deviceRect+窗口原点) 才是对的坐标空间；
  - 相关提交：`a7ce8ef7 fix(device): tap 不再重复叠加 DeviceHub 窗口原点`（0.3.3 引入，0.4.0 仍在）。
- 复验（2026-11-24，本地检出）：已修复。窗口 (21,89) 时 `calibrate --json` 的 `deviceRect` 回到 `x=416.392`（= 395.392+21）、`y=234.7727`（= 145.77+89），并新增 `windowTitle: "iPhone 17 – iOS 26.2"`；`tap 347 431` 真的打开了模拟器里的「设置」，`drag 200 700 200 300` 能滚动页面；`dart test` 114 条全过（含 #145 改为屏幕坐标、新增 iPad mini 用例）。
- 状态变更：2026-11-24 待处理

### [待处理] device: size 的 scaleSource 永远是 fallback：deviceType 标识符被当成目录名，iPad mini 报错 scale 与点尺寸

- 包/版本：w_tools_device 0.4.0（本地检出）
- 环境：macOS / Xcode 27（DeviceTypes 目录 133 个 `.simdevicetype`）；模拟器 iPhone 17（iOS 26.2）、iPhone 17 Pro（iOS 26.5）、iPad mini (A17 Pro)（iOS 26.4）
- 命令 / 输入：`size --json --device=EA613910…`（iPad mini (A17 Pro)）
  ```bash
  dart run w_tools_device:device size --json --device=EA613910-F2DF-42CB-8B19-C29C5C17B2B5   # iPad mini (A17 Pro)
  ```
- 期望：`size` 读出设备类型描述里的真实密度，输出 `scale: 2`、`width: 744`、`pixelWidth: 1488`、`scaleSource: "deviceType"`（README 说「读不到才回退并把 scaleSource 标成 fallback」）。
- 实际：
  ```json
  {"width":496,"height":755,"pixelWidth":1488,"pixelHeight":2266,"scale":3,"scaleSource":"fallback"}
  ```
  `scale` 算成 3（真实 2），`width/height` 跟着错成 496×755（真实 744×1133）；iPhone 17 / 17 Pro 也都是 `scaleSource:"fallback"`。
- 影响（我因此做错了什么 / 多花了什么）：0.4.0 的「密度不再需要 `--scale`」在真机上等于没生效，只是回退启发式恰好对 iPhone 蒙对（1206px→3、2064px→2）。iPad mini 这种 1488px 的机型会拿到错的 point 尺寸，任何按 `size` 算布局/比例的动作都会偏 1/3；如果后续把 `--region` 或点击换算接到 `size` 上，错得更隐蔽。
- 根因（读码定位）：`lib/src/simctl.dart` 的 `_deviceType()` 从 `device.plist` 读到的 `deviceType` 是标识符 `com.apple.CoreSimulator.SimDeviceType.iPhone-17`，`_metricsFromDeviceType()` 却直接拼 `$dir/$type.simdevicetype/Contents/Resources/capabilities.plist`；而 Xcode 27 的目录名是人类可读名（`iPhone 17.simdevicetype`、`iPad mini (A17 Pro).simdevicetype`），`com.apple.*.simdevicetype` 一个都不存在 → 永远走到 fallback。
- 建议：用 `xcrun simctl list devicetypes`（identifier ↔ name）或 `device.plist` 里的其它字段把标识符映射成目录名，再读 capabilities.plist；读不到时在 `--json` 里带上尝试过的路径，方便现场排查。另外 `test/cli_integration_test.dart:57-65` 的 fake `plutil` 用 `*"iPhone-17-Pro.simdevicetype"*` 匹配，正好掩盖了这个错误假设（真实目录名里有空格），建议改成按真实目录名造 fixture。
- 复现数据：DeviceTypes 目录、capabilities 值、三台模拟器输出（见下）
  - `ls /Library/Developer/CoreSimulator/Profiles/DeviceTypes | grep '^com.apple'` → 空；`ls -d /Library/Developer/CoreSimulator/Profiles/DeviceTypes/*.simdevicetype | wc -l` → 133，全部是 `iPhone 17.simdevicetype` 这种名字；
  - `plutil -p ".../iPad mini (A17 Pro).simdevicetype/Contents/Resources/capabilities.plist"` → `main-screen-scale => 2`、`main-screen-width => 1488`；
  - `size --json` 三台模拟器全是 `"scaleSource":"fallback"`（iPhone 17 / 17 Pro / iPad mini）；
  - `fallbackScale(1488)`（`simctl.dart:62`：`>=1536 || <1080 ? 2 : 3`）→ 3，与真实 2 不符。
- 二次复验（2026-11-24 10:47）：仍是 `scaleSource:"deviceType"`，且新增的 `scaleReason` 在成功路径不输出、只在回退时给出（`no-device-type` / `no-devicetypes` / `unknown-device-type` / `no-capabilities`），正好补上「卡在哪一步」的排障缺口；iPad mini 仍 744×1133 / scale 2。
- 复验（2026-11-24，本地检出）：已修复。`size` 改走 `simctl list devicetypes` 的 `bundlePath` → iPhone 17 报 `402×874 / scale 3 / scaleSource "deviceType"`；iPad mini (A17 Pro) 报 `744×1133 / scale 2 / deviceType`（原来 496×755 / 3 / fallback）。
- 状态变更：2026-11-24 待处理

### [待处理] device: --region 改成截图像素后，按 point 写的 device_smoke 假失败，缺迁移指引

- 包/版本：w_tools_device 0.4.0（本地检出）；项目 ureward_member_app 的 `tool/device_smoke.dart`
- 环境：macOS / Xcode 27 / iPhone 17 模拟器（1206×2622 px，402×874 pt）
- 命令 / 输入：`verify 121 821 --region=0,35,402,70`（旧 smoke 的 point region）
  ```bash
  # 项目 smoke 里的写法：region 由 calibrate 的 device.width/height（point）算出来
  #   region = 0,35,402,70   y = 821（tab 栏）
  dart run w_tools_device:device verify 121 821 --region=0,35,402,70
  ```
- 期望：0.4.0 明确 `--region` 是**截图像素**，所以按 point 算出来的 `0,35,402,70` 应该被当成「截图左上角 402×70 px 的一条」，或者工具能提示单位不对；升级文档应给出「把 region 乘 screenshot.scale」的迁移片段。
- 实际：这个 region 会被当成「设备截图左上角 402×70 px」（状态栏/刘海一带）——设备截图是 1206×2622 px，宽度只覆盖 1/3 屏，点 tab 时那一带不会变，于是 `changed:false`、`exit 1`，冒烟报「tab 点不动」。项目里按旧语义写的 `tool/device_smoke.dart`（`region = 0,${h*0.04},${w},${h*0.08}`，h/w 来自 `calibrate.device`，单位 point）在 0.4.0 下必然假失败。
- 备注：0.4.0 目前还有「tap 坐标整体偏移窗口原点」的问题（另条反馈，现象是点击静默无效），所以本机没能用一次点击同时证明 region 单位；region 单位结论来自代码与文档：`_fingerprint` 对设备截图（1206 px 宽）按 region 取像素，402 宽的 region 只覆盖左 1/3。
- 影响（我因此做错了什么 / 多花了什么）：升级到 0.4.0 后 iOS 冒烟直接红，现象是「坐标失效 / tab 点不到」，排查方向会被引到标定和 App 上，而不是 region 单位。`--region` 从 point 改成 px 是破坏性变更，但 CHANGELOG 没写迁移动作，包内又删掉了 `example/tool/device_smoke.dart`（原来各项目就是抄这份），于是各项目的脚本停在旧语义上。
- 建议：任选其一 —— ①`--region` 增加 `--region-space=px|point`（iOS 默认沿用 point 更兼容）；②CHANGELOG + README 给一段迁移片段（`region_px = [x*s, y*s, w*s, h*s]`，`s = calibrate.screenshot.scale`）；③`verify`/`wait` 在 region 超出截图时会「明显偏小」的尺寸上给 warning（例如 region 宽 < 截图宽 30% 时提示单位可能是 point）。
- 复现数据：README 示例、项目 smoke 写法、实测退出码（见下）
  - `packages/device/README.md:38` 自己的示例是 `verify 200 840 --region=0,40,402,80`（402 = 设备 point 宽），而同文件 `:45` 又写「截图 / --region = 截图像素」—— README 内部就矛盾；`docs/agents/device-testing.md:57` 抄的也是这个 point 尺寸示例；
  - 本项目 `tool/device_smoke.dart` 的 `_runIos`：`final region = '0,${(h * 0.04).round()},${w.round()},${(h * 0.08).round()}';`，`w/h` 来自 `calibrate.device`（point）；
  - 实测冒烟（DeviceHub 窗口 (21,89)、单台 booted iPhone 17）：`dart run tool/device_smoke.dart --tabs=4` → `✔ list`、`✔ calibrate {402 x 874}`、`✔ tab 1 changed:true`，到 `✘ tab 2` 时 `verify 251 822 --region=0,35,402,70` 返回 `changed:false`（exit 1）—— region 只有状态栏那一条，tab 切换不会经过它；
  - 实测（受上面坐标问题限制，仅作参考）：`verify 40 821 --region=0,35,402,70` → `{"changed":false}` exit 1；`verify 121 821 --region=0,105,1206,210` → `changed:true` exit 0。
- 二次复验（2026-11-24 10:47）：`verify`/`wait` 的 JSON 现在同时给 `region`（输入坐标）与 `regionPixels`（实际比较的截图 px），实测 `0,0,402,400` → `0,0,1206,1200`（×3），单位换算可以直接看出来；`verify 241 477 --region=0,0,402,400` 点「登入」→ `changed:true` exit 0。
- 复验（2026-11-24，本地检出）：已修复。`--region` 改回「与 tap 同坐标系」（iOS = 设备 point），README `:45` / `:83` 与 CHANGELOG 同步；`verify 200 347 --region=0,40,402,80` 点「通用」→ `changed:true` exit 0，原地再点一次 → `changed:false` exit 1；`wait --region=0,40,402,80` 正常。
- 状态变更：2026-11-24 待处理

### [待处理] device: list --real --json 的 transport 输出字符串 "null"、bootState 为空，shot --real 报错带空括号

- 包/版本：w_tools_device 0.4.0（本地检出）
- 环境：macOS / Xcode 27；真机 iPhone 12（UDID 00008101-001145823411001E，当前 unavailable）+ iPad Air 11-inch (M2)（网络配对）
- 命令 / 输入：`list --real --json` + `shot --real --device=… --json`（输出见下）
  ```bash
  dart run w_tools_device:device list --real --json
  dart run w_tools_device:device shot --real --device=00008101-001145823411001E --out=/tmp/a.png --json
  ```
- 期望：`--json` 里字段类型稳定；devicectl 没给 `transportType` / `bootState` 时，要么省略该字段，要么给 `null`——不要输出字符串 `"null"`；`shot --real` 失败时给出能看懂的原因（设备离线 / 未解锁 / 未信任）。
- 实际：
  ```json
  {"udid":"00008101-001145823411001E","name":"Lei0533的iPhone","osVersion":"27.0","bootState":"","transport":"null","paired":true}
  ```
  `transport` 是字符串 `"null"`（`real_device.dart:84` 用 `'${conn['transportType']}'` 拼，缺字段就成了 "null"）；`bootState` 是空串。紧接着 `shot --real` 报错：
  ```
  真机未启动/未解锁：Lei0533的iPhone ()   （exit 3）
  ```
  括号里空的，就是因为 bootState 为空 —— 看不出到底是「没连上」「没解锁」还是「没信任」。
- 影响（我因此做错了什么 / 多花了什么）：脚本里 `d['transport'] == 'sameMachine'` 之类的判断在字符串 "null" 上永远不成立/永远成立都要小心；人工读列表时 `transport=null`、`bootState=` 都是噪音，且排障时拿不到可用信息（实际这台机器 devicectl 报的是 `State: unavailable`，工具只说「未启动/未解锁」）。
- 建议：`list --real` 用 `devicectl` 的 state/unavailable 原因（`connectionProperties.tunnelState`、屏幕外的 `deviceProperties`）映射成一句人话；缺字段时 JSON 里省略而不是写 `"null"`；`shot --real` 的错误文案带上 `state` 原文，例如「真机不可用（devicectl state=unavailable）：请确认已解锁并信任这台电脑」。
- 复现数据：devicectl 原文与工具输出（见下）
  - `xcrun devicectl list devices` → `Lei0533的iPhone … State: unavailable`；
  - `xcrun devicectl list devices --json-output` → 该设备 `hardwareProperties.bootState`、`connectionProperties.transportType` 均缺失，`connectionProperties.tunnelState = 'unavailable'`；
  - 工具输出见上（`transport: "null"`、`bootState: ""`、报错里的空括号）。
- 复验（2026-11-24，本地检出）：已修复。`list --real --json` 现在输出 `state: "booted" / "unavailable"`，devicectl 没给的字段直接省略（`transport` 不再出现 `"null"`）；文本表头连接列给 `-`；`shot --real` 对未启动设备报「真机不可用（state=unavailable）：请确认已连接、解锁并信任本机（磊张的iPad / 00008020-001235DA3C89002E）」。
- 状态变更：2026-11-24 待处理

### [待处理] device: Device Hub 窗口显示的不是目标设备时会静默点错设备，却报「被其它窗口遮挡」

- 包/版本：w_tools_device 0.4.0（本地检出）
- 环境：macOS / Xcode 27 / Device Hub；同时 booted 两台：iPhone 17（iOS 26.2，7A271930…）与 iPhone 17 Pro（iOS 26.5，7665ACEB…）；Device Hub 窗口标题为 `iPhone 17 Pro – iOS 26.5`
- 命令 / 输入：`calibrate --device=<17>` / `calibrate --json`（A / B 见下）
  ```bash
  # A. 目标设备与窗口里显示的设备不一致（窗口显示 17 Pro，命令却指定 17）
  dart run w_tools_device:device calibrate --device=7A271930-CA20-41B2-9360-8D29DB42012A --json
  # B. 窗口里选中的是一台已关机的设备（只显示机模 + Start 按钮）
  dart run w_tools_device:device calibrate --json
  ```
- 期望：A 应报错「Device Hub 当前显示的是 iPhone 17 Pro，与 --device 指定的 iPhone 17 不一致，请先在 Device Hub 里选中目标设备」；B 应报「Device Hub 里选的设备没启动 / 没有实时预览」，而不是把原因归到「被其它窗口遮挡」。
- 实际：A 返回 `ok:true`、`exit 0`，`deviceRect` 与指定 17 Pro 时完全相同（说明它标定的是窗口里显示的那台，而不是 `--device` 指定的那台），后续 tap 会点到另一台设备上，且 JSON 里 `deviceId` 仍写目标设备 —— 静默点错设备。B 报的是：
  ```
  设备预览可能被其它窗口遮挡（只识别到 4px 高）。请把 DeviceHub 窗口置于最前再试。  （exit 3）
  ```
  但当时 Device Hub 明明在最前，只是窗口里选中的设备是关着的（显示 Start 占位）。反复重试、把窗口置前都无效，按提示排查方向是错的。
- 影响（我因此做错了什么 / 多花了什么）：多设备（两个模拟器都 booted）时，标定/点击会静默落到 Device Hub 显示的那台，`--device` 形同虚设；而「窗口不是目标设备」这个原因被误报成遮挡，我在这个提示上折腾了好几轮（重试 drag、重新 activate、怀疑屏幕录制权限），实际只需要在 Device Hub 里换选中项。
- 建议：`_calibrate` 里顺手读一下窗口标题（`tell application "System Events" to tell process "DeviceHub" to get name of window 1` 已经能拿到 `iPhone 17 Pro – iOS 26.5`，同一条 osascript 通道，不用新依赖），与 `_resolveSim` 解析出的 `name + runtime` 比对；不一致就报专门错误。识别到「机身高度明显偏小」时，把提示改成两种可能：「① 窗口被遮挡；② Device Hub 里选中的设备已关机 / 不是目标设备（当前窗口：<标题>）」，并给出窗口标题。
- 复现数据：deviceRect 相同、窗口标题、选中项 plist（见下）
  - `calibrate --device=7A271930…` 与 `--device=7665ACEB…` 的 `deviceRect` 完全一致：`x=395.392,y=145.77265671641794,w=333.216,h=724.4546865671641`；
  - 窗口标题：`osascript -e 'tell application "System Events" to tell process "DeviceHub" to get name of window 1'` → `iPhone 17 Pro – iOS 26.5`；
  - Device Hub 选中项在 `~/Library/Preferences/com.apple.dt.Devices.plist` 的 `lastSelectedDeviceIdentifier`（= 7665ACEB…），与 booted 的 iPhone 17（7A271930…）不同；
  - 报错文案出处：`lib/src/calibration.dart:146-151`（`_minDeviceHeightRatio` 分支）。
- 二次复验（2026-11-24 10:50）：两台模拟器同时 booted（iPhone 17 / 17 Pro）、Device Hub 显示 17 时，`calibrate --device=<17 Pro>` 与 `tap --device=<17 Pro>` 都稳定 exit 3 并给出上面的文案，没有误点。
- 复验（2026-11-24，本地检出）：已修复。Device Hub 显示 iPhone 17、命令指定 17 Pro 时，`calibrate` 与 `tap` 都报「Device Hub 当前显示的是「iPhone 17 – iOS 26.2」，与 --device 指定的「iPhone 17 Pro」不一致；请先在 Device Hub 里选中目标设备后重试。」exit 3；`calibrate --json` 新增 `windowTitle`；「只识别到 Npx 高」的提示已列出「窗口被遮挡 / 选中设备已关机」两种原因并附窗口标题。
- 状态变更：2026-11-24 待处理

### [待处理] device: 宿主左键被留在按下状态时 tap/verify 全部静默失效，没有任何提示

- 包/版本：w_tools_device 0.4.0（本地检出，含 `regionPixels` / `scaleReason` 的最新版本）
- 环境：macOS 26（双屏）、Xcode 27 / Device Hub、cliclick 5.1（brew stable）、iPhone 17 模拟器（iOS 26.2）
- 命令 / 输入：`tap 347 431 --json` / `verify 241 477 --region=0,0,402,400 --json`（排查命令见下）
  ```bash
  dart run w_tools_device:device tap 347 431 --json        # 点模拟器桌面上的 uReward 图标
  dart run w_tools_device:device verify 241 477 --region=0,0,402,400 --json
  # 排查用：查宿主左键状态（CGEventSource）
  swift -e 'import CoreGraphics; print(CGEventSource.buttonState(.hidSystemState, button: .left))'
  cliclick du:690,590    # 释放
  ```
- 期望：当宿主环境的左键被留在「按下」状态时，`tap` / `verify` 的失败信息里能提示这一点；`drag` 结束后顺手补一次幂等的 `du:`（按下状态是全局的，残留会让后续所有点击静默失效）。
- 实际：`tap` 全部无效但 `ok:true` / `exit 0`（`verify` 只是 `changed:false`）；模拟器桌面被「点」进抖动模式（说明事件被当成**长按**）。此时 `CGEventSource.buttonState(.hidSystemState, .left)` 一直是 `true`；执行 `cliclick du:x` 释放后，同一个 `tap` 立刻恢复正常（打开了 uReward），`verify` 也立刻能拿到 `changed:true`。
- 影响（我因此做错了什么 / 多花了什么）：花了约 15 分钟，先把怀疑放在「标定又偏了 / 窗口原点又没加 / region 单位」，反复对 `deviceRect` 与窗口截图做像素级比对（坐标其实完全正确）；最后靠 `CGEventSource.buttonState` 才定位到是环境层面的左键卡住。任何残留（例如宿主自己调过 `cliclick dd:` 没释放、或外部工具/脚本中断）都会让后续 `tap` 静默失效，而工具输出看起来一切正常。
- 建议：①`verify` 没变化时，错误/提示里补一条排查项「若所有点击都无效，先释放宿主鼠标左键：`cliclick du:<x>,<y>`」；②`drag` 结束（含异常路径）补一次幂等 `cliclick du:<x>,<y>`；③可选：`tap` 前后读一次 `CGEventSource.buttonState`（走一个 10 行的 swift 脚本或 AFK 小工具），发现左键按下就先 `du:` 再点。
- 复现数据：卡住时的按钮状态 / 释放后的对照与截图（见下）
  - 卡住时：`swift btn.swift` → `combined=true hid=true`；`tap` → `{"ok":true,"exit":0}` 但模拟器画面不变；`verify` → `changed:false`（`regionPixels` 换算正确，`region 0,0,402,400 → 0,0,1206,1200`）；
  - `cliclick du:690,590` 后：`combined=false hid=false`；随后 `tap 347 431` 打开 uReward、`verify 241 477 --region=0,0,402,400` 点「登入」→ `changed:true` exit 0；
  - 抖动模式截图：桌面出现「編輯 / 完成」与减号角标（长按的典型结果）；
  - 顺带确认：`cliclick dd:/dm:/du:` 组成的 `drag` 本身结束后状态是 `false`，残留主要来自「按下后进程被杀 / 手工 dd 未释放」这类中断。
- 状态变更：2026-11-24 待处理

## 已闭环

| 日期 | 问题 | 结果 |
| --- | --- | --- |
| 2026-11-03 | 设备预览被其它窗口遮挡时，标定算出错误坐标（不报错） | ✅ 0.1.0：先 `activate` DeviceHub；识别高度明显偏小直接报「被遮挡」 |
| 2026-11-03 | `shot --real` 锁屏时返回全黑 PNG，退出码 0 | ✅ 0.1.0：`ScreenStats.isMostlyDark` 检测并给 warning |
| 2026-11-03 | 多设备（真机 + 模拟器）时 `verify` 未透传 `--device`，点到另一台 | ✅ 0.1.1：`--device` 全链路透传 |
| 2026-11-03 | Android 首次启动弹通知权限框，`foreground` 校验失败但没有说明 | ✅ 0.1.0：冒烟要求 `--package` 并提示先 `pm grant`（文档已写） |
