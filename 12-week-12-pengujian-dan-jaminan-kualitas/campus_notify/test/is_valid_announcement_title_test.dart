import 'package:campus_notify/is_valid_announcement_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidAnnouncementTitle', () {
    // Arrange: judul normal berisi teks
    test('menerima judul yang berisi teks', () {
      // Act
      final result = isValidAnnouncementTitle('UTS Susulan');
      // Assert
      expect(result, isTrue);
    });

    test('menerima judul dengan spasi di awal dan akhir', () {
      // Arrange + Act + Assert
      expect(isValidAnnouncementTitle('  Pengumuman Penting  '), isTrue);
    });

    test('menolak string kosong', () {
      // Arrange: string kosong
      const input = '';
      // Act
      final result = isValidAnnouncementTitle(input);
      // Assert
      expect(result, isFalse);
    });

    test('menolak judul yang hanya berisi spasi (kasus tepi)', () {
      // Arrange: hanya spasi — terlihat ada isi tapi sebenarnya kosong
      expect(isValidAnnouncementTitle(' '), isFalse);
      expect(isValidAnnouncementTitle('   '), isFalse);
    });
  });
}

