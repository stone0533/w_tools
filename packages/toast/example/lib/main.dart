import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:w_tools_toast/w_tools_toast.dart';

void main() {
  runApp(
    WToastTheme(
      style: WToastStyle.defaults.copyWith(
        duration: const Duration(seconds: 2),
      ),
      child: MaterialApp(
        title: 'w_tools_toast 示例',
        // BotToast 必须在 MaterialApp 里初始化，否则所有入口都会走 onError。
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: const _HomePage(),
      ),
    ),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  Future<void> _runLoading(BuildContext context) async {
    await WToast.runWithLoading(
      () async => Future<void>.delayed(const Duration(milliseconds: 600)),
      message: '保存中...',
      successMessage: '保存成功',
      errorMessage: (error) => '保存失败：$error',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('w_tools_toast 示例')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () => WToast.showSuccess('保存成功', context: context),
            child: const Text('成功'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => WToast.showError('网络异常', context: context),
            child: const Text('错误'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => WToast.showWarning('只读模式', context: context),
            child: const Text('警告'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => WToast.showText(text: '纯文本提示'),
            child: const Text('文本'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => WToast.showCustom(
              toastBuilder: (cancel) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text('自定义内容'),
                  IconButton(onPressed: cancel, icon: const Icon(Icons.close, size: 16)),
                ],
              ),
              context: context,
            ),
            child: const Text('自定义'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _runLoading(context),
            child: const Text('loading + 结果提示'),
          ),
          const SizedBox(height: 12),
          const OutlinedButton(
            onPressed: WToast.hideAll,
            child: Text('关闭全部'),
          ),
        ],
      ),
    );
  }
}
