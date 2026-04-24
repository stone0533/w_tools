## 1.0.6

- 修改了 WConfig 类，将 token 相关的键名从 const 改为私有变量 + 公共 getter 的形式
- 为 WConfig 类添加了 set 方法，用于设置 token 相关的键名，并且在已经赋值的情况下抛出异常
- 在 WConfigSetup 类中添加了对应的 setter 方法，以便通过链式调用设置这些键名
- 整理了 widget.dart 文件中的 withContainer 方法，修复了缩进并添加了文档注释
- 移除了 widget.dart 文件中不必要的导入
- 检查了 WListViewConfig 类的 copyWith 方法，确保所有属性都被正确复制

## 1.0.4

- 重构 WToastConfig 类，移除默认实现，使其更加灵活
- 将构建器中的 String 类型参数改为 Object? 类型，支持传递任意类型对象
- 移除 WToastConfig 中的静态方法，改为实例方法
- 优化加载状态管理，每个实例管理自己的加载状态
- 更新相关文档和示例

## 1.0.3

- 优化 WToastConfig 类，使其更加配置驱动
- 移除 WToastConfig 中的默认实现，让用户完全自定义 UI
- 更新相关文档和示例

## 1.0.2

- 优化了多个组件的配置类，添加了 copy 和 copyWith 方法
- 增强了 WFormMultiDropdown 组件，添加了更多自定义选项
- 优化了 WRichText 组件的性能
- 修复了多个组件中的小问题
- 更新了文档

## 1.0.1

- 修复了部分组件的文档注释
- 优化了部分组件的性能
- 更新了 README.md

## 1.0.0

- 初始版本发布
- 包含完整的组件库、工具类和扩展功能
- 支持配置驱动的开发模式
- 提供丰富的 UI 组件和实用工具