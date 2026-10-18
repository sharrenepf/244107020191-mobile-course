import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcements.dart';

/// Repository wiring — satu-satunya tempat new AnnouncementRepositoryImpl().
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(),
);

/// Use case wiring — menerima abstraksi, bukan konkret.
final getAnnouncementsProvider = Provider<GetAnnouncements>(
  (ref) => GetAnnouncements(ref.watch(announcementRepositoryProvider)),
);

/// State daftar pengumuman — dipakai HomePage.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final r = await ref.watch(getAnnouncementsProvider).call();
  if (r.failure != null) throw Exception(r.failure!.message);
  return r.items;
});

class CategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void select(String value) => state = value;
}

final selectedCategoryProvider = NotifierProvider<CategoryNotifier, String>(
  CategoryNotifier.new,
);

final filteredAnnouncementsProvider = FutureProvider<List<Announcement>>((
  ref,
) async {
  final category = ref.watch(selectedCategoryProvider);
  final r = await ref.watch(getAnnouncementsProvider).call(category: category);
  if (r.failure != null) throw Exception(r.failure!.message);
  return r.items;
});

/// Detail pengumuman — langsung repository tanpa use case.
/// Keputusan: satu baris, tanpa aturan bisnis → use case over-engineering.
/// (ref: AI Challenge docs/ai-decision-table.md)
final announcementDetailProvider = FutureProvider.family<Announcement?, String>(
  (ref, id) async {
    final r = await ref.watch(announcementRepositoryProvider).fetchById(id);
    if (r.failure != null) throw Exception(r.failure!.message);
    return r.item;
  },
);
