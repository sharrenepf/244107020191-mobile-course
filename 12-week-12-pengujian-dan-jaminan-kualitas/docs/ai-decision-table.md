# AI Challenge: Tabel Usulan vs Keputusan Final

| Usulan AI | Keputusan Final | Alasan Teknis & Trade-off |
| :--- | :--- | :--- |
| **Use case untuk semua operasi** (`Login`, `Logout`, `GetAnnouncements`, `GetAnnouncementDetail`) | Hanya buat use case untuk `GetAnnouncements` dan `Login`. Operasi detail dan logout langsung memanggil repository. | Detail pengumuman (`fetchById`) dan logout hanya 1 baris tanpa aturan bisnis (tidak ada sorting/validasi/transformasi). Membuat class use case terpisah adalah **over-engineering** (boilerplate tanpa nilai tambah). |
| **Menaruh `api_client.dart` di `lib/core/`** | Memindahkan ke `lib/shared/data/api_client.dart`. Folder `lib/core/` dipertahankan murni Dart. | Aturan sterilitas Clean Architecture melarang `lib/core/` mengimpor library luar seperti `dio` atau `firebase`. Jika ditaruh di `core/`, uji sterilitas grep akan gagal. |
| **Menambahkan package DI terpisah (`get_it`)** | Menggunakan bawaan **Riverpod** (`Provider`, `FutureProvider`, `NotifierProvider`). | Riverpod sudah bertindak sebagai DI container deklaratif yang compile-time safe. Menambah `get_it` menambah kompleksitas dependencies tanpa keuntungan nyata. |
| **Menaruh Interface & Implementasi di folder yang sama** | Interface di `domain/repositories/` dan implementasi di `data/repositories/`. | Prinsip Dependency Inversion: domain tidak boleh tahu detail implementasi (Dio/SQLite/Mock). Menyatukannya melanggar aturan dependensi Clean Architecture. |
| **StateProvider untuk filter kategori UI** | Menggunakan `NotifierProvider` dengan `CategoryNotifier` murni. | Pada Flutter & `flutter_riverpod: ^3.x`, `StateProvider` telah deprecated/dihapus. Penggunaan `NotifierProvider` lebih modern dan type-safe. |
