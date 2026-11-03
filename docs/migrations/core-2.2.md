# core 2.2 迁移：校验 / 正则 / 密码哈希

| 旧 | 新 | 说明 |
| --- | --- | --- |
| `WRegExpPattern.email` 等字符串常量 | `WRegExp.email`（`RegExp`） | 需要字符串形式时自行保存；`WRegExpPattern` / `WRegExpPreset` 3.0 移除 |
| `WRegExpPreset.personal` 等分类 Map | 按需维护自己的 Map，或直接用 `WRegExp` | 同上 |
| `WValidator.escapeSql` | 参数化查询 / 预编译语句 | 字符替换不能防注入，3.0 移除 |
| `WValidator.stripHtml` | HTML 转义或渲染器 | 正则剥标签不可靠，3.0 移除 |
| `WHash.hashPassword` / `verifyPassword` | 服务端 bcrypt / argon2 | 客户端 SHA-256 加盐不是密码哈希方案，3.0 移除 |

`WValidator` 的格式校验（邮箱 / 手机号 / 用户名 / 密码 / IPv4 / 身份证 / 银行卡）已全部改走
`WRegExp`，行为不变；`WRegExp` 新增 `username`。
