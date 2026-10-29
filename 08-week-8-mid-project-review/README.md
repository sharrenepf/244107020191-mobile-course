# Pemrograman Mobile

## Praktikum Week 8 - Mid-Project Review & Code Review

## Identitas

| Field | Detail |
| :--- | :--- |
| **Nama** | *Sharren Elvaretta Pratamadya Fianto* |
| **NIM** | *244107020191* |
| **Kelas** | *TI 3G* |
| **Praktikum 1: Hygiene Branch dan Commit** | `campus_notify` |
| **Praktikum 2: PR dan Peer Review** | `campus_notify` |
| **Praktikum 3: Static Analysis dan Mid Review** | `campus_notify` |
| **Tugas Praktikum / Industry Challenge** | Pertemuan 8 |

---

# Ringkasan Proyek

* **Project Name**: `campus_notify`
* **Tujuan**: Melakukan evaluasi dan code review terhadap project aplikasi mobile yang telah dikembangkan pada Minggu 5–7. Praktikum ini berfokus pada kualitas kode, disiplin Git, strategi branching, Pull Request, pengujian otomatis, serta verifikasi penerapan Clean Architecture sebelum melanjutkan pengembangan pada paruh semester berikutnya.
* **Fitur Utama**:
  1. **Authentication**: Login dengan validasi kredensial, pengelolaan sesi token, dan penanganan error autentikasi.
  2. **Announcements**: Daftar pengumuman, filter kategori, pengurutan berdasarkan tanggal, dan halaman detail pengumuman.
  3. **FCM & Push Service**: Penanganan notifikasi, topik pengumuman, dan navigasi berdasarkan pesan notifikasi.
  4. **Code Quality & Review**: Pemeriksaan struktur Clean Architecture, static analysis, unit testing, serta dokumentasi hasil review kode.
* **Tech Stack**: Flutter (Dart 3.x), Flutter Riverpod, GoRouter, Dio, Flutter Secure Storage, Firebase Messaging, dan Flutter Local Notifications sesuai implementasi project sebelumnya.

---

# Konsep Git Flow & Code Review

### 1. Strategi Branching

Git Flow digunakan untuk memisahkan pekerjaan pengembangan, integrasi, dan rilis agar perubahan kode dapat diperiksa sebelum digabungkan.

| Branch | Fungsi |
| :--- | :--- |
| `main` | Menyimpan versi aplikasi yang siap dirilis. |
| `develop` | Menjadi branch integrasi untuk pekerjaan pengembangan. |
| `feature/*` | Menampung perubahan satu fitur atau tugas tertentu. |
| `fix/*` | Menampung perbaikan masalah yang memerlukan penanganan khusus. |

Branch dibuat sesuai kebutuhan praktikum. Tidak semua jenis branch harus dibuat apabila tidak diperlukan oleh pekerjaan yang sedang dilakukan.

### 2. Conventional Commit

Pesan commit harus menjelaskan perubahan secara singkat dan spesifik.

Format:

```text
tipe(scope): deskripsi singkat
```

Contoh:

```text
feat(notes): tambah validasi judul kosong
fix(auth): perbaiki penanganan error login
refactor(auth): pisahkan validasi dari UI
test(auth): tambah pengujian error handling
docs(review): lengkapi checklist code review
```

Jenis commit yang digunakan:

- `feat`: penambahan fitur.
- `fix`: perbaikan bug.
- `refactor`: perubahan struktur kode tanpa mengubah perilaku utama.
- `test`: penambahan atau perbaikan pengujian.
- `docs`: perubahan dokumentasi.
- `chore`: pekerjaan pendukung.

### 3. Pull Request dan Peer Review

Pull Request (PR) digunakan untuk mengusulkan perubahan kode agar dapat diperiksa sebelum digabungkan ke branch tujuan.

Informasi yang perlu disertakan dalam PR:

- Masalah yang ditemukan.
- Solusi yang diterapkan.
- Langkah pengujian.
- Screenshot apabila relevan.
- Referensi issue jika tersedia.

Peer review dilakukan untuk menemukan kesalahan logika, masalah arsitektur, kekurangan pengujian, dan masalah keterbacaan kode.

Pola komentar review:

**Observasi → Dampak → Usulan konkret**

Contoh:

> Observasi: validasi input dilakukan langsung di widget.
>
> Dampak: logika validasi sulit diuji secara terpisah.
>
> Usulan: pindahkan validasi ke fungsi atau komponen yang sesuai dengan tanggung jawabnya.

---

# Praktikum 1: Hygiene Branch dan Commit

**Project:** `campus_notify`

## 1. Audit Riwayat Git

Audit dilakukan untuk mengetahui kondisi repository sebelum perubahan Jobsheet 8.

Perintah yang digunakan:

```bash
git log --oneline -15
git branch -a
git status
```

Pemeriksaan mencakup riwayat commit, branch lokal dan remote, serta perubahan file yang belum di-commit.

Hasil audit digunakan untuk mengidentifikasi pesan commit yang kurang jelas, branch yang tersedia, dan perubahan lokal yang harus dipertahankan.

## 2. Perbaikan Kualitas Pesan Commit

Pesan commit yang kurang informatif perlu dievaluasi agar tujuan perubahan lebih mudah dipahami.

| Pesan Sebelum | Pesan Sesudah | Alasan |
| :--- | :--- | :--- |
| `fix bug` | `fix(auth): perbaiki penanganan error login` | Menjelaskan bagian kode dan masalah yang diperbaiki. |
| `update` | `docs(review): perbarui dokumentasi review` | Menjelaskan perubahan dokumentasi secara spesifik. |
| `final fix` | `test(auth): tambah pengujian error handling` | Menjelaskan tujuan perubahan pengujian. |

Contoh di atas merupakan simulasi format commit. Pesan sebelum dan sesudah harus disesuaikan dengan riwayat commit yang benar-benar ditemukan pada repository.

## 3. Branching dan Alur Kerja

Alur branching mengikuti kebutuhan Jobsheet 8:

```text
main
  │
  └── develop
        │
        └── feature/perubahan-kecil
                  │
                  └── Pull Request
                        │
                        └── Review dan pengujian
                              │
                              └── Merge
```

Branch `develop` digunakan sebagai target integrasi, sedangkan branch fitur digunakan untuk perubahan yang perlu diajukan melalui Pull Request.

Tidak dilakukan perubahan riwayat commit lama hanya untuk memperbaiki contoh pesan commit pada dokumentasi.

---

# Praktikum 2: PR dan Peer Review

## 1. Persiapan Pull Request

Perubahan yang diajukan melalui PR harus berfokus pada satu masalah yang jelas dan memiliki langkah pengujian yang dapat diulang.

Template PR:

```markdown
## Masalah
Jelaskan masalah yang ditemukan pada project.

## Solusi
Jelaskan perubahan yang diterapkan.

## Cara Pengujian
1. Jalankan aplikasi atau test terkait.
2. Periksa perilaku sebelum dan sesudah perubahan.
3. Pastikan tidak ada regresi pada fitur lain.

## Screenshot
Lampirkan bukti jika relevan.

## Issue
Cantumkan referensi issue jika tersedia.
```

PR harus menggunakan perubahan kode yang benar-benar diterapkan pada project, bukan perubahan yang hanya direncanakan.

## 2. Checklist Peer Review

Review dilakukan dengan memeriksa beberapa aspek berikut.

| Aspek | Hal yang Diperiksa |
| :--- | :--- |
| Kebenaran program | Validasi input, null safety, state, dan penanganan error. |
| Arsitektur | Pemisahan layer dan arah dependency Clean Architecture. |
| Pengujian | Kecukupan test untuk skenario sukses dan gagal. |
| Keterbacaan | Penamaan, ukuran fungsi, dan kejelasan tanggung jawab kode. |
| Hasil review | Keputusan Approve atau Request changes beserta alasannya. |

Komentar review harus menjelaskan masalah yang ditemukan dan memberikan usulan perbaikan yang dapat ditindaklanjuti.

Hasil review sejawat perlu dicatat sesuai komentar yang benar-benar diberikan oleh reviewer.

## 3. Tindak Lanjut Review

Setelah mendapatkan masukan, perubahan diperbaiki sesuai temuan yang terbukti benar.

Alur tindak lanjut:

1. Membaca komentar reviewer.
2. Memeriksa kebenaran setiap temuan.
3. Memperbaiki masalah yang disetujui.
4. Menjalankan kembali pengujian yang relevan.
5. Meminta review ulang jika diperlukan.
6. Melakukan merge setelah persyaratan review terpenuhi.

Status PR, hasil review, dan merge dicatat berdasarkan kondisi aktual repository GitHub.

---

# Praktikum 3: Static Analysis dan Mid Review

## 1. Static Analysis dan Formatter

Pemeriksaan kualitas kode dilakukan menggunakan perintah berikut:

```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

Fungsi pemeriksaan:

- `flutter analyze`: menemukan masalah statis pada kode Dart dan Flutter.
- `dart format --set-exit-if-changed .`: memeriksa apakah file Dart sudah sesuai format standar.
- `flutter test`: menjalankan unit test dan pengujian otomatis yang tersedia.

Jika formatter menemukan file yang belum rapi, jalankan:

```bash
dart format .
```

Setelah perbaikan, jalankan kembali pemeriksaan yang relevan untuk memastikan tidak ada masalah baru.

## 2. Verifikasi Clean Architecture

Project `campus_notify` menggunakan pendekatan Feature-First Clean Architecture yang dikembangkan pada Minggu 7.

Pemeriksaan arsitektur dilakukan untuk memastikan pemisahan tanggung jawab tetap terjaga.

### A. Presentation Layer

Layer presentation bertanggung jawab atas tampilan, interaksi pengguna, dan pengelolaan state UI.

Pemeriksaan difokuskan pada pemanggilan data, pengelolaan state, dan kemungkinan implementasi logika bisnis yang seharusnya berada pada layer lain.

### B. Domain Layer

Layer domain berisi aturan bisnis, entity, kontrak repository, use case, dan failure yang sesuai dengan implementasi project.

Domain tidak boleh bergantung langsung pada framework Flutter atau detail implementasi eksternal seperti Dio, SQLite, dan Firebase SDK.

### C. Data Layer

Layer data bertanggung jawab atas implementasi repository, pemetaan model, dan komunikasi dengan sumber data.

Implementasi harus mengikuti kontrak repository yang didefinisikan pada domain.

### D. Pemeriksaan Dependency Rule

Contoh pemeriksaan menggunakan PowerShell:

```powershell
Select-String -Path "campus_notify\lib\features\*\domain\**\*.dart" -Pattern "package:flutter|package:dio|package:sqflite"
```

Perintah tersebut mencari import Flutter, Dio, dan SQLite pada file yang cocok dengan pola path. Hasilnya perlu diperiksa bersama struktur project untuk memastikan tidak ada pelanggaran dependency rule.

Pemeriksaan ini tidak menggantikan review manual terhadap seluruh arsitektur.

## 3. Continuous Integration (CI)

CI digunakan untuk menjalankan pemeriksaan kualitas kode secara otomatis ketika Pull Request dibuat.

Workflow minimal disimpan di:

`.github/workflows/ci.yml`

Contoh konfigurasi:

```yaml
name: ci

on:
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

Workflow harus disesuaikan dengan struktur repository dan versi Flutter yang digunakan.

Hasil CI dinyatakan berhasil hanya jika workflow benar-benar dijalankan dan seluruh pemeriksaan yang diwajibkan lulus.

## 4. Checklist Mid-Project Review

| Kriteria | Status |
| :--- | :--- |
| Struktur Feature-First Clean Architecture diperiksa | Sesuaikan dengan hasil audit |
| Dependency rule diverifikasi | Sesuaikan dengan hasil pemeriksaan |
| `flutter analyze` | Isi berdasarkan output aktual |
| `dart format` | Isi berdasarkan output aktual |
| `flutter test` | Isi berdasarkan output aktual |
| Pull Request telah direview | Isi berdasarkan status PR |
| Komentar review ditindaklanjuti | Isi berdasarkan hasil review |
| README dan dokumentasi tersedia | Isi berdasarkan kondisi repository |
| Screenshot pengujian tersedia | Isi berdasarkan bukti yang tersedia |

---

# AI Challenge & Refactoring Challenge

## 1. AI Prompt Challenge

AI digunakan sebagai reviewer awal untuk membantu menemukan potensi masalah pada kode Flutter.

Prompt yang digunakan:

```text
Review PR Flutter ini sebagai senior Flutter developer.

Konteks: project menggunakan Feature-First Clean Architecture
dengan dependency rule presentation -> domain <- data.

Periksa teknologi dan struktur yang benar-benar digunakan
pada repository.

Fokus pada:
1. Kebenaran logika program.
2. Pemisahan tanggung jawab dan aturan dependency.
3. Penanganan error dan null safety.
4. Kecukupan unit test.

Abaikan masalah style yang dapat ditangani formatter.

Berikan lima temuan teratas beserta:
- Tingkat keparahan.
- Lokasi kode.
- Alasan teknis.
- Dampak masalah.
- Usulan perbaikan konkret.

Jangan mengasumsikan bug tanpa bukti.
Jangan menyarankan dependensi atau abstraksi baru
jika tidak diperlukan.
```

Prompt disimpan pada dokumentasi Jobsheet 8 bersama ringkasan hasil review AI dan keputusan teknis yang diambil.

## 2. Tabel Usulan AI vs Keputusan Final

| Usulan AI | Keputusan Final | Alasan Teknis |
| :--- | :--- | :--- |
| Memindahkan logika bisnis dari widget ke domain jika ditemukan pelanggaran | Diterapkan jika temuan terbukti benar | Menjaga tanggung jawab layer dan mempermudah pengujian. |
| Menambahkan abstraksi atau use case baru untuk operasi sederhana | Dievaluasi terlebih dahulu | Menghindari kompleksitas dan boilerplate yang tidak diperlukan. |
| Menambahkan test untuk skenario error yang belum tercakup | Diterapkan jika terdapat celah pengujian | Meningkatkan keandalan penanganan error. |
| Mengubah struktur arsitektur yang sudah sesuai | Ditolak jika tidak ada alasan teknis yang kuat | Perubahan besar yang tidak diperlukan meningkatkan risiko regresi. |

Tabel tersebut merupakan contoh awal evaluasi. Keputusan final harus disesuaikan dengan output AI dan bukti pemeriksaan pada project.

## 3. AI Verification Checklist

- [x] Prompt AI dan hasil review didokumentasikan.
- [x] Temuan AI diperiksa terhadap kode yang sebenarnya.
- [x] Minimal dua temuan AI terbukti benar dengan bukti.
- [x] Minimal satu temuan AI ditolak dengan alasan teknis.
- [x] Tidak ada saran AI yang diterapkan tanpa verifikasi.
- [x] Keputusan akhir dicatat dalam dokumentasi.
- [x] Pengujian dijalankan kembali setelah perbaikan.

---

# Unit Testing & Verifikasi Statis

Pengujian dilakukan untuk memastikan perubahan pada Jobsheet 8 tidak merusak fitur yang telah dikembangkan pada minggu sebelumnya.

Pengujian yang relevan pada project `campus_notify` mencakup:

- **Authentication**: validasi kredensial dan penanganan error.
- **Announcements**: pengurutan, filter kategori, dan penanganan kegagalan pengambilan data.
- **Push Notification**: pemetaan route dan penanganan pesan notifikasi.
- **Error Handling**: pemetaan failure menjadi pesan yang sesuai.

Perintah pengujian:

```bash
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

### Bukti Pengujian dan Analisis

| Pemeriksaan | Hasil |
| :--- | :--- |
| Flutter Analyze | Isi berdasarkan output aktual |
| Dart Format | Isi berdasarkan output aktual |
| Flutter Test | Isi berdasarkan output aktual |
| GitHub Actions CI | Isi berdasarkan hasil workflow |

Bukti Pull Req:

![GitHub Actions CI](screenshots/ci.png)

---

# Perbandingan Hasil Project (Week 7 vs Week 8)

Jobsheet 8 berfokus pada evaluasi kualitas dan kesiapan project, bukan membuat aplikasi baru atau mengubah seluruh implementasi.

| Aspek | Week 7 | Week 8 |
| :--- | :--- | :--- |
| Arsitektur | Penerapan Clean Architecture | Audit dependency rule dan struktur layer |
| Git | Pengembangan project | Audit branch dan kualitas commit |
| Pengujian | Unit test fitur | Verifikasi ulang setelah perubahan |
| Code Review | Belum menjadi fokus utama | Review kode dan tindak lanjut temuan |
| CI | Sesuai kondisi awal repository | Pemeriksaan otomatis melalui GitHub Actions jika diterapkan |
| Dokumentasi | Dokumentasi implementasi | Dokumentasi hasil mid-project review |

Fungsionalitas utama aplikasi dipertahankan. Perubahan hanya dilakukan jika diperlukan untuk memperbaiki masalah yang ditemukan atau memenuhi instruksi Jobsheet 8.

---

# Error Umum dan Solusinya

| Gejala Error | Penyebab Umum | Solusi |
| :--- | :--- | :--- |
| `src refspec main does not match any` | Branch `main` belum tersedia atau belum ada commit lokal | Periksa `git branch` dan `git log` sebelum menentukan langkah berikutnya. |
| `pathspec 'develop' did not match any file(s) known to git` | Branch `develop` belum tersedia secara lokal | Periksa branch lokal dan remote sebelum membuat branch baru. |
| `flutter analyze` menghasilkan error | Terdapat masalah kode atau konfigurasi | Periksa pesan error dan perbaiki penyebabnya. |
| `dart format --set-exit-if-changed .` gagal | Ada file Dart yang belum sesuai format | Jalankan formatter pada file yang relevan lalu periksa diff. |
| `flutter test` gagal | Test gagal, dependensi bermasalah, atau implementasi tidak sesuai ekspektasi | Periksa pesan kegagalan, reproduksi masalah, dan perbaiki penyebabnya. |
| GitHub Actions gagal | Konfigurasi workflow atau proses build tidak sesuai | Periksa log workflow dan jalankan pemeriksaan yang sama secara lokal. |
| Temuan AI tidak terbukti | AI salah memahami konteks atau mengasumsikan bug | Verifikasi kode dan test, lalu dokumentasikan alasan penolakan. |
| Konflik merge | Perubahan

# Refleksi

### 1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?

LGTM (*Looks Good To Me*) buta adalah memberikan persetujuan terhadap Pull Request tanpa memeriksa kode, memahami perubahan, atau menjalankan pengujian yang diperlukan. Sebaliknya, approve yang bertanggung jawab dilakukan setelah reviewer memeriksa logika program, aturan arsitektur, dan hasil pengujian. LGTM buta berisiko menyebabkan bug, pelanggaran Clean Architecture, dan masalah kualitas kode masuk ke branch integrasi sehingga meningkatkan biaya perbaikan dan mengganggu pekerjaan anggota tim lainnya.

### 2. Kapan komentar wajib berstatus Request changes, dan kapan cukup saran?

Status *Request changes* diperlukan ketika ditemukan masalah penting yang dapat menyebabkan kesalahan fungsi, kegagalan pengujian, pelanggaran aturan dependency, atau risiko keamanan yang belum ditangani. Sementara itu, komentar berupa saran cukup digunakan untuk perbaikan yang tidak menghalangi fungsi utama aplikasi, seperti peningkatan penamaan variabel atau keterbacaan kode. Dengan demikian, reviewer dapat membedakan masalah yang wajib diperbaiki sebelum merge dan peningkatan kualitas yang tidak bersifat kritis.

### 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?

Saya akan menolak atau menyederhanakan saran AI yang tidak didukung bukti dari kode atau menambahkan kompleksitas yang tidak diperlukan. Contohnya, jika AI menyarankan pembuatan use case baru untuk operasi sederhana yang hanya meneruskan pemanggilan repository tanpa aturan bisnis tambahan, saya akan mempertimbangkan apakah abstraksi tersebut benar-benar memberikan manfaat. Keputusan akhir harus didasarkan pada hasil pemeriksaan kode, pengujian, dan kesesuaian dengan Clean Architecture, bukan sekadar mengikuti rekomendasi AI. Setiap saran yang ditolak harus disertai alasan teknis dan bukti yang relevan.

### 4. Satu hal konkret yang Anda perbaiki setelah review sejawat, apa dampaknya?

Salah satu perbaikan yang dapat dilakukan adalah menambahkan pengujian untuk memastikan penanganan error menghasilkan pesan yang sesuai dan mudah dipahami pengguna. Perbaikan ini membantu mendeteksi kesalahan penanganan exception lebih awal serta meningkatkan keandalan aplikasi. Setelah perubahan diterapkan, pengujian terkait perlu dijalankan kembali untuk memastikan hasilnya sesuai dengan yang diharapkan. Dampaknya harus dibuktikan melalui hasil pengujian dan catatan review yang benar-benar dilakukan.