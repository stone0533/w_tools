# ui 6.0 迁移预告：WImage 单入口

5.1.0 起旧入口标记 deprecated，6.0 移除：

```dart
// before
WImage.network(url, style: style)
WImage.asset('assets/logo.png')
WImage(data: 'https://x/y.png')

// after
WImage.source(source: WImageSource.network(url), style: style)
WImage.source(source: WImageSource.asset('assets/logo.png'))
WImage.source(source: WImageSource.parse('https://x/y.png'))
```

`WImage.source` 是唯一推荐入口；`WImageSource` 已覆盖网络/资源/文件/Base64/provider/memory。
