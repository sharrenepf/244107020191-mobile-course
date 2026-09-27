import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          darkModeAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Memuat preferensi tema...'),
            ),
            error: (err, _) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text('Gagal memuat: $err'),
            ),
            data: (isDark) => SwitchListTile(
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Mode Gelap'),
              subtitle: Text(isDark ? 'Aktif' : 'Nonaktif'),
              value: isDark,
              onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          const Divider(),
          lastOpenedAsync.when(
            loading: () => const ListTile(title: Text('Memuat...')),
            error: (_, __) => const ListTile(title: Text('-')),
            data: (lastOpened) => ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Terakhir dibuka'),
              subtitle: Text(lastOpened ?? 'Baru pertama kali dibuka'),
            ),
          ),
        ],
      ),
    );
  }
}