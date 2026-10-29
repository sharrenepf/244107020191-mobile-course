import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_mock_source.dart';

/// Implementasi AnnouncementRepository menggunakan data mock lokal.
/// Saat backend siap, ganti _mockList dengan call Dio.
///
/// Keputusan: fetchById TIDAK punya use case terpisah karena satu baris
/// tanpa aturan bisnis — langsung repository ke notifier sudah cukup.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  /// Data disimpan di mock, bukan di Dio/SQLite.
  /// Ganti dengan: AnnouncementRepositoryImpl(this._dio) saat backend siap.
  final List<Announcement> _mockList = kAnnouncements;

  @override
  Future<({List<Announcement> items, Failure? failure})>
      fetchAnnouncements() async {
    try {
      // Simulasi delay jaringan kecil.
      await Future.delayed(const Duration(milliseconds: 200));
      return (items: List<Announcement>.unmodifiable(_mockList), failure: null);
    } catch (e) {
      return (
        items: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final item = _mockList.where((a) => a.id == id).firstOrNull;
      return (item: item, failure: null);
    } catch (e) {
      return (
        item: null,
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
