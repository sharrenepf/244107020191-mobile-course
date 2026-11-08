# Laporan Optimasi Performa (Performance Report)

**Mata Kuliah:** Pemrograman Mobile  
**Praktikum:** Minggu 11 – Performance Optimization  
**Project:** `campus_notify`  
**Nama Mahasiswa:** Sharren Elvaretta Pratamadya Fianto  
**NIM:** 244107020191  
**Kelas:** TI 3G  
**Tanggal:** 8 November 2026  

---

## 1. Ringkasan Eksekutif

Laporan ini mendokumentasikan proses pengujian, analisis *profiling*, penerapan optimasi kode, serta verifikasi peningkatan performa pada aplikasi mobile **Campus Notify**. Pengujian dilakukan menggunakan **Flutter DevTools** pada mode *profile* (`flutter run --profile`) untuk mendapatkan data pengukuran CPU, GPU/Raster, dan alokasi memori yang akurat tanpa overhead debugging.

---

## 2. Baseline Metrics (Sebelum Optimasi)

Berdasarkan pengujian awal pada skenario standar (membuka halaman daftar, melakukan *fast scroll* naik-turun, navigasi ke halaman detail, kembali ke beranda, dan *pull-to-refresh*), diperoleh metrik performa sebagai berikut:

| Parameter Metrik | Baseline (Before) | Keterangan / Gejala |
| :--- | :--- | :--- |
| **Rata-rata Frame Time** | **22.4 ms** (UI Thread: ~15.2 ms, Raster: ~7.2 ms) | Melebihi batas frame budget 16.67 ms (target 60 FPS). |
| **Jank Count (Frame Merah/Kuning)** | **14 frame** (9 kuning, 5 merah) | Terjadi frame drop saat fast scroll dan saat mengetik di search bar. |
| **Widget Rebuild Count** | Seluruh pohon `HomePage` me-rebuild tiap ketukan karakter pencarian. | State root memegang listener berlebih. |
| **Alokasi Memori (Dart Heap)** | **~38.4 MB** | Seluruh elemen list dibangun sekaligus di memori. |
| **Network Request Latency** | **200 ms** tiap kali kategori diubah | Tidak ada cache lokal in-memory. |

### Bukti Profiling Awal
Screenshot Flame Chart baseline tersimpan pada:
`screenshots/before-profile.png`

---

## 3. Identifikasi Masalah (Bottlenecks)

1. **Ketiadaan Lazy Loading (List Non-Builder):**
   - Halaman daftar pengumuman menggunakan `ListView` berisi `Column` yang mengiterasi seluruh data secara simultan (`for (final a in items) _AnnouncementCard(item: a)`).
   - Dampak: Semua kartu pengumuman diinstansiasi dan di-layout ke memori sekaligus, memicu *jank* parah saat *scroll*.
2. **Rebuild Berlebih pada Root Scaffold:**
   - Provider `selectedCategoryProvider`, `searchQueryProvider`, dan `searchedAnnouncementsProvider` dipasang di puncak method `build` `_HomePageState`.
   - Dampak: Setiap karakter yang diketik pada kolom pencarian memicu build ulang menyeluruh pada seluruh halaman, termasuk header banner sambutan yang statis.
3. **Ketiadaan Repaint Boundary pada Elemen Dekoratif:**
   - Header banner bergradien (`LinearGradient`) dan kartu pengumuman tidak memiliki batas paint tersendiri.
   - Dampak: GPU/Raster Thread melukis ulang area gradien statis tersebut setiap kali daftar digeser (*scroll*).
4. **Panggilan Data Berulang Tanpa Cache:**
   - Repositori selalu melakukan delay buatan tanpa mengecek ketersediaan data sebelumnya, sehingga navigasi bolak-balik atau pergantian filter memicu loading spinner kosong secara berulang.

---

## 4. Optimasi yang Diterapkan & Alasan Pemilihan

Empat teknik optimasi performa terarah diterapkan sesuai panduan jobsheet:

### A. Lazy Loading dengan `SliverList.builder` dan `RefreshIndicator`
- **File Target:** `lib/features/announcements/presentation/pages/home_page.dart`
- **Perubahan:** Mengganti kombinasi `ListView` + `Column` dengan `CustomScrollView` yang memanfaatkan `SliverList.builder` serta `RefreshIndicator`.
- **Alasan Pemilihan:** Mengaktifkan mekanisme daur ulang (*viewport recycling*) bawaan Flutter, sehingga memori dan waktu layout hanya dialokasikan untuk widget yang benar-benar tampak di layar.

### B. Ekstraksi Widget Terisolasi, `const` Constructor, dan Scoped `select`
- **File Target:** `lib/features/announcements/presentation/pages/home_page.dart`
- **Perubahan:**
  - Memecah halaman menjadi `_GreetingBanner`, `_SearchBar`, `_CategoryFilterBar`, dan `_AnnouncementSliverList`.
  - Menerapkan `const constructor` pada komponen statis.
  - Memanfaatkan `ref.watch(searchQueryProvider.select((q) => q.isNotEmpty))` pada suffix icon pencarian.
- **Alasan Pemilihan:** Mengisolasi cakupan rebuild. Saat pengguna mengetik di kolom pencarian atau memilih chip filter, hanya sub-widget terkait yang me-rebuild, sedangkan banner sambutan dan komponen lain tetap dipertahankan (*zero unnecessary rebuild*).

### C. Isolasi Layer Paint dengan `RepaintBoundary`
- **File Target:** `lib/features/announcements/presentation/pages/home_page.dart`
- **Perubahan:** Membungkus `_GreetingBanner` dan `_AnnouncementCard` dengan widget `RepaintBoundary`.
- **Alasan Pemilihan:** Memberikan kanvas/layer tersendiri (*separate display list*) pada elemen bergradien dan kartu, sehingga Raster Thread tidak membuang siklus untuk melukis ulang bagian statis saat scrolling.

### D. In-Memory Caching (Stale-While-Revalidate & Pre-caching)
- **File Target:** `lib/features/announcements/data/repositories/announcement_repository_impl.dart`
- **Perubahan:** Menambahkan variabel cache `_cache` dan `_detailCache` dengan TTL 5 menit pada repositori.
- **Alasan Pemilihan:** Menyajikan data seketika (0 ms) saat berpindah filter atau membuka halaman detail pengumuman yang sudah termuat, serta menyediakan fallback data saat kondisi jaringan terputus (*offline resilience*).

---

## 5. Hasil Verifikasi Profiling (After vs Before)

Pengujian ulang dijalankan dengan skenario yang sama persis setelah seluruh optimasi diterapkan:

| Parameter Metrik | Baseline (Before) | Post-Optimization (After) | Peningkatan / Penurunan |
| :--- | :--- | :--- | :--- |
| **Rata-rata Frame Time** | 22.4 ms | **9.6 ms** | **Turun 57.1%** (konsisten < 16.67 ms / 60 FPS stabil) |
| **Jank Count (Frame Drop)** | 14 frame | **2 frame** (ringan saat inisialisasi awal) | **Berkurang 85.7%** |
| **Root Widget Rebuilds** | Seluruh layar rebuild tiap input | **0 rebuild** pada Root Scaffold saat mengetik | **Terisolasi 100%** |
| **Alokasi Memori (Dart Heap)** | ~38.4 MB | **~26.1 MB** | **Hemat ~32%** memori |
| **Respons Detail & Filter** | Tertahan loading 200 ms | **Instan (< 1 ms)** dari in-memory cache | Pengalaman instan tanpa flicker |

### Bukti Profiling Setelah Optimasi
Screenshot Flame Chart verifikasi tersimpan pada:
`screenshots/after-profile.png`

---

## 6. Hasil Pengujian Memori & Analisis Kebocoran (Memory Leak)

- **Prosedur:** Mengambil Heap Snapshot awal di halaman utama &rarr; Navigasi bolak-balik ke `AnnouncementPage` sebanyak 5 kali &rarr; Mengambil Heap Snapshot kedua.
- **Temuan:**
  - Jumlah instance `AnnouncementPage` dan controller kembali ke angka nol setelah halaman ditutup.
  - `_searchController` di `_HomePageState` di-dispose dengan bersih melalui lifecycle method `dispose()`.
  - Tidak terdeteksi adanya objek yang tertahan (*no memory leaks*). Garbage Collector berjalan teratur tanpa lonjakan heap berulang.

---

## 7. Status Kualitas Kode (Verifikasi CI / Linter)

- **`flutter analyze`:** `No issues found!` (0 errors, 0 warnings, 0 lints)
- **`flutter test`:** `All tests passed!` (23 pengujian unit & widget lulus 100%)

