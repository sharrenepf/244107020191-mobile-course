import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncements {
  const GetAnnouncements(this._repository);
  final AnnouncementRepository _repository;

  Future<({List<Announcement> items, Failure? failure})> call({
    String category = 'Semua',
    String query = '',
  }) async {
    final result = await _repository.fetchAnnouncements();
    if (result.failure != null) return result;

    // Filter kategori (aturan bisnis yang sudah ada).
    var items = category == 'Semua'
        ? result.items
        : result.items.where((a) => a.category == category).toList();

    // Filter pencarian judul — case-insensitive, murni Dart.
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      items = items.where((a) => a.title.toLowerCase().contains(q)).toList();
    }

    return (items: items, failure: null);
  }
}
