# WImage golden baselines

这些基线由 `packages/ui` 的 `test/image_golden_test.dart` 生成，当前在 **macOS / Flutter 3.38.4** 上生成。

## 重新生成

```bash
cd packages/ui
flutter test --update-goldens test/image_golden_test.dart
```

## CI / 跨平台

当前 `image_golden_test.dart` 通过 `defaultTargetPlatform == TargetPlatform.macOS` 仅在 macOS 运行 golden；
其它平台自动 skip，避免用 macOS 基线误判 Linux/Windows。

- 在对应平台重新执行上面的命令生成基线并提交；
- 或只在一个平台跑 golden，其它平台只跑结构测试；
- 不要手工编辑 PNG。

用例只使用纯色块、圆角与简单的 `Icon`/文字，尽量降低字体差异；新增 golden 时也请保持这个原则。
