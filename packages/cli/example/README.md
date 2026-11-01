# w_tools_cli 示例

CLI 不是 Flutter App。示例以命令演示一个最小消费方项目的接入流程。

## 直接看命令

```bash
# 查组件
dart run w_tools_cli:list 下拉
dart run w_tools_cli:explain WForm

# 看项目事实
dart run w_tools_cli:context --format=prompt

# 初始化项目
dart run w_tools_cli:init --profile=minimal --no-ui --no-instructions

# 检查项目
dart run w_tools_cli:doctor --format=markdown
```

## 可复现 demo

```bash
cd packages/cli
dart pub get
bash example/run_demo.sh
```

脚本在缺少 `.dart_tool` 时也会自动执行 `dart pub get`。

Windows 请使用 Git Bash 或 WSL；`dart test` 在 Windows 上会跳过依赖 bash 的示例测试。

脚本会：

```text
复制 demo_project 到临时目录
执行 init
执行 doctor
执行 context
执行 list / explain
退出时清理临时目录
```

不会修改仓库，也不会提交 `init` 生成物。

## demo_project

```text
example/demo_project/
  pubspec.yaml
```

只包含：

```yaml
name: demo_app
dependencies:
  w_tools_core: any
```

`demo_project` 只用于 CLI 解析，不保证独立 `dart pub get`；核心目的是复现 `init` / `doctor` / `context` 流程。

`init --profile=minimal` 会生成：

```text
lib/app/w/toolkit.dart
.w_tools_doctor.yaml
```

随后脚本执行同参数的 `init --check-drift`，确认生成物与模板一致；`doctor` 应通过。

`demo_project` 里的 `w_tools_core: any` 只用于解析，不代表真实项目的锁定版本；真实项目请以 `init` 输出的版本片段为准。

## 为什么不是 Flutter example

`w_tools_cli` 是纯 Dart 工具，作用于消费方项目；它没有可运行的页面。

真正的验证在：

```text
packages/cli/test/cli_test.dart
```

本目录只提供可读、可复现的命令示例。
