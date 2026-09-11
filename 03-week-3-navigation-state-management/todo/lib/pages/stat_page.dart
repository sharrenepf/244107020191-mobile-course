import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget digunakan agar halaman dapat membaca
// dan merespons perubahan state dari Riverpod.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch digunakan untuk memantau perubahan state
    // dari statsProvider.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),

      // AsyncValue.when menangani tiga kondisi:
      // loading, error, dan data.
      body: statsAsync.when(
        // Kondisi ketika data sedang dimuat.
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Kondisi ketika terjadi error.
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),

              const SizedBox(height: 12),

              // Tombol untuk mencoba mengambil data kembali.
              FilledButton(
                onPressed: () {
                  // ref.read digunakan di dalam callback tombol.
                  ref.read(statsProvider.notifier).retry();
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),

        // Kondisi ketika data berhasil diperoleh.
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(stats[index]),
            );
          },
        ),
      ),
    );
  }
}