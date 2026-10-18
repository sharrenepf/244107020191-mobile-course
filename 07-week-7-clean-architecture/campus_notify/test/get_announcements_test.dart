import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository palsu — murni Dart, tanpa Dio, tanpa database.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> items, Failure? failure})>
  fetchAnnouncements() async {
    if (fail) {
      return (
        items: const <Announcement>[],
        failure: const NetworkFailure('offline (simulasi)'),
      );
    }
    return (items: items, failure: null);
  }

  @override
  Future<({Announcement? item, Failure? failure})> fetchById(String id) =>
      throw UnimplementedError();
}

void main() {
  // ── Test use case sukses ──────────────────────────────────────────────────
  test('GetAnnouncements meneruskan daftar dari repository', () async {
    final repo = FakeAnnouncementRepository(
      items: [
        Announcement(
          id: '1',
          title: 'A',
          category: 'Umum',
          publishedAt: DateTime(2026, 9, 1),
        ),
      ],
    );
    final result = await GetAnnouncements(repo).call();
    expect(result.failure, isNull);
    expect(result.items.length, 1);
    expect(result.items.first.title, 'A');
  });

  // ── Test use case failure ─────────────────────────────────────────────────
  test('GetAnnouncements meneruskan failure tanpa melempar', () async {
    final result = await GetAnnouncements(
      FakeAnnouncementRepository(fail: true),
    ).call();
    expect(result.failure, isA<NetworkFailure>());
    expect(result.items, isEmpty);
  });

  // ── Test filter kategori (aturan bisnis di use case) ─────────────────────
  test(
    'GetAnnouncements filter kategori mengecualikan yang tidak cocok',
    () async {
      final repo = FakeAnnouncementRepository(
        items: [
          Announcement(
            id: '1',
            title: 'Akademik',
            category: 'Akademik',
            publishedAt: DateTime(2026, 9, 1),
          ),
          Announcement(
            id: '2',
            title: 'Kegiatan',
            category: 'Kegiatan',
            publishedAt: DateTime(2026, 9, 2),
          ),
        ],
      );
      final result = await GetAnnouncements(repo).call(category: 'Akademik');
      expect(result.failure, isNull);
      expect(result.items.length, 1);
      expect(result.items.first.category, 'Akademik');
    },
  );

  // ── Test filter 'Semua' mengembalikan semua item ──────────────────────────
  test(
    'GetAnnouncements dengan kategori Semua mengembalikan semua item',
    () async {
      final repo = FakeAnnouncementRepository(
        items: [
          Announcement(
            id: '1',
            title: 'A',
            category: 'Akademik',
            publishedAt: DateTime(2026, 9, 1),
          ),
          Announcement(
            id: '2',
            title: 'B',
            category: 'Kegiatan',
            publishedAt: DateTime(2026, 9, 2),
          ),
        ],
      );
      final result = await GetAnnouncements(repo).call();
      expect(result.items.length, 2);
    },
  );
}
