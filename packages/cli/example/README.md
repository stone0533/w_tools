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
bash example/run_demo.sh
```

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
  w_tools_core: ^2.0.0
```

`init --profile=minimal` 会生成：

```text
lib/app/w/toolkit.dart
.w_tools_doctor.yaml
```

`doctor` 应该通过。

## 为什么不是 Flutter example

`w_tools_cli` 是纯 Dart 工具，作用于消费方项目；它没有可运行的页面。

真正的验证在：

```text
packages/cli/test/cli_test.dart
```

本目录只提供可读、可复现的命令示例。
