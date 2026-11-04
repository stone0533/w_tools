> 迁移记录：只描述从旧版本升级的步骤，不代表当前公开 API。

# ui 6.0 迁移：WImage 单入口

6.0 已删除所有旧构造器与 String 图片扩展。

## 旧写法

```dart
WImage.network(url, style: style)
WImage.asset('assets/logo.png')
WImage.file('/tmp/a.png')
WImage.base64(data)
WImage(data: 'https://x/y.png')
WImage.memory(bytes)
WImage.provider(provider)

'https://x/y.png'.toImage()
'logo.png'.toAssetImage()
```

## 新写法

```dart
WImage.source(source: WImageSource.network(url), style: style)
WImage.source(source: WImageSource.asset('assets/logo.png'))
WImage.source(source: WImageSource.file('/tmp/a.png'))
WImage.source(source: WImageSource.base64(data))
WImage.source(source: WImageSource.parse('https://x/y.png'))
WImage.source(source: WImageSource.provider(MemoryImage(bytes)))
WImage.source(source: WImageSource.provider(provider))
```

`WImage.source` 是唯一入口；`WImageSource` 覆盖网络 / 资源 / 文件 / Base64 / 任意 provider。
