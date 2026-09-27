import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';
import 'note_providers.dart';
import 'repositories/note_repository.dart';

/// Toggle simulasi offline yang deterministik (tidak bergantung Wi-Fi kelas).
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool value) => state = value;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

/// ================== CACHE-FIRST UNTUK POSTS ==================
class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repo = ref.watch(postRepositoryProvider);
    final cached = await repo.readCachedPosts();
    // 1. Segera kembalikan cache agar UI tidak blank saat offline.
    // 2. Di background: fetch -> simpan ke cached_posts -> update state.
    Future.microtask(_refreshInBackground);
    return cached;
  }

  Future<void> _refreshInBackground() async {
    if (ref.read(forceOfflineProvider)) return; // simulasi offline aktif
    final repo = ref.read(postRepositoryProvider);
    try {
      final fresh = await repo.fetchFromNetwork();
      await repo.cachePosts(fresh);
      state = AsyncData(fresh);
    } catch (_) {
      // Gagal refresh (offline/timeout) -> biarkan cache lama tetap tampil.
    }
  }

  /// Dipanggil manual lewat tombol refresh di UI.
  Future<void> manualRefresh() async {
    if (ref.read(forceOfflineProvider)) return;
    final repo = ref.read(postRepositoryProvider);
    state = const AsyncLoading();
    try {
      final fresh = await repo.fetchFromNetwork();
      await repo.cachePosts(fresh);
      state = AsyncData(fresh);
    } catch (e, st) {
      // Refresh gagal, tapi data lama (state.value) tetap dipertahankan.
      state = AsyncData(state.value ?? []);
    }
  }
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

/// ================== ANTREAN SYNC UNTUK NOTES (DIRTY FLAG) ==================
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

class SyncNotesNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async => null; // belum pernah sync

  Future<void> runSync() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(noteRepositoryProvider);
      final syncedCount = await syncNotes(repo);
      ref.invalidate(notesProvider); // refresh badge & list
      ref.invalidate(dirtyCountProvider); // refresh angka dirty di appbar
      return syncedCount;
    });
  }
}

final syncNotesProvider = AsyncNotifierProvider<SyncNotesNotifier, int?>(
  SyncNotesNotifier.new,
);
