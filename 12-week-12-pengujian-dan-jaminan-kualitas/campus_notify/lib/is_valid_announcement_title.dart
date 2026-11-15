/// Mengembalikan true jika [value] mengandung teks setelah spasi
/// di awal dan akhir diabaikan.
///
/// Digunakan untuk memvalidasi judul pengumuman sebelum disimpan.
bool isValidAnnouncementTitle(String value) => value.trim().isNotEmpty;

