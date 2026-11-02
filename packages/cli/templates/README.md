# CLI 模板标记

`templates/` 是 `init` 生成内容的唯一来源；改完必须运行：

```bash
cd packages/cli
dart run tool/gen_templates.dart
```

## 可选能力

单行标记：

```html
<!-- @optional:qr -->
<!-- @optional:map -->
```

整行会在对应能力关闭时移除。

多行块：

```html
<!-- @optional:form:start -->
...
<!-- @optional:form:end -->
```

当前支持的能力：

```text
app / form / api / async / qr / map
```

`@optional:*` 标记只控制生成文本，不会出现在最终 AGENTS 里。
不要手工编辑 `lib/src/init/templates.g.dart`。
