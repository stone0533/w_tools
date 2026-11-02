- **基础工具**：`WStorage` 读取前先 `await WStorage.init()`；`WStorage` / `WToken`
  是明文存储。`WValidator` 做业务语义校验，纯正则用 `WRegExp`；日志用 `WLogger`。
