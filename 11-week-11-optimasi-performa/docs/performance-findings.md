# Temuan Profiling Performa (Performance Findings)

**Project:** `campus_notify`  
**Modul:** Minggu 11 - Optimasi Performa Flutter  
**Tanggal:** 8 November 2026  

---

## 1. Ringkasan Eksekutif
Berdasarkan hasil baseline profiling pada mode profile (`flutter run --profile`) menggunakan Flutter DevTools (tab Performance & Memory) serta analisis struktur kode sumber, teridentifikasi beberapa bottleneck yang memengaruhi frame rate (jank), konsumsi memori, dan efisiensi rendering pada aplikasi.

---

## 2. Identifikasi Masalah Utama

### Masalah 1: List Tidak Menggunakan Builder (Ketiadaan Lazy Loading)
- **Lokasi Kode:** `lib/features/announcements/presentation/pages/home_page.dart` (baris 63–65 dan 204–206).
- **Kategori:** CPU/Build & Memori.
- **Gejala Profiling:**
  - Terjadi lonjakan frame time (frame kuning/merah) saat scrolling cepat.
  - Event `Layout` dan `Build` pada Timeline memakan waktu signifikan karena seluruh widget card diinstansiasi sekaligus.
- **Penyebab Teknis:**
  Halaman utama menggunakan `ListView(children: [...])` dan merender item daftar menggunakan `Column(children: [for (final a in items) _AnnouncementCard(item: a)])`. Hal ini menonaktifkan mekanisme recycling/lazy loading bawaan Flutter. Semua item pengumuman dipaksa dibuat dan di-layout ke memori meskipun berada jauh di luar viewport layar.
- **Rencana Solusi:**
  Mengganti implementasi menjadi `ListView.builder` dengan `SliverList` atau custom scroll view ber-builder terpisah, sehingga widget hanya di-render saat masuk ke dalam viewport layar.

---

### Masalah 2: Rebuild Widget Berlebih pada Root Scaffold (Root-Level Watchers)
- **Lokasi Kode:** `lib/features/announcements/presentation/pages/home_page.dart` (baris 36–41).
- **Kategori:** CPU/Build (Widget Rebuild).
- **Gejala Profiling:**
  - Flame Chart menunjukkan pemanggilan `HomePage.build` berulang-ulang setiap kali karakter pencarian diketik atau chip kategori ditekan.
  - Call stack UI Thread mencatat rebuild pada seluruh subtree widget Scaffold.
- **Penyebab Teknis:**
  `ref.watch(selectedCategoryProvider)`, `ref.watch(searchQueryProvider)`, dan `ref.watch(searchedAnnouncementsProvider)` ditempatkan langsung di puncak method `build` kelas `_HomePageState`. Akibatnya, setiap perubahan input pencarian sekecil apa pun memicu rebuild total seluruh halaman, termasuk header banner sambutan (gradient container) yang bersifat statis. Selain itu, belum semua widget statis memanfaatkan `const` constructor dan pemisahan sub-widget terisolasi (`Consumer`).
- **Rencana Solusi:**
  - Memisahkan komponen (Banner Header, Search & Filter Bar, Announcement List) ke dalam widget terpisah atau melokalisasi `ref.watch` menggunakan widget `Consumer`.
  - Menerapkan `const constructor` secara konsisten pada seluruh widget statis.

---

### Masalah 3: Ketiadaan RepaintBoundary untuk Isolasi Area Render Berat
- **Lokasi Kode:** `lib/features/announcements/presentation/pages/home_page.dart` (Header banner gradien & Card pengumuman).
- **Kategori:** Raster/Paint.
- **Gejala Profiling:**
  - Seluruh layer kanvas di-repaint saat list melakukan scrolling atau saat chip filter berubah status.
  - Raster Thread terbebani oleh operasi repaint elemen dekoratif gradien yang sebetulnya tidak mengalami perubahan tampilan.
- **Penyebab Teknis:**
  Banner header memiliki dekorasi visual yang relatif kompleks (`BoxDecoration` dengan `LinearGradient` dan `BorderRadius`). Tanpa pembungkus `RepaintBoundary`, Flutter akan menggabungkan layer header ke dalam flow repaint scroll view utama, menyebabkan raster thread melukis ulang bagian statis tersebut.
- **Rencana Solusi:**
  Membungkus banner header dan/atau widget kartu dengan `RepaintBoundary` agar memiliki display list terpisah dan tidak ikut di-paint ulang saat scrolling.

---

### Masalah 4: Ketiadaan Mekanisme Cache (Stale-While-Revalidate) pada Pengambilan Data
- **Lokasi Kode:** `lib/features/announcements/data/repositories/announcement_repository_impl.dart`.
- **Kategori:** Jaringan & User Experience.
- **Gejala Profiling:**
  - Setiap kali provider di-refresh atau di-invalidate (misal saat pull-to-refresh atau ganti filter), UI selalu mengalami flash loading spinner kosong (`CircularProgressIndicator`) dan tertahan latensi jaringan tiruan.
- **Penyebab Teknis:**
  Repository belum mengimplementasikan strategi caching in-memory (*stale-while-revalidate*). Repository langsung mengeksekusi fetch tanpa menyajikan data cache lokal yang sudah tersedia sebelumnya.
- **Rencana Solusi:**
  Menerapkan mekanisme in-memory caching pada repository dengan pola *stale-while-revalidate*: kembalikan data cache yang tersimpan secara instan, lakukan pembaruan data secara asinkron di latar belakang, dan perbarui state tanpa memblokir UI.

---

## 3. Kesimpulan Prioritas Optimasi
Berdasarkan temuan di atas, optimasi yang paling tepat dan relevan untuk diterapkan pada Langkah 3 adalah:
1. **Penerapan Lazy Loading (`ListView.builder`)** untuk mengatasi masalah alokasi berlebih pada list.
2. **Ekstraksi Widget & Penggunaan `const` Constructor + Riverpod Scoping (`Consumer`)** untuk mencegah rebuild berlebih di root widget.
3. **Penerapan `RepaintBoundary`** untuk mengisolasi proses paint pada elemen bergradien/dekoratif.
4. **Implementasi In-Memory Caching (Stale-While-Revalidate)** pada Repository layer.

