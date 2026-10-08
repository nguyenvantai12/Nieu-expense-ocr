import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/scan_flow_provider.dart';

class ScanFlowScreen extends ConsumerWidget {
  const ScanFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanFlowProvider);

    // Listen for state changes to navigate
    ref.listen<ScanFlowState>(scanFlowProvider, (prev, next) {
      if (next is ScanReviewing) {
        context.go('/scan/review');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(scanFlowProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(context, ref, scanState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ScanFlowState state) {
    return switch (state) {
      ScanIdle() => _buildSourceSelection(context, ref),
      ScanCapturing() => const _ScanProgress(
        message: 'Đang mở camera hoặc thư viện...',
      ),
      ScanRecognizing() => const _ScanProgress(
        message: 'Đang nhận diện chữ trên hóa đơn...',
      ),
      ScanParsing() => const _ScanProgress(
        message: 'Đang phân tích thông tin hóa đơn...',
      ),
      ScanReviewing() => const _ScanProgress(
        message: 'Đang mở màn hình xác nhận...',
      ),
      ScanSaving() => const _ScanProgress(message: 'Đang lưu chi tiêu...'),
      ScanSuccess() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text('Đã lưu thành công!'),
          ],
        ),
      ),
      ScanError(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(scanFlowProvider.notifier).reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    };
  }

  Widget _buildSourceSelection(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Chọn nguồn ảnh hóa đơn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(scanFlowProvider.notifier).captureFromCamera(),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(scanFlowProvider.notifier).pickFromGallery(),
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn từ thư viện'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanProgress extends StatelessWidget {
  const _ScanProgress({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
