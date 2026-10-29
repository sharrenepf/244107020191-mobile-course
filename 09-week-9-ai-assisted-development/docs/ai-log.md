# AI-Assisted Development Log — Week 9

**Nama**: Sharren Elvaretta  
**NIM**: 244107020191  
**Absen**: 24  
**Mata Kuliah**: Pemrograman Mobile  
**Minggu**: 9 — AI-Assisted Development (Vibe Coding)  
**Tanggal**: 29 Oktober 2026  
**Project**: Campus Notify (dari Week 7, Clean Architecture)

---

## 1. Konteks Proyek Sebelum Perubahan

### Struktur Arsitektur
Project Campus Notify menggunakan **Feature-First Clean Architecture**:
```
lib/
├── core/           # Entities, failures, use case interface (murni Dart)
├── shared/         # Infrastruktur lintas fitur (providers, router)
└── features/
    ├── announcements/
    │   ├── domain/     # Entity, repository interface, use cases
    │   ├── data/       # Mock data source, repository impl
    │   └── presentation/ # Pages, providers (Riverpod)
    └── auth/
```

### State Management
- **Riverpod 3.4.3** — menggunakan `NotifierProvider` (bukan `StateProvider` yang deprecated)
- Semua provider dikumpulkan di `announcement_providers.dart`

### Data
- Mock lokal di `announcement_mock_source.dart` — 5 item:
  1. Libur Nasional
  2. UTS Semester Ganjil
  3. Jadwal kuliah berubah
  4. Pendaftaran UKM Fotografi
  5. Seminar Pengembangan Karier

### Fitur yang Sudah Ada (Week 7)
- Filter kategori (Semua / Akademik / Kegiatan / dll)
- `GetAnnouncements.call(category:)` — menerima parameter kategori
- `filteredAnnouncementsProvider` — provider gabungan filter + data

---

## 2. Fitur yang Dikembangkan di Week 9

**Fitur**: Search judul pengumuman (case-insensitive)

**Alasan pemilihan**:
- Kebutuhan nyata — user perlu cari pengumuman tertentu tanpa scroll semua
- Tidak membutuhkan dependency baru
- Dapat diimplementasikan sebagai perluasan use case yang sudah ada (tidak over-engineering)
- Mudah diuji dengan unit test

---

## 3. Prompt AI yang Digunakan

### Prompt 1 — Analisis Arsitektur
```
Saya memiliki project Flutter Campus Notify dengan Clean Architecture.
Berikut struktur domain dan use case yang ada:

[GetAnnouncements use case]
Future<({List<Announcement> items, Failure? failure})> call({String category = 'Semua'})

[AnnouncementRepository interface]
Future<({List<Announcement> items, Failure? failure})> getAnnouncements({String category})

Saya ingin menambahkan fitur search judul pengumuman (case-insensitive).
Apakah sebaiknya saya:
A) Tambah parameter `query` ke use case yang sudah ada
B) Buat use case baru SearchAnnouncements
C) Handle di presentation layer saja

Pertimbangkan prinsip Clean Architecture dan hindari over-engineering.
```

**Respons AI**: Pilihan A — perluasan parameter `query` ke use case yang ada. Alasan: data masih mock lokal, belum perlu separation of concern untuk search. Use case baru lebih cocok ketika ada API endpoint terpisah.

### Prompt 2 — Implementasi Use Case
```
Tambahkan parameter `query` ke use case GetAnnouncements.
Kriteria:
- Default query = '' (string kosong berarti tampilkan semua)
- Filter case-insensitive pada field `title` entity Announcement
- Tetap kompatibel dengan filter kategori yang ada
- Jangan ubah contract AnnouncementRepository

Kode use case saat ini:
[kode get_announcements.dart diberikan]
```

### Prompt 3 — Implementasi Provider
```
Tambahkan search state ke announcement_providers.dart menggunakan Riverpod 3.
Kriteria:
- SearchNotifier extends Notifier<String>
- searchQueryProvider untuk menyimpan query string
- searchedAnnouncementsProvider menggabungkan kategori + query
- Jangan hapus filteredAnnouncementsProvider yang lama

Kode providers saat ini:
[kode announcement_providers.dart diberikan]
```

### Prompt 4 — Implementasi UI
```
Tambahkan search bar ke HomePage menggunakan widget TextField standar Flutter.
Kriteria:
- TextEditingController dikelola dengan benar (initState/dispose)
- onChanged memperbarui searchQueryProvider
- Empty state berbeda: jika query tidak kosong tampilkan ikon search_off + teks "Tidak ditemukan"
- Jika query kosong dan hasil kosong tampilkan ikon inbox + teks default
- Jangan tambah package baru

Kode home_page.dart saat ini:
[kode home_page.dart diberikan]
```

### Prompt 5 — Unit Test
```
Buat 4 unit test untuk fitur search di get_announcements_test.dart.
Skenario:
1. Query kosong → kembalikan semua item
2. Query cocok (partial) → kembalikan item yang sesuai
3. Query tidak cocok → kembalikan daftar kosong
4. Query huruf kapital → cocok case-insensitive

Gunakan Mockito yang sudah ada, jangan tambah dependency.
```

---

## 4. Konteks Kode yang Diberikan ke AI

Setiap prompt menyertakan:
- Konten file yang relevan (use case, providers, atau page)
- Interface `AnnouncementRepository` (tidak boleh diubah)
- Entity `Announcement` (field: id, title, content, category, date)
- Aturan: jangan buat project baru, jangan tambah dependency, jangan over-engineering

---

## 5. Output Awal AI & Evaluasi

### Output Use Case (Representatif)
```dart
Future<({List<Announcement> items, Failure? failure})> call({
  String category = 'Semua',
  String query = '',
}) async {
  final result = await repository.getAnnouncements(category: category);
  if (result.failure != null) return result;
  
  if (query.isEmpty) return result;
  
  final filtered = result.items
      .where((a) => a.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
  return (items: filtered, failure: null);
}
```
**Evaluasi**: ✅ Benar. Logic filter hanya di use case, tidak bocor ke repository.

### Output Provider (Representatif)
```dart
class SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchNotifier, String>(
  SearchNotifier.new,
);
```
**Evaluasi**: ✅ Benar. Menggunakan `NotifierProvider` yang sesuai Riverpod 3.

---

## 6. Tabel Usulan AI — Keputusan & Alasan

| # | Usulan AI | Keputusan | Alasan |
|---|-----------|-----------|--------|
| 1 | Tambah `debounce` pada TextField search | ❌ Ditolak | Data mock lokal, tidak ada API call. Debounce menambah complexity tanpa manfaat nyata. |
| 2 | Buat use case terpisah `SearchAnnouncements` | ❌ Ditolak | Over-engineering untuk data lokal. Cukup perluasan parameter. |
| 3 | Gunakan `StreamProvider` untuk real-time search | ❌ Ditolak | Data bersifat statis (mock), stream tidak diperlukan. |
| 4 | Filter `query` di presentation layer saja | ❌ Ditolak | Melanggar prinsip Clean Architecture — business logic harus di domain. |
| 5 | Perluasan `GetAnnouncements` dengan param `query` | ✅ Diterima | Paling sederhana, tetap clean, kompatibel dengan filter kategori yang ada. |
| 6 | `TextEditingController` di `_HomePageState` | ✅ Diterima | Lifecycle benar: dispose di `dispose()`, tidak terjadi memory leak. |
| 7 | Empty state berbeda untuk "tidak ditemukan" vs "kosong" | ✅ Diterima | UX lebih baik, implementasi sederhana dengan kondisional. |

---

## 7. Temuan Bug / Halusinasi AI

### Bug: Query Trim di Layer yang Salah

**Deskripsi**: Output awal AI menempatkan `query.trim()` hanya di widget `onChanged`, bukan di use case:

```dart
// Versi awal AI (presentation) — bermasalah
onChanged: (v) => ref.read(searchQueryProvider.notifier).update(v.trim()),
```

**Masalah**: Use case menerima string yang belum di-trim jika dipanggil dari context lain (misal: unit test langsung, atau integrasi di masa depan dengan input yang belum di-trim).

**Fix yang Diterapkan**: Trimming tetap di presentation (untuk responsivitas UI), **ditambah juga validasi di use case** dengan `.trim()` pada saat filter:

```dart
// Di use case — defensive programming
final q = query.trim().toLowerCase();
if (q.isEmpty) return result;
final filtered = result.items
    .where((a) => a.title.toLowerCase().contains(q))
    .toList();
```

**Kategori**: Bug layer boundary — trimming defensif perlu ada di use case.

### Halusinasi: Import yang Tidak Ada

**Deskripsi**: AI sempat menyarankan `import 'package:flutter_hooks/flutter_hooks.dart'` untuk manajemen `TextEditingController`.

**Dampak**: Package `flutter_hooks` tidak ada di `pubspec.yaml`.

**Fix**: Gunakan `StatefulWidget` dengan `_HomePageState` yang sudah ada — lebih sesuai dan tidak butuh dependency baru.

---

## 8. File yang Diubah

| File | Perubahan |
|------|-----------|
| `lib/features/announcements/domain/usecases/get_announcements.dart` | Tambah parameter `query` dengan filter case-insensitive |
| `lib/features/announcements/presentation/providers/announcement_providers.dart` | Tambah `SearchNotifier`, `searchQueryProvider`, `searchedAnnouncementsProvider` |
| `lib/features/announcements/presentation/pages/home_page.dart` | Tambah `TextField` search bar, `TextEditingController`, empty state dinamis |
| `test/get_announcements_test.dart` | Tambah 4 unit test search |

**File yang TIDAK diubah** (sesuai prinsip tidak boleh ubah contract):
- `lib/features/announcements/domain/repositories/announcement_repository.dart`
- `lib/features/announcements/data/repositories/announcement_repository_impl.dart`
- `lib/features/announcements/data/sources/announcement_mock_source.dart`
- Semua file di `features/auth/` dan `shared/`

---

## 9. Refactoring yang Dilakukan

1. **Konsolidasi provider**: `searchedAnnouncementsProvider` menggantikan `filteredAnnouncementsProvider` di `home_page.dart` — provider lama tidak dihapus untuk kompatibilitas
2. **Defensive trim**: Tambahkan `.trim()` di use case untuk keamanan layer boundary
3. **Empty state bersyarat**: Pisahkan logika tampil "Tidak ditemukan" vs "Belum ada pengumuman" berdasarkan `query.isNotEmpty`

---

## 10. Hasil Verifikasi

### `dart format`
```
Formatted 28 files (0 changed) in 0.41 seconds
Exit code: 0 ✅
```

### `flutter analyze`
```
No issues found! (ran in 136.9s)
Exit code: 0 ✅
```

### `flutter test test/get_announcements_test.dart`
```
+0: GetAnnouncements meneruskan daftar dari repository
+1: GetAnnouncements meneruskan failure tanpa melempar
+2: GetAnnouncements filter kategori mengecualikan yang tidak cocok
+3: GetAnnouncements dengan kategori Semua mengembalikan semua item
+4: Search: query kosong mengembalikan semua item
+5: Search: query cocok mengembalikan item yang sesuai
+6: Search: query tidak cocok mengembalikan daftar kosong
+7: Search: pencarian tidak membedakan huruf besar dan kecil
All tests passed! (8/8)
Exit code: 0 ✅
```

---

## 11. Skenario Pengujian Manual

| Skenario | Input | Expected | Hasil |
|----------|-------|----------|-------|
| Tampilan awal | (kosong) | 5 pengumuman tampil | ✅ |
| Search parsial | "UTS" | 1 hasil: "UTS Semester Ganjil" | ✅ |
| Search tidak cocok | "xyzabc" | Empty state "Tidak ditemukan" dengan ikon search_off | ✅ |
| Search case-insensitive | "JADWAL" | 1 hasil: "Jadwal kuliah berubah" | ✅ |
| Hapus query | (bersihkan field) | Kembali tampil 5 pengumuman | ✅ |
| Kombinasi filter + search | Kategori "Akademik" + query "UTS" | 1 hasil | ✅ |

---

## 12. Refleksi Pembelajaran

### Manfaat AI dalam Pengembangan

1. **Kecepatan prototyping**: Dengan prompt yang tepat, AI menghasilkan kerangka kode dalam hitungan detik — menghemat ~60% waktu implementasi awal.
2. **Konsistensi pattern**: AI mengenali pattern Riverpod 3 (`NotifierProvider`) dan tidak menyarankan API yang sudah deprecated.
3. **Dokumentasi otomatis**: AI dapat membantu menulis komentar dan docstring yang konsisten.

### Keterbatasan AI yang Ditemukan

1. **Layer boundary**: AI tidak selalu sadar pentingnya defensive programming di setiap layer. Trimming di presentation saja tidak cukup.
2. **Dependency hallucination**: AI menyarankan package yang tidak ada (`flutter_hooks`) tanpa mengecek `pubspec.yaml` terlebih dahulu.
3. **Over-engineering tendency**: AI cenderung menyarankan solusi yang lebih kompleks (debounce, stream, use case terpisah) meskipun tidak diperlukan untuk kasus sederhana.

### Kesimpulan

AI sangat berguna sebagai **asisten coding**, bukan pengganti engineer. Setiap output AI harus dievaluasi dengan:
- Pemahaman arsitektur proyek
- Kebutuhan aktual (bukan theoretical best practice)
- Prinsip tidak over-engineering
- Verifikasi dengan `analyze` dan `test`

**Peran engineer tetap krusial**: mengevaluasi, memfilter, dan mengadaptasi output AI sesuai konteks nyata.
