# 设备上验证（模拟器 / 真机）

> 项目：`{{projectName}}`（Android applicationId：`{{androidAppId}}`）。
> 本文件由 `dart run w_tools_cli:init --device` 生成；把 `<...>` 换成实际值后再提交。
> 目的：让「保活 / 刷新策略 / 渲染」这类只有真实引擎才成立的验证**可重复执行**。

## 1. 固定设备与命令

| 设备 | UDID | 用途 |
| --- | --- | --- |
| <模拟器名称> | `<SIM_UDID>` | 日常自动化 |
| <真机名称> | `<DEVICE_UDID>` | 手感/真机差异（需解锁并信任） |

```bash
# 跑设备上的集成测试
flutter test integration_test -d <SIM_UDID>

# 起 App 并截图（模拟器无 GUI 窗口也能用）
flutter run -d <SIM_UDID>
xcrun simctl io <SIM_UDID> screenshot /tmp/shot.png
```

### 真机（物理设备）

```bash
dart run w_tools_device:device list --real                 # 列真机（wired = 数据线）
dart run w_tools_device:device shot --real --device=<名称>  # 截图（必须解锁，锁屏是全黑图）
flutter test integration_test -d <DEVICE_UDID>             # 跑集成测试（解锁 + 允许 Xcode 控制）
```

真机**点击不支持**（需 `idb ui tap` 或 XCUITest）——所以验证逻辑优先写进 `integration_test`。

### Android（可选，adb）

#### Gradle 镜像（JVM 到 dl.google.com 握手被拦时）

用 `docs/templates/gradle-mirror.init.gradle` 覆盖到 `~/.gradle/init.gradle`，
把 `google()`/`mavenCentral()` 换成 aliyun 镜像（只影响本机，不改项目配置）。

```bash
dart run w_tools_device:device list --android
dart run w_tools_device:device size --android          # 像素
dart run w_tools_device:device tap --android <x> <y>   # **截图像素**，不需要标定/cliclick
dart run w_tools_device:device verify --android <x> <y> --region=<像素区域>
dart run tool/device_smoke.dart --android --package={{androidAppId}}
```

> Xcode 27 起模拟器 GUI 是 **Device Hub**（`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`），
> `Simulator.app` 已移除；`simctl` 管脚本、`devicectl` 管真机。

## 2. 在 DeviceHub 里点模拟器（用 w_tools_device，不要手工标定）

```bash
dart pub add dev:w_tools_device
brew install cliclick        # 一次性
# 权限：辅助功能 + 屏幕录制，都要给「运行 agent 的宿主 App」
```

> `osascript ... click at` **点不到模拟器画面**（AX press 无效），必须 cliclick。

```bash
dart run w_tools_device:device list                  # 列模拟器（状态/运行时/UDID）
dart run w_tools_device:device boot "iPhone 17 Pro"
dart run w_tools_device:device shot --out=/tmp/a.png
dart run w_tools_device:device calibrate             # 自动标定（置前 DeviceHub + 遮挡检测）
dart run w_tools_device:device tap <x> <y>           # **设备坐标**（point），自动换算
dart run w_tools_device:device drag <x1> <y1> <x2> <y2>
dart run w_tools_device:device type "hello"
dart run w_tools_device:device wait                  # 等画面稳定
dart run w_tools_device:device verify <x> <y>        # 点一下并确认画面变了（坐标自检）
```

**推荐**：`verify` 加 `--region=x,y,w,h`（设备坐标），只看真正会变的区域，
避开 banner 轮播 / 列表自动刷新造成的假阳性：

```bash
# 例：只有标题区变化才算成功（切 tab 场景）
dart run w_tools_device:device verify 121 821 --region=0,40,402,80
```

退出码：`0` 成功 · `1` 参数/执行错误 · `2` `verify` 画面没变化（坐标可能失效）。

标定缓存：`~/.cache/w_tools_device/<udid>.json`，窗口位置/大小变了自动重算。

## 3. 写设备测试的坑

1. **`pumpAndSettle` 不能碰无限动画**（`CircularProgressIndicator` / `..repeat()`）→ 用 `pump(Duration)`；
2. 多个 `ListView` 共享 `PrimaryScrollController` 会抛错 → 每个列表独立 controller；
3. 不要在 `dispose()` 里才第一次初始化 `late final` 的 controller（会在 deactivated element 上建 ticker）；
4. TTL / 时间断言要真等（`DateTime.now()` + `Future.delayed`），`pump(时长)` 不推进墙钟；
5. 集成测试会跑 `pod install`，可能改写 `ios/Podfile.lock` / `project.pbxproj`（验证完 `git checkout`）。
6. **`verify` 默认比整屏指纹**：banner 轮播、列表自动刷新会让它误判 → 用 `--region` 只看会变的区域；
7. `bool.fromEnvironment('E2E')` **只认 "true"**，`--dart-define=E2E=1` 会得到 false
   （`w_tools_e2e` 已按字符串解析，自己写请照做）；
8. 登录成功后 `Get.offAllNamed` 可能**永不 resolve**：别 `await` 它，否则成功日志都打不出来；
   导航失败也不要判成「登录失败」。

## 4. 免登录入口（E2E 测试账号）

```bash
flutter run -d <SIM_UDID> -t tool/main_e2e.dart \
  --dart-define=E2E=1 \
  --dart-define=E2E_EMAIL=<账号> \
  --dart-define=E2E_PASSWORD=<密码>
```

实现建议（照本项目抄）：
- `lib/app/bootstrap.dart`：启动流程 + 可选 `afterStart` 钩子（生产入口传 null）
- `lib/main.dart`：`bootstrap()`，**不 import 任何测试包**
- `tool/main_e2e.dart`：`bootstrap(afterStart: ...)`，在这里调 `w_tools_e2e` 的 `E2eLogin.run`

生效条件：`E2E=1` + 账号密码非空 + 非 release。凭证不进仓库（编译期常量）。
若项目还没实现，参考 `lib/app/w/e2e.dart` 的写法（`E2eLogin.run()` + 启动后调用）。

## 5. 用日志验证刷新策略

```bash
n0=$(grep -c "<接口路径片段>" /tmp/run.log)
# 切走再切回（TTL 内）→ 计数不变；超过 TTL 再切回 → 计数增加
```

## 6. 新项目接入清单

一次性依赖：

```bash
dart pub add dev:w_tools_device dev:w_tools_e2e
brew install cliclick            # 点模拟器用
# 系统设置 → 隐私与安全性 → 给「运行 agent 的宿主 App」开：辅助功能 + 屏幕录制
```

- [ ] `integration_test/app_smoke_test.dart`（复制模板，一般不用改）
- [ ] 启动三件套：`lib/app/bootstrap.dart`（含 `afterStart` 钩子）/ `lib/main.dart`（只调 bootstrap）/
      `tool/main_e2e.dart`（在这里调 `E2eLogin.run`）
- [ ] 记录模拟器 / 真机 UDID 到本文件
- [ ] 真机自检：`device list --real` 能看到设备；`device shot --real` 出非全黑图
- [ ] 复制冒烟脚本 `docs/templates/tool/device_smoke.dart.tpl` → `tool/device_smoke.dart`

**iOS 自检**（需要 DeviceHub 打开 + 上面两个权限）：

```bash
dart run w_tools_device:device calibrate                 # 得到设备逻辑尺寸
dart run w_tools_device:device verify <tab_x> <tab_y> --region=<标题区>
# 期望：切 tab 时「画面有变化」exit 0；再点同 tab「无变化」exit 2
dart run tool/device_smoke.dart                          # 归位→逐 tab→回到 tab0→同 tab 应无变化
```

**真机自检**：

```bash
dart run w_tools_device:device list --real                # wired = 数据线
dart run w_tools_device:device shot --real --device=<名称> # 锁屏会给「几乎全黑」warning
flutter test integration_test -d <DEVICE_UDID>            # 解锁 + 允许 Xcode 控制
```

**Android 自检**（不需要 cliclick / 屏幕录制 / 标定，坐标就是像素）：

```bash
dart run w_tools_device:device list --android
dart run w_tools_device:device size --android              # 例如 1080x2340（px）
dart run w_tools_device:device shot --android --out=/tmp/a.png
dart run w_tools_device:device verify --android <x> <y> --region=<像素区域>
dart run tool/device_smoke.dart --android --package={{androidAppId}}
# 冒烟要求 App 已登录且在 tab 页：游客态点「会员卡」会跳登錄頁，后续 tab 就点不动

# 模拟器：无窗口启动即可；多设备时显式 --device
emulator -avd <AVD名> -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect
dart run tool/device_smoke.dart --android --device=emulator-5554 --package={{androidAppId}}
# 首次启动若弹通知权限框，先：adb shell pm grant <包名> android.permission.POST_NOTIFICATIONS
```

> JVM 到 `dl.google.com` 握手被拦（`curl` 能通、Java 不通）时，先按
> `docs/templates/gradle-mirror.init.gradle` 配镜像，否则 Android 构建会卡在下载依赖。

- [ ] 保留本文档第 3 节「坑」（通用），其余替换成项目信息
