import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Provider untuk CommentRepository.
///
/// Repository menggunakan Dio yang sudah dikonfigurasi
/// melalui dioProvider di providers.dart.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Notifier untuk mengambil komentar berdasarkan postId.
///
/// Pada Riverpod 3, FamilyAsyncNotifier sudah tidak digunakan.
/// Parameter family disimpan melalui constructor.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);

    // Exception dari repository otomatis menjadi AsyncError.
    return repository.fetchComments(postId);
  }

  /// Memuat ulang komentar.
  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(commentRepositoryProvider);

      final comments = await repository.fetchComments(postId);

      state = AsyncData(comments);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

/// Provider family.
///
/// Contoh:
/// ref.watch(commentListProvider(1))
///
/// berarti mengambil komentar untuk postId = 1.
final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
  CommentListNotifier.new,
);