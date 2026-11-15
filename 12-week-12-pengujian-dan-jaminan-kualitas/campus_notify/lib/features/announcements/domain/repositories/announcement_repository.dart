import '../../../../core/failures.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements();

  /// item == null && failure == null  ->  tidak ditemukan
  Future<({Announcement? item, Failure? failure})> fetchById(String id);
}