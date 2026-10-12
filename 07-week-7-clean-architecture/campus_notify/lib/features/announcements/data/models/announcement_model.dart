import '../../../../core/format.dart';
import '../../domain/entities/announcement.dart';

/// Model untuk mapping data eksternal (JSON/API) ke entity.
/// Mapping (fromJson / toEntity) hanya ada di sini — entity tetap murni.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    super.body = '',
    super.category = 'Umum',
    required super.publishedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'Umum',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Konversi ke entity murni (batas data → domain).
  Announcement toEntity() => Announcement(
        id: id,
        title: title,
        body: body,
        category: category,
        publishedAt: publishedAt,
      );

  /// Tanggal yang diformat untuk UI (pakai formatDate dari core).
  String get formattedDate => formatDate(publishedAt);
}
