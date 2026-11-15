/// Entity murni: tidak ada import Flutter, tidak ada toMap/fromJson.
/// Mapping ada di AnnouncementModel (data layer).
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.body = '',
    this.category = 'Umum',
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime publishedAt;
}