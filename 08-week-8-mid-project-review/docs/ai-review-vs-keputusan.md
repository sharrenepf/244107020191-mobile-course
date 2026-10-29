# AI Code Review vs Keputusan Pengembang

Dokumen ini mencatat hasil evaluasi kode menggunakan kecerdasan buatan (*AI-assisted Code Review*), perbandingan dengan kondisi riil project `campus_notify`, verifikasi teknis, serta keputusan akhir yang diambil oleh pemilik project (*project owner*).

---

## 1. Prompt Review yang Digunakan

Prompt berikut diberikan kepada model AI dengan bertindak sebagai Senior Flutter Developer dan Code Reviewer:

```text
Review PR Flutter ini sebagai senior Flutter developer. Project menggunakan feature-first Clean Architecture dengan dependency rule presentation → domain ← data, Riverpod, GoRouter, serta Dio jika memang digunakan pada project. Fokus pada kebenaran, arsitektur, dan test. Abaikan style yang dapat ditangani formatter. Berikan lima temuan teratas dengan tingkat keparahan, alasan teknis, bukti lokasi kode, dan usulan perbaikan konkret. Jangan mengasumsikan dependensi atau fitur yang tidak ditemukan di repository.
```

---

## 2. Ringkasan Hasil Review AI

AI melakukan peninjauan terhadap arsitektur, layer domain, data source, penanganan error, dan strategi pengujian pada project `campus_notify`. Secara umum, arsitektur project dinilai sudah sangat baik dalam memisahkan layer Presentation, Domain, dan Data. Namun, AI mengidentifikasi beberapa area perbaikan terkait penanganan pesan error, dead code pada routing, persistensi token sesi, penanganan kasus batas (*boundary cases*), dan saran penambahan tool *code generation*.

---

## 3. Evaluasi Temuan AI dan Verifikasi Teknis

Berikut adalah 5 temuan teratas dari AI beserta analisis bukti dan keputusan akhirnya:

### Temuan 1: Penanganan Pesan Error Objek `Failure` di Presentation Layer
- **Tingkat Keparahan:** High (Kebenaran Program / User Experience)
- **Lokasi Kode:** `lib/core/format.dart:17-20`, `lib/features/announcements/presentation/pages/home_page.dart:110`, `lib/features/announcements/presentation/pages/announcement_page.dart:37`
- **Uraian AI:** Fungsi `errorMessage(Object error)` hanya memotong prefix `'Exception: '`. Jika layer data mengembalikan `Failure` (misal `NetworkFailure` atau `LocalFailure`) yang diteruskan usecase ke UI, UI akan menampilkan teks `Instance of 'NetworkFailure'` karena kelas `Failure` tidak meng-override `toString()`.
- **Bukti Teknis:** Di `lib/core/failures.dart`, `Failure` didefinisikan sebagai `sealed class Failure { const Failure(this.message); final String message; }` tanpa method `toString()`. Saat dio/repository melempar failure ke UI, pengguna melihat string representasi instance objek alih-alih pesan kesalahan yang dapat dipahami.
- **Keputusan:** **DITERIMA (Terbukti Benar)**.
- **Tindak Lanjut:** Menambahkan `@override String toString() => message;` pada `Failure` dan menambahkan pengecekan `if (error is Failure) return error.message;` pada helper `errorMessage`.

---

### Temuan 2: Duplikasi Logika Route Parser dan Keberadaan Dead Code
- **Tingkat Keparahan:** Medium (Arsitektur & Pemeliharaan Kode)
- **Lokasi Kode:** `lib/messaging/route_parser.dart:4-8` vs `lib/core/format.dart:10-14`
- **Uraian AI:** Terdapat dua definisi fungsi `routeFromMessage`. Satu berada di `lib/messaging/route_parser.dart` dan satu lagi di `lib/core/format.dart`. Berdasarkan penelusuran impor, `route_parser.dart` sama sekali tidak pernah diimpor oleh file lain di seluruh aplikasi (*dead code*).
- **Bukti Teknis:** Hasil pencarian `Select-String -Path "campus_notify\lib\**\*.dart" -Pattern "route_parser.dart"` menghasilkan 0 referensi. Seluruh modul (`push_service.dart`, `auth_push_test.dart`) mengimpor `routeFromMessage` dari `core/format.dart`.
- **Keputusan:** **DITERIMA (Terbukti Benar)**.
- **Tindak Lanjut:** Menandai `route_parser.dart` sebagai kandidat pembersihan refactoring pada PR berikutnya agar tidak membingungkan anggota tim.

---

### Temuan 3: Migrasi In-Memory Token Store ke Persistent Storage
- **Tingkat Keparahan:** Medium (Fungsionalitas / Keamanan)
- **Lokasi Kode:** `lib/shared/data/token_store.dart:14-25` dan `lib/shared/providers.dart:15-18`
- **Uraian AI:** Implementasi default `tokenStoreProvider` menggunakan penyimpanan memori volatile (`InMemoryTokenStore`), yang menyebabkan token login hilang seketika saat aplikasi ditutup atau di-restart. AI menyarankan untuk segera mewajibkan `FlutterSecureStorage` pada default provider.
- **Bukti Teknis:** Di `lib/shared/data/token_store.dart`, `TokenStore` dirancang menggunakan interface (*abstract class*) dengan implementasi mock memori untuk mempermudah running di platform desktop/web saat pengembangan.
- **Keputusan:** **DISEDERHANAKAN / DITUNDA DENGAN ALASAN TEKNIS**.
- **Alasan Teknis:** Pada konteks jobsheet praktikum mid-project review dan automated CI/CD (`flutter test`), `InMemoryTokenStore` sengaja dipertahankan sebagai implementasi default agar pengujian dan demonstrasi tidak bergantung pada driver hardware native (Keystore Android / Keychain iOS / Windows DPAPI) yang sering memicu kegagalan build pada lingkungan runner CI GitHub Actions atau emulator lab praktikum.

---

### Temuan 4: Defensive Boundary Check pada Indeks Bulan Kalender
- **Tingkat Keparahan:** Low (Keterbacaan & Ketahanan Kode)
- **Lokasi Kode:** `lib/core/format.dart:1-7`
- **Uraian AI:** Fungsi `formatDate(DateTime d)` memetakan bulan langsung menggunakan `_bulan[d.month - 1]`. Jika suatu saat parsing string tanggal menghasilkan data di luar rentang kalender 1–12, pemanggilan fungsi ini akan melempar `RangeError (index)`.
- **Bukti Teknis:** Pemformatan menggunakan array konstan `_bulan` dengan 12 elemen. Meskipun objek `DateTime` standar Dart menjamin nilai bulan 1–12, nilai fallback jika gagal parse di model menggunakan epoch `0` (`DateTime.fromMillisecondsSinceEpoch(0)`).
- **Keputusan:** **DITERIMA SEBAGAI SARAN PENINGKATAN**.
- **Tindak Lanjut:** Mencatat saran ini untuk penguatan validasi parsing di level `AnnouncementModel.fromJson`.

---

### Temuan 5: Usulan Penggantian State Management ke BLoC dan Code Generator Freezed
- **Tingkat Keparahan:** High (Over-Engineering / Pelanggaran Aturan Praktikum)
- **Lokasi Kode:** Seluruh layer `domain/` dan `presentation/`
- **Uraian AI:** AI menyarankan untuk merombak seluruh state management dari Riverpod ke `flutter_bloc` serta menambahkan pustaka `freezed` dan `build_runner` untuk menghasilkan model immutable otomatis.
- **Bukti Teknis:** Proyek `campus_notify` telah menggunakan **Riverpod 3** dan **GoRouter** secara konsisten dari Jobsheet 7 sesuai silabus resmi mata kuliah Pemrograman Mobile JTI Polinema.
- **Keputusan:** **DITOLAK SECARA TEKNIS (REJECTED)**.
- **Alasan Teknis:**
  1. Melanggar Aturan Utama Jobsheet 8 (#1 dan #2): dilarang melakukan *over-engineering* dan dilarang menambahkan dependensi/arsitektur baru yang tidak diperlukan.
  2. Implementasi Riverpod yang ada saat ini sudah bersih, teruji dengan 15 unit tests yang lulus 100%, serta sepenuhnya mematuhi prinsip Clean Architecture. Menambahkan `build_runner` dan `freezed` akan memperlambat waktu kompilasi dan mempersulit pemahaman mahasiswa.

---

## 4. Tabel Rekapitulasi Keputusan Final

| No | Temuan AI Review | Kategori | Keputusan | Alasan Utama |
|---|---|---|---|---|
| 1 | Penanganan error `Failure` di UI | Correctness | **DITERIMA** | Menghindari tampilan teks teknis internal ke mahasiswa pengguna aplikasi. |
| 2 | Dead code `route_parser.dart` | Architecture | **DITERIMA** | Menjaga kebersihan basis kode dan konsistensi titik rujukan routing. |
| 3 | Wajibkan persistent secure storage | Security/Platform | **DITUNDA** | Menjaga kompatibilitas lingkungan pengujian CI dan kemudahan demonstrasi praktikum. |
| 4 | Boundary check `formatDate` | Robustness | **DITERIMA** | Meningkatkan ketahanan fungsi helper terhadap nilai tanggal tepi. |
| 5 | Migrasi ke BLoC & Freezed | Architecture | **DITOLAK** | Over-engineering, melanggar silabus Riverpod dan aturan jobsheet praktikum. |

---

## 5. Kesimpulan Review

Kombinasi antara *AI-assisted Code Review* dan verifikasi manual oleh pengembang terbukti sangat efektif. AI mampu mendeteksi potensi cacat tersembunyi seperti penanganan objek `Failure` dan *dead code*, namun pengembang manusia tetap memegang kendali penuh untuk menolak saran yang bersifat *over-engineering* atau tidak sesuai dengan batasan praktikum akademik.

