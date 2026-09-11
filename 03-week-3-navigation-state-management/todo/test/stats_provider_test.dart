import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo/providers/stats_provider.dart';

void main() {
  group('StatsNotifier', () {
    test(
      'build() mengembalikan 3 data statistik ketika berhasil',
      () async {
        final container = ProviderContainer(
          overrides: [
            // Mengganti fetcher asli dengan fetcher
            // sederhana untuk kebutuhan testing.
            statsFetcherProvider.overrideWithValue(
              () async => [
                'Total pengguna: 1.245',
                'Total transaksi: 389',
                'Rata-rata rating: 4.7',
              ],
            ),
          ],
        );

        addTearDown(container.dispose);

        // Mengambil data dari provider.
        final data = await container.read(statsProvider.future);

        expect(data, isA<List<String>>());
        expect(data.length, 3);
      },
    );

    test(
      'retry() mengubah state menjadi data',
      () async {
        final container = ProviderContainer(
          overrides: [
            statsFetcherProvider.overrideWithValue(
              () async => [
                'Total pengguna: 1.245',
                'Total transaksi: 389',
                'Rata-rata rating: 4.7',
              ],
            ),
          ],
        );

        addTearDown(container.dispose);

        // Menunggu proses awal selesai.
        await container.read(statsProvider.future);

        // Mengambil notifier untuk menjalankan retry().
        final notifier =
            container.read(statsProvider.notifier);

        await notifier.retry();

        final state = container.read(statsProvider);

        // Memastikan state berhasil menjadi AsyncData.
        expect(
          state,
          isA<AsyncData<List<String>>>(),
        );

        expect(state.value!.length, 3);
      },
    );
  });
}