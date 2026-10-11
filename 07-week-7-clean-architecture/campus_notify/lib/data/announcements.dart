class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String date;
}

const List<Announcement> kAnnouncements = [
  Announcement(
    id: '1',
    title: 'Libur Nasional',
    body: 'Perkuliahan diliburkan pada hari Jumat. Kegiatan belajar '
        'mengajar dilanjutkan kembali pada hari Senin sesuai jadwal.',
    category: 'Umum',
    date: '2 Okt 2026',
  ),
  Announcement(
    id: '2',
    title: 'UTS Semester Ganjil',
    body: 'UTS dimulai Senin depan. Cek jadwal dan ruang ujian di SIAKAD. '
        'Mahasiswa wajib membawa kartu mahasiswa.',
    category: 'Akademik',
    date: '3 Okt 2026',
  ),
  Announcement(
    id: '3',
    title: 'Jadwal kuliah berubah',
    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00. '
        'Harap semua mahasiswa memperhatikan perubahan ini.',
    category: 'Akademik',
    date: '4 Okt 2026',
  ),
  Announcement(
    id: '4',
    title: 'Pendaftaran UKM Fotografi',
    body: 'Pendaftaran anggota baru UKM Fotografi dibuka sampai akhir '
        'bulan. Daftar melalui sekretariat UKM.',
    category: 'Kegiatan',
    date: '4 Okt 2026',
  ),
  Announcement(
    id: '5',
    title: 'Seminar Pengembangan Karier',
    body: 'Seminar karier bersama alumni diadakan Sabtu pukul 09.00 '
        'di Aula Utama. Terbuka untuk semua mahasiswa.',
    category: 'Kegiatan',
    date: '5 Okt 2026',
  ),
];

Announcement? findAnnouncement(String id) {
  for (final a in kAnnouncements) {
    if (a.id == id) return a;
  }
  return null;
}