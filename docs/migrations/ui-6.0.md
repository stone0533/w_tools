# ui 6.0 迁移预告：WImage 单入口

6.0 已移除旧入口：

```dart
// before
WImage.source(source: WImageSource.network(url), style: style)
WImage.source(source: WImageSource.asset('assets/logo.png'))
WImage.source(source: WImageSource.parse('https://x/y.png'))

// after
WImage.source(source: WImageSource.network(url), style: style)
WImage.source(source: WImageSource.asset('assets/logo.png'))
WImage.source(source: WImageSource.parse('https://x/y.png'))
```

`WImage.source` 是唯一推荐入口；`WImageSource` 已覆盖网络/资源/文件/Base64/provider/memory。
