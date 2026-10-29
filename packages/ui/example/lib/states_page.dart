import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

const _pixelBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class StatesPage extends StatelessWidget {
  const StatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('加载成功'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage(
            data: 'data:image/png;base64,$_pixelBase64',
            style: const WImageStyle(width: 160, height: 90, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('加载失败（自定义错误占位）'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage(
            data: 'data:image/png;base64,@@invalid@@',
            style: const WImageStyle(width: 160, height: 90),
            config: const WImageConfig(
              errorWidget: ColoredBox(
                color: Color(0xFFFFEBEE),
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('空数据'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage(
            data: '',
            style: const WImageStyle(width: 160, height: 90),
            config: const WImageConfig(
              errorWidget: ColoredBox(
                color: Color(0xFFFFF3E0),
                child: Center(child: Icon(Icons.image_not_supported_outlined)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('加载中（placeholder）'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage.network(
            'https://example.invalid/loading.png',
            style: const WImageStyle(width: 160, height: 90),
            config: const WImageConfig(
              placeholder: ColoredBox(
                color: Color(0xFFE8EAF6),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: ColoredBox(
                color: Color(0xFFFFEBEE),
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('主题默认错误占位'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage(
            data: 'data:image/png;base64,@@invalid@@',
            style: const WImageStyle(width: 160, height: 90),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('预加载'),
        const SizedBox(height: 8),
        Center(
          child: FilledButton.tonal(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await WImagePreloader().preloadImage('assets/demo.png');
              if (!context.mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('assets/demo.png 已预加载')),
              );
            },
            child: const Text('预加载 assets/demo.png'),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Web 上的 file://（其它平台为文件错误）'),
        const SizedBox(height: 8),
        _StateCard(
          child: WImage(
            data: 'file:///definitely/not/here.png',
            type: WImageType.file,
            style: const WImageStyle(width: 160, height: 90),
            config: const WImageConfig(
              errorWidget: ColoredBox(
                color: Color(0xFFE0F2F1),
                child: Center(child: Icon(Icons.folder_off_outlined)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }
}
