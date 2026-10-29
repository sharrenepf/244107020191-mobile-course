# Review Checklist — Jobsheet 8 Mid-Project Review

Dokumen ini memuat catatan evaluasi dan checklist peninjauan kualitas kode (*code review*), *branch hygiene*, *commit messages*, *static analysis*, dan kepatuhan arsitektur untuk project mobile semester 5.

---

## 1. Praktikum 1: Hygiene Branch dan Commit

### A. Kondisi Branching
- **Branch Produksi (`main`):** Digunakan untuk menyimpan kode rilis yang stabil.
- **Branch Integrasi (`develop`):** Sudah tersedia di remote (`origin/develop`) sebagai branch integrasi fitur sebelum digabungkan ke `main`.
- **Branching Model:** Mengikuti alur kerja GitFlow sederhana (`main` ← `develop` ← `feature/*` atau `chore/*`).

### B. Evaluasi Riwayat Commit (Contoh Nyata dari Git History)

Berdasarkan pemeriksaan riwayat commit Git aktual (`git log --oneline`), berikut adalah analisis 3 commit lama dan perbaikan standarnya menggunakan format **Conventional Commits** (`<type>(<scope>): <deskripsi singkat>`):

| Hash Commit | Pesan Commit Lama | Analisis Masalah | Usulan Perbaikan (Conventional Commits) |
|---|---|---|---|
| `9508b82` | `js 6` | Terlalu singkat, menggunakan singkatan informal (`js`), dan tidak menjelaskan modul atau fitur yang ditambahkan/diubah. | `feat(auth): implementasi autentikasi dan integrasi FCM push notification` |
| `31c56a7` | `Jobsheet 7` | Hanya menyebutkan nama modul/pertemuan praktikum tanpa rincian teknis mengenai restrukturisasi kode yang dilakukan. | `refactor(announcements): migrasi kode ke Clean Architecture dan state management Riverpod` |
| `af6c650` | `update readme` | Kata kerja generik, tanpa lingkup (*scope*), dan tidak memberikan informasi bagian dokumentasi apa yang diperbarui. | `docs: perbarui panduan instalasi dan dokumentasi arsitektur project pada README` |

### C. Panduan Hygiene Commit untuk Tim
1. **Atomicity:** Satu commit hanya menangani satu tujuan perubahan logis (tidak mencampur *formatting*, *feature*, dan *refactoring* sekaligus).
2. **Format Standar:** Gunakan konvensi `feat`, `fix`, `refactor`, `style`, `test`, `docs`, atau `chore`.
3. **Pesan Jelas:** Gunakan kalimat imperatif di bagian deskripsi (misal: "tambahkan validasi...", "perbaiki bug...", bukan "tambahin" atau "update").

---

## 2. Praktikum 2: Pull Request dan Peer Review

### A. Rencana Pull Request (Simulasi / Real PR)
- **Judul PR:** `fix(core): penanganan pesan ramah pada kegagalan domain dan routing notifikasi`
- **Tujuan / Base Branch:** `develop` ← `fix/error-handling-and-route`
- **Referensi Issue:** Menutup issue `#4: UI menampilkan teks teknis Instance of Failure saat koneksi error`

#### Deskripsi PR:
> **Masalah:**
> Saat terjadi kegagalan jaringan atau parsing pada data layer, objek `Failure` diteruskan ke UI. Karena fungsi `errorMessage()` di `lib/core/format.dart` hanya mengecek `Exception: `, objek `Failure` dicetak sebagai `Instance of 'NetworkFailure'`, membingungkan pengguna awam. Selain itu terdapat duplikasi deklarasi fungsi `routeFromMessage` di `messaging/route_parser.dart` yang tidak pernah dipanggil (*dead code*).
>
> **Solusi:**
> 1. Menambahkan penanganan `if (error is Failure) return error.message;` pada helper `errorMessage` serta meng-override `toString()` pada kelas `Failure`.
> 2. Menghapus / mengonsolidasikan file `lib/messaging/route_parser.dart` agar rujukan routing terpusat.
>
> **Cara Pengujian:**
> 1. Jalankan `flutter test` untuk memastikan test parsing error dan alur provider tetap lulus.
> 2. Simulasikan kondisi offline pada `AnnouncementPage` dan pastikan pesan teks menampilkan pesan ramah bahasa Indonesia.

---

### B. Catatan Peer Review (Format: Observasi → Dampak → Usulan Konkret)

Berikut adalah daftar temuan code review dari rekan sejawat (*peer reviewer*):

#### 1. Temuan Kebenaran Program (Correctness) — 1
- **Observasi:** Pada `lib/core/format.dart` baris 17–20, fungsi `errorMessage(Object error)` hanya membuang substring `'Exception: '` menggunakan `text.substring(11)`.
- **Dampak:** Ketika terjadi `Failure` dari Domain Layer (seperti `NetworkFailure` atau `AuthFailure`), objek tersebut tidak memiliki awalan `'Exception: '`, sehingga menghasilkan representasi default `"Instance of 'NetworkFailure'"`. Akibatnya layar UI menampilkan teks teknis ke mahasiswa.
- **Usulan Konkret:** Lakukan pengecekan tipe objek terlebih dahulu: jika berupa `Failure`, kembalikan langsung `error.message`.

#### 2. Temuan Kebenaran Program (Correctness) — 2
- **Observasi:** Pada `lib/core/failures.dart`, kelas dasar `sealed class Failure` dan subclass-nya tidak meng-override method `toString()`.
- **Dampak:** Interpolasi string atau logging `$failure` menghasilkan representasi objek default Dart, bukan pesan kesalahan yang ada di dalam properti `message`.
- **Usulan Konkret:** Tambahkan `@override String toString() => message;` pada kelas `Failure` agar representasi string selalu berupa pesan deskriptif.

#### 3. Temuan Arsitektur (Architecture)
- **Observasi:** Terdapat file `lib/messaging/route_parser.dart` yang mendefinisikan fungsi `routeFromMessage` dengan implementasi yang identik dengan fungsi di `lib/core/format.dart`, namun file di folder `messaging/` tidak pernah diimpor oleh file mana pun (*dead code*). Selain itu, fungsi routing notifikasi ditempatkan di file `format.dart` bersamaan dengan `formatDate`.
- **Dampak:** Melanggar prinsip *Separation of Concerns* (SoC) dan *Single Responsibility Principle* (SRP), serta menimbulkan kebingungan pengembang mana file parser yang aktif digunakan.
- **Usulan Konkret:** Satukan utilitas routing ke dalam package messaging/routes khusus dan pisahkan dari utilitas format tanggal murni.

#### 4. Temuan Pengujian (Testing)
- **Observasi:** Pengujian unit di `test/auth_push_test.dart` berfokus pada alur token store dan dio interceptor, namun fungsi utilitas `formatDate` dan `errorMessage` belum diuji secara independen dengan variasi input tepi (*boundary inputs*).
- **Dampak:** Potensi regresi logika formatting tanggal atau pesan error tidak terdeteksi otomatis oleh automated test runner.
- **Usulan Konkret:** Tambahkan test case unit untuk fungsi `formatDate` (termasuk tanggal awal bulan/tahun baru) dan `errorMessage` (untuk `Exception`, `Failure`, dan string mentah).

#### 5. Saran Keterbacaan (Readability)
- **Observasi:** Array `_bulan` di `lib/core/format.dart` menggunakan indeks langsung `d.month - 1` tanpa guard clause jika suatu saat nilai tanggal di luar rentang standar kalender masehi 1–12.
- **Dampak:** Keterbacaan kode sedikit berkurang dan rentan *RangeError* jika ada data DateTime abnormal.
- **Usulan Konkret:** Tambahkan komentar dokumentasi (docstring) yang jelas pada fungsi `formatDate` dan pastikan data tanggal yang masuk tervalidasi.

---

### C. Keputusan Akhir Reviewer
- **Status Review:** **Request Changes** (Perlu perbaikan penanganan `Failure` dan pembersihan dead code sebelum di-merge ke branch `develop`).
- **Setelah Perbaikan:** **Approved** (Semua 15 test lulus dan arsitektur tetap bersih).

---

### D. Langkah Praktis Membuat Pull Request di GitHub (Panduan Mandiri)
1. Buat branch fitur dari `develop`:
   ```bash
   git checkout -b fix/error-handling develop
   ```
2. Commit perubahan dengan pesan yang terstruktur:
   ```bash
   git commit -m "fix(core): tangani Failure pada helper errorMessage"
   ```
3. Push branch ke GitHub:
   ```bash
   git push origin fix/error-handling
   ```
4. Buka repositori di GitHub, pilih menu **Pull requests** > **New pull request**.
5. Pilih `base: develop` dan `compare: fix/error-handling`.
6. Isi judul dan deskripsi PR menggunakan template di atas, lalu minta rekan mahasiswa/dosen untuk mereview (Assign Reviewer).
7. Setelah direview dan disetujui (*Approve*), lakukan **Squash and merge** atau **Rebase and merge**.


---

## 3. Praktikum 3: Static Analysis, CI GitHub Actions, dan Evaluasi Arsitektur

### A. Hasil Pemeriksaan Static Analysis & Formatter Aktual
Pemeriksaan dijalankan pada root project `08-week-8-mid-project-review/campus_notify`:

1. **`flutter analyze`:**
   - **Hasil:** `No issues found! (ran in 41.8s)`
   - **Status:** **PASS (0 issue / 0 warning / 0 error)**. Kode memenuhi seluruh aturan linter `flutter_lints ^6.0.0`.
2. **`flutter test`:**
   - **Hasil:** 
     - `test/auth_push_test.dart`: 11 passed (autentikasi, token refresh, Dio interceptor, mapping friendly error).
     - `test/get_announcements_test.dart`: 4 passed (GetAnnouncements usecase, handling failure, filter kategori).
     - Total: **15 tests passed (100% lulus)**.
   - **Status:** **PASS**.
3. **`dart format`:**
   - **Hasil:** `dart format --output=none --set-exit-if-changed lib test` mengidentifikasi 26 file yang dapat dirapikan spasi dan indentasinya sesuai gaya standar Dart.
   - **Keputusan:** Sesuai prinsip kehati-hatian praktikum, reformat massal tidak dijalankan secara agresif ke seluruh file agar tidak menimbulkan diff commit yang tidak perlu (*noise*).

### B. Konfigurasi CI GitHub Actions
File workflow CI minimal telah dikonfigurasikan pada `.github/workflows/ci.yml` dengan spesifikasi:
- **Trigger:** Event `push` dan `pull_request` pada branch `main` dan `develop`.
- **Environment:** `ubuntu-latest` dengan `subosito/flutter-action@v2` (channel `stable`).
- **Tahapan CI:**
  1. `actions/checkout@v4`
  2. Setup Flutter SDK
  3. `flutter pub get` pada folder `campus_notify`
  4. `flutter analyze` untuk mencegah kode bermasalah ter-merge
  5. `flutter test` untuk memastikan seluruh unit test lulus secara otomatis

### C. Evaluasi Kepatuhan Clean Architecture (`campus_notify`)

Pemeriksaan aktual terhadap batasan arsitektur *feature-first Clean Architecture*:

| Aturan Arsitektur | Kondisi Aktual pada Kode | Status Kepatuhan |
|---|---|---|
| **Presentation Layer Independence** | Halaman (`HomePage`, `AnnouncementPage`, `LoginPage`) hanya mengonsumsi state dari Riverpod providers (`announcement_providers.dart`, `auth_providers.dart`). Logika bisnis filtering atau autentikasi didelegasikan ke layer usecase. | **PATUH** |
| **Domain Layer Purity** | Layer domain (`lib/features/*/domain/`) tidak mengimpor `package:flutter`, `package:dio`, `package:sqflite`, atau pustaka eksternal lainnya. Domain hanya berisi pure Dart entities, repository interfaces, dan usecases. | **PATUH (100% Pure Dart)** |
| **Data Layer Responsibility** | Data sources (`announcement_mock_source.dart`) dan Repositories (`announcement_repository_impl.dart`, `auth_repository_impl.dart`) mengimplementasikan kontrak interface dari domain. Konversi data JSON ke Entity dilakukan via `AnnouncementModel.fromJson` dan `toEntity()`. | **PATUH** |
| **Dependency Injection** | Seluruh ketergantungan (API client, token store, repository, usecase) dihubungkan menggunakan Riverpod providers, memungkinkan pengujian mudah di-mock via `ProviderScope` override. | **PATUH** |
