import '../../domain/entities/announcement.dart';

/// Data mock pengumuman kampus.
/// Repository impl mengambil data dari sini.
/// Ganti seluruh isi list ini (atau ganti datasource ke Dio) saat backend siap.
final List<Announcement> kAnnouncements = [
  Announcement(
    id: '1',
    title: 'Libur Nasional',
    body:
        'Perkuliahan diliburkan pada hari Jumat. Kegiatan belajar '
        'mengajar dilanjutkan kembali pada hari Senin sesuai jadwal.',
    category: 'Umum',
    publishedAt: DateTime(2026, 10, 2),
  ),
  Announcement(
    id: '2',
    title: 'UTS Semester Ganjil',
    body:
        'UTS dimulai Senin depan. Cek jadwal dan ruang ujian di SIAKAD. '
        'Mahasiswa wajib membawa kartu mahasiswa.',
    category: 'Akademik',
    publishedAt: DateTime(2026, 10, 3),
  ),
  Announcement(
    id: '3',
    title: 'Jadwal kuliah berubah',
    body:
        'Kelas Mobile pindah ke Ruang A2 jam 13.00. '
        'Harap semua mahasiswa memperhatikan perubahan ini.',
    category: 'Akademik',
    publishedAt: DateTime(2026, 10, 4),
  ),
  Announcement(
    id: '4',
    title: 'Pendaftaran UKM Fotografi',
    body:
        'Pendaftaran anggota baru UKM Fotografi dibuka sampai akhir '
        'bulan. Daftar melalui sekretariat UKM.',
    category: 'Kegiatan',
    publishedAt: DateTime(2026, 10, 4),
  ),
  Announcement(
    id: '5',
    title: 'Seminar Pengembangan Karier',
    body:
        'Seminar karier bersama alumni diadakan Sabtu pukul 09.00 '
        'di Aula Utama. Terbuka untuk semua mahasiswa.',
    category: 'Kegiatan',
    publishedAt: DateTime(2026, 10, 5),
  ),
];
