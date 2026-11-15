# AI Challenge: Output Awal AI

Berikut adalah tanggapan awal dari AI assistant saat diberikan prompt perancangan Clean Architecture untuk `campus_notify`:

---

### Usulan Arsitektur:
1. Pisahkan seluruh fitur ke dalam `features/auth/` dan `features/announcements/` dengan struktur feature-first (`data`, `domain`, `presentation`).
2. Masukkan semua use case terpisah untuk setiap aksi:
   - `LoginUseCase`
   - `LogoutUseCase`
   - `CheckSessionUseCase`
   - `GetAnnouncementsUseCase`
   - `GetAnnouncementDetailUseCase`
3. Letakkan infrastruktur bersama seperti `api_client.dart` di dalam `lib/core/network/` dan gunakan `get_it` atau Riverpod untuk DI.
4. Buat mapping DTO/Model pada layer data yang ditransformasi ke domain Entity murni.
5. Gunakan Record Dart `({T? data, Failure? failure})` untuk meminimalkan ketergantungan pada pustaka pihak ketiga seperti `fpdart`.

---

### Analisis Awal Trade-off oleh AI:
- **Kelebihan**: Sangat modular, mudah diuji secara unit test tanpa framework UI/database.
- **Biaya/Overhead**: Jumlah file berlipat ganda, khususnya untuk operasi CRUD sederhana satu baris (seperti mengambil detail pengumuman berdasarkan ID).
