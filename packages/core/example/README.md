# w_tools_core 示例

真实场景示例，覆盖：

- `WValidator.isValidEmail`
- `WHash.sha256`
- `WEncrypt.aesEncrypt` / `aesDecrypt`
- `WStorage.init` / `WToken`
- `WStorage.setInt` / `getInt`
- `WUx.debounce`
- `WCountdown`
- `WPlatform`

## 运行

```bash
cd packages/core/example
flutter pub get
flutter run
```

没有连接设备时：

```bash
flutter analyze
flutter test
```

## 页面

```text
邮箱 / 待处理文本
  校验邮箱
  哈希 + AES

token
  保存 token
  读取 token

防抖输入
  停止输入 300ms 后触发一次

计数
  计数 +1
  读取计数

倒计时
  开始 5 秒倒计时
```

## 说明

- `WStorage` / `WToken` 使用 SharedPreferences，是明文存储。
- `WEncrypt` 使用 AES-CBC，只提供机密性，不提供完整性。
- 测试使用 `SharedPreferences.setMockInitialValues({})`，不依赖真实设备存储。
