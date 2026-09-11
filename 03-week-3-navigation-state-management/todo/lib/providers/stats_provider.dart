import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef StatsFetcher = Future<List<String>> Function();

final statsFetcherProvider = Provider<StatsFetcher>((ref) {
  return () async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final isFailure = random.nextDouble() < 0.3;

    if (isFailure) {
      throw Exception(
        'Gagal mengambil data statistik dari server',
      );
    }

    return [
      'Total pengguna: 1.245',
      'Total transaksi: 389',
      'Rata-rata rating: 4.7',
    ];
  };
});

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return ref.read(statsFetcherProvider)();
  }

  Future<void> retry() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(statsFetcherProvider)(),
    );
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);