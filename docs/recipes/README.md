# 组合用法（Recipes）

单包文档讲“这个类型怎么用”，这里讲“几件事怎么拼起来”。都使用当前 API，不引用弃用入口。

- [分页列表：刷新 + 追加 + 错误](paged-list.md)
- [分页列表测试：本地 harness + 标准边界](paged-list-test.md)
- [独立区块并行：不要让一个超时拖垮整页](parallel-sections.md)
- [App 根装配：主题 + 排版 + 全局提示](app-shell-theme.md)
- [表单提交：校验 + loading + 结果提示](form-submit.md)
- [Keep-alive / TickerMode 集成测试（参考示例）](keepalive-integration-test.md)
- [E2E 免登录入口](e2e-login.md)

> 单包最小用法见 [`docs/agents/<pkg>.md`](../agents/README.md)。
> 测试策略（白盒 / 黑盒）不属于组合场景，见 [`docs/guides/testing.md`](../guides/testing.md)。
> 设备冒烟脚本（Tab 型 App）见 [`packages/device/example/`](../../packages/device/example/README.md)，不在这里重复。
