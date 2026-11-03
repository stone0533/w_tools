export 'src/components.dart';

// 公开依赖：`WFormController.formKey` / `fields` 的静态类型来自
// flutter_form_builder，自定义字段也需要它的基类。这里显式导出，
// 消费方不必再自己声明同版本依赖。
export 'package:flutter_form_builder/flutter_form_builder.dart'
    show FormBuilderField, FormBuilderFieldState, FormBuilderFields, FormBuilderState;
