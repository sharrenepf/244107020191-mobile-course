# Pemrograman Mobile

## Praktikum Week 11 - Performance Optimization

## Identitas

| Field | Detail |
| :--- | :--- |
| **Nama** | *Sharren Elvaretta Pratamadya Fianto* |
| **NIM** | *244107020191* |
| **Kelas** | *TI 3G* |
| **Langkah 1: Baseline Profiling** | campus_notify |
| **Langkah 2: Identifikasi Masalah** | campus_notify |
| **Langkah 3: Terapkan Optimasi** | campus_notify |
| **Langkah 4: Verifikasi Profiling** | campus_notify |
| **Langkah 5: Memory Profiling** | campus_notify |
| **Tugas Praktikum / Industry Challenge** | Pertemuan 11 |

---

# Ringkasan Proyek

* **Project Name**: `campus_notify`
* **Tujuan**: Mengoptimalkan performa aplikasi `campus_notify` (hasil Week 7–10) menggunakan Flutter DevTools, dengan menerapkan minimal 3 teknik optimasi dan memverifikasinya lewat profiling sebelum dan sesudah.
* **Fokus Optimasi**: Mengurangi widget rebuild, lazy loading list, dan (opsional) caching/optimasi gambar.
* **Tech Stack**: Flutter (Dart 3.x), Flutter Riverpod, GoRouter, Dio, Flutter DevTools (mode `--profile`).

---

# Konsep Singkat

1. **Frame budget**: 16,67 ms (60 FPS). Frame yang melebihi budget menyebabkan *jank*.
2. **UI Thread** menangani build, layout, paint. **Raster Thread** menangani rendering GPU.
3. **Profiling wajib di mode `--profile`**, karena mode debug punya overhead besar sehingga hasilnya tidak akurat.
4. **Alur kerja**: ukur (baseline) → temukan masalah → optimasi → ukur ulang (verifikasi).

---

# Langkah 1: Baseline Profiling

```bash
flutter run --profile
```

DevTools → tab **Performance** → **Record**. Skenario yang dijalankan (dan diulang persis sama saat verifikasi):

1. Buka daftar pengumuman
2. Scroll cepat
3. Buka detail
4. Kembali
5. Pull-to-refresh

### Metrics Baseline (Before)

| Metrik | Nilai |
| :--- | :---: |
| Jumlah frame merah (>32 ms) | [ISI] |
| Jumlah frame kuning (16–32 ms) | [ISI] |
| Rata-rata frame time | [ISI] ms |
| Fungsi teratas di Flame Chart | [ISI] |
| Memory (Heap) awal | [ISI] MB |

| Flame Chart Before |
| :---: |
| ![Before Profile](screenshots/before-profile.png) |

---

# Langkah 2: Identifikasi Masalah

Temuan lengkap ada di [`docs/performance-findings.md`](docs/performance-findings.md).

| No | Masalah | Bukti di DevTools | Lokasi File |
| :-: | :--- | :--- | :--- |
| 1 | Widget rebuild berlebih | [ISI: `build` berulang di Flame Chart] | [ISI: file.dart] |
| 2 | [ISI: mis. list belum pakai builder / request berulang tanpa cache] | [ISI] | [ISI] |
| 3 | [ISI] | [ISI] | [ISI] |

---

# Langkah 3: Terapkan Optimasi

| No | Optimasi | Diterapkan di | Alasan Pemilihan |
| :-: | :--- | :--- | :--- |
| 1 | `const` constructor / ekstrak widget | [ISI: file.dart] | Widget statis tidak ikut rebuild saat parent rebuild |
| 2 | Riverpod `select` | [ISI: file.dart] | Widget hanya rebuild saat field yang dipakai berubah |
| 3 | `ListView.builder` | [ISI: file.dart] | Hanya item yang terlihat yang dibangun |

> Sesuaikan tabel dengan optimasi yang benar-benar diterapkan. Contoh sebelum/sesudah kode:

```dart
// Sebelum
final state = ref.watch(announcementProvider);

// Sesudah
final count = ref.watch(announcementProvider.select((s) => s.length));
```

---

# Langkah 4: Verifikasi Profiling

Skenario yang sama dijalankan ulang dengan `flutter run --profile`.

| Metrik | Before | After | Perubahan |
| :--- | :---: | :---: | :---: |
| Frame merah | [ISI] | [ISI] | [ISI] |
| Frame kuning | [ISI] | [ISI] | [ISI] |
| Rata-rata frame time | [ISI] ms | [ISI] ms | [ISI] |

| Flame Chart Before | Flame Chart After |
| :---: | :---: |
| ![Before](screenshots/before-profile.png) | ![After](screenshots/after-profile.png) |

---

# Langkah 5: Memory Profiling

Prosedur: Heap Snapshot di halaman daftar → buka detail lalu kembali (ulang 5x) → snapshot kedua → bandingkan.

| Metrik | Snapshot 1 | Snapshot 2 |
| :--- | :---: | :---: |
| Heap size | [ISI] MB | [ISI] MB |
| Instance halaman/controller menumpuk? | - | [ISI: Ya/Tidak] |

* **Hasil**: [ISI: tidak ada leak / ada leak pada ... dan diperbaiki dengan `dispose()`]

---

# Dokumentasi

* [`docs/performance-findings.md`](docs/performance-findings.md): Temuan dari profiling.
* [`docs/performance-report.md`](docs/performance-report.md): Baseline, optimasi, dan hasil verifikasi.

---

# Verifikasi Statis

| Flutter Analyze | Flutter Test |
| :---: | :---: |
| ![Analyze](screenshots/analyze.png) | ![Test](screenshots/test.png) |

* `flutter analyze`: [ISI: No issues found!]
* `flutter test`: [ISI: All tests passed!]

---

# Error Umum dan Solusinya

| Gejala | Penyebab Umum | Solusi |
| :--- | :--- | :--- |
| Hasil profiling tidak akurat / banyak jank | Dijalankan di mode debug | Gunakan `flutter run --profile` |
| `Out of memory` saat build Gradle | RAM laptop tidak cukup | `flutter clean`, tutup aplikasi lain |
| `const` error "not a constant expression" | Ada parameter non-const di dalam widget | Hapus `const` pada widget induk atau ekstrak bagian yang dinamis |
| Heap terus naik saat navigasi | `controller`/listener/subscription tidak di-`dispose()` | Tambahkan `dispose()` yang benar |

---

# Checklist Verifikasi Mandiri

* [x] Baseline profiling dilakukan di mode `--profile`.
* [x] `screenshots/before-profile.png` dan `after-profile.png` tersedia.
* [x] Minimal 3 masalah tercatat di `docs/performance-findings.md`.
* [x] Minimal 3 optimasi diterapkan dan berkaitan dengan masalah yang ditemukan.
* [x] Skenario before dan after identik.
* [x] Memory profiling dilakukan (5x navigasi bolak-balik).
* [x] `docs/performance-report.md` lengkap.
* [x] `flutter analyze` bersih.
* [x] `flutter test` lulus.

---

# Kesimpulan

1. Optimasi harus berdasarkan **data profiling**, bukan tebakan.
2. Optimasi sederhana seperti `const`, `select`, dan `ListView.builder` murah diterapkan tetapi berdampak nyata pada jumlah rebuild.
3. Verifikasi dengan skenario yang sama sebelum dan sesudah membuktikan optimasi bekerja.
4. Memory profiling memastikan tidak ada objek yang menumpuk setelah navigasi berulang.

---

# Refleksi

### 1. Optimasi mana yang memberikan dampak terbesar dan mengapa?
[ISI sesuai hasil nyata, contoh jawaban:] Optimasi **Riverpod `select` + `const` constructor** berdampak terbesar karena mengurangi jumlah `build` yang berulang di Flame Chart, sehingga frame time turun dan frame kuning/merah berkurang. Dampaknya paling besar karena rebuild terjadi pada setiap interaksi (scroll, filter, refresh).

### 2. Bagaimana memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?
Dengan mengukur ulang di mode `--profile` memakai **skenario yang sama persis**, lalu membandingkan metrik before vs after (jumlah frame merah/kuning, rata-rata frame time, memori). Jika angkanya tidak membaik, optimasi tersebut tidak terbukti efektif.

### 3. Trade-off apa yang dihadapi?
Kompleksitas kode vs performa. Contohnya `select` dan ekstrak widget menambah jumlah file/baris dan membuat kode lebih sulit dibaca, sementara caching menambah risiko data basi (*stale*). Optimasi hanya layak jika manfaatnya terukur.

### 4. Kapan optimasi prematur sebaiknya dihindari?
Saat belum ada bukti masalah dari profiling, atau saat aplikasi masih berkembang dan kodenya sering berubah. Optimasi tanpa data hanya menambah kompleksitas tanpa hasil jelas. Ukur dulu, baru optimasi bagian yang benar-benar menjadi bottleneck.
