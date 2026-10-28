import 'package:flutter/material.dart';
import 'package:w_tools_ui/w_tools_ui.dart';

/// 一张 1×1 透明 PNG，用于演示 Base64 来源。
const _base64Demo = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 进程级缓存预算；占位符默认值交给 WImageTheme。
  WImageCachePolicy.configure(
    maxSize: 300,
    maxMemoryBytes: 300 * 1024 * 1024,
  );

  runApp(
    const WImageTheme(
      data: WImageThemeData(
        defaultPlaceholder: Center(child: CircularProgressIndicator()),
        defaultErrorWidget: Icon(Icons.broken_image),
      ),
      child: WImageExampleApp(),
    ),
  );
}

class WImageExampleApp extends StatelessWidget {
  const WImageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'w_tools_ui · WImage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WImageExamplePage(),
    );
  }
}

class WImageExamplePage extends StatefulWidget {
  const WImageExamplePage({super.key});

  @override
  State<WImageExamplePage> createState() => _WImageExamplePageState();
}

class _WImageExamplePageState extends State<WImageExamplePage> {
  late final WImageController _retryController;

  @override
  void initState() {
    super.initState();
    _retryController = WImageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WImage 示例')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('网络图 + 圆角 + 固定宽高比'),
          const SizedBox(height: 8),
          WImage.network(
            'https://picsum.photos/seed/wtools/640/360',
            style: const WImageStyle(
              aspectRatio: 16 / 9,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('本地资源（asset）'),
          const SizedBox(height: 8),
          WImage.asset(
            'assets/demo.png',
            prefix: false,
            style: const WImageStyle(
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Base64'),
          const SizedBox(height: 8),
          Row(
            children: [
              WImage.base64(
                _base64Demo,
                style: const WImageStyle(
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('裸 Base64 串，不需要 data:image/png;base64, 前缀'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('圆形头像'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: WImage(
              data: 'https://i.pravatar.cc/160?img=12',
              type: WImageType.network,
              style: const WImageStyle(
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.all(Radius.circular(36)),
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('进度 + 自动重试 + 手动重试'),
          const SizedBox(height: 8),
          WImage.network(
            'https://example.invalid/wtools-demo.jpg',
            controller: _retryController,
            style: WImageStyle(
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              retryCount: 2,
              retryDelay: 500,
              progressBuilder: (context, url, progress) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: progress.fraction),
                      const SizedBox(height: 8),
                      Text('${progress.fraction ?? 0}'),
                    ],
                  ),
                );
              },
              errorWidgetBuilder: (context, url, error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, size: 32),
                      const SizedBox(height: 8),
                      Text(error.message),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _retryController.retry,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              },
            ),
            onLoadStatusChanged: (status) {
              debugPrint('image status: $status');
            },
            onProgress: (progress) {
              debugPrint('image progress: ${progress.fraction}');
            },
          ),
          const SizedBox(height: 24),
          const _SectionTitle('预加载资源'),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final preloader = WImagePreloader();
              await preloader.preloadImage('assets/demo.png');
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('资源已预加载')),
              );
            },
            child: const Text('预加载 assets/demo.png'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
