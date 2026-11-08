import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_mock_source.dart';

/// Implementasi AnnouncementRepository menggunakan data mock lokal
/// dengan in-memory caching untuk optimasi performa jaringan.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final List<Announcement> _mockList = kAnnouncements;

  // In-memory cache layer
  List<Announcement>? _cache;
  final Map<String, Announcement> _detailCache = {};
  DateTime? _lastFetch;
  static const Duration _cacheTtl = Duration(minutes: 5);

  @override
  Future<({List<Announcement> items, Failure? failure})> fetchAnnouncements({
    bool forceRefresh = false,
  }) async {
    // 1. Cache-First: Kembalikan langsung dari in-memory cache jika masih valid
    if (!forceRefresh && _cache != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < _cacheTtl) {
        return (items: List<Announcement>.unmodifiable(_cache!), failure: null);
      }
    }

    try {
      // 2. Simulasi network request
      await Future.delayed(const Duration(milliseconds: 200));
      _cache = List<Announcement>.from(_mockList);
      _lastFetch = DateTime.now();

      // Perbarui cache detail untuk akses instan di AnnouncementPage
      for (final a in _cache!) {
        _detailCache[a.id] = a;
      }

      return (items: List<Announcement>.unmodifiable(_cache!), failure: null);
    } catch (e) {
      // 3. Fallback ke cache jika network gagal (offline-first resilience)
      if (_cache != null && _cache!.isNotEmpty) {
        return (items: List<Announcement>.unmodifiable(_cache!), failure: null);
      }
      return (
        items: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchById(String id) async {
    // 1. Cek apakah detail sudah ada di in-memory cache
    if (_detailCache.containsKey(id)) {
      return (item: _detailCache[id], failure: null);
    }

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final item = _mockList.where((a) => a.id == id).firstOrNull;
      if (item != null) {
        _detailCache[id] = item;
      }
      return (item: item, failure: null);
    } catch (e) {
      return (
        item: null,
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
