import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncements {
  const GetAnnouncements(this._repository);
  final AnnouncementRepository _repository;

  Future<({List<Announcement> items, Failure? failure})> call({
    String category = 'Semua',
  }) async {
    final result = await _repository.fetchAnnouncements();
    if (result.failure != null) return result;
    final filtered = category == 'Semua'
        ? result.items
        : result.items.where((a) => a.category == category).toList();
    return (items: filtered, failure: null);
  }
}