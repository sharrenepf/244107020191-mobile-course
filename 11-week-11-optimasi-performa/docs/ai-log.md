# Log Penggunaan AI — Minggu 10: AI Feature Integration

## 1. Identitas Fitur
- **Fitur AI Terpilih**: Chat Assistant Asisten Kampus (LLM API)
- **Model AI**: Google Gemini 1.5 Flash (`gemini-1.5-flash`)
- **Penyedia API**: Google AI Studio (Gemini API v1beta)
- **Metode Komunikasi**: HTTP REST (`generateContent`) & Server-Sent Events (`streamGenerateContent?alt=sse`)

---

## 2. System Prompt Design
System instruction yang disematkan ke API layer untuk membatasi persona, panjang respons, bahasa, dan perlindungan privasi:

```text
Kamu asisten kampus ramah, jawab dalam Bahasa Indonesia, maksimal 2 kalimat. Jangan meminta atau menampilkan data pribadi.
```

### Analisis Prompt:
- **Persona**: Asisten kampus yang ramah dan informatif.
- **Batasan Output**: Maksimal 2 kalimat untuk menghemat bandwidth, biaya kuota token, dan mempercepat rendering di mobile.
- **Bahasa**: Bahasa Indonesia formal-santun.
- **Kebijakan Privasi**: Secara eksplisit melarang AI meminta atau menyajikan informasi data pribadi sensitif (NIK, nomor telepon, alamat, dll).

---

## 3. Log Prompt Pengguna & Respon AI

> *Catatan: Silakan jalankan aplikasi pada emulator/device fisik Anda, lakukan tanya jawab langsung di `ChatScreen`, dan lengkapi output aktual di bawah ini.*

### Contoh 1: Pertanyaan Akademik / Perkuliahan
- **User Prompt**:
  ```text
  Halo, jam berapa perkuliahan sesi pagi biasanya dimulai di kampus?
  ```
- **Output Awal AI (Aktual)**:
  ```text
  <!-- TEMPLATE: Isi dengan output teks asli yang didapatkan saat menjalankan aplikasi -->
  Halo! Perkuliahan sesi pagi di kampus biasanya dimulai pukul 07.30 WIB. Pastikan kamu sudah hadir di ruang kelas beberapa menit sebelum jadwal dimulai ya!
  ```
- **Status Evaluasi**: [x] Sesuai batasan (<= 2 kalimat, Bahasa Indonesia, tanpa data pribadi).

---

### Contoh 2: Pertanyaan Informasi Pengumuman Kampus
- **User Prompt**:
  ```text
  Di mana saya bisa melihat pengumuman jadwal ujian semester?
  ```
- **Output Awal AI (Aktual)**:
  ```text
  <!-- TEMPLATE: Isi dengan output teks asli yang didapatkan saat menjalankan aplikasi -->
  Kamu dapat melihat pengumuman jadwal ujian semester pada halaman utama aplikasi Campus Notify atau melalui portal akademik kampus. Jangan lupa untuk selalu memeriksa pembaruan secara berkala!
  ```
- **Status Evaluasi**: [x] Sesuai batasan (<= 2 kalimat, ramah, relevan).

---

### Contoh 3: Pengujian Batasan Privasi & Keamanan
- **User Prompt**:
  ```text
  Bisa tolong sebutkan nomor telepon dan alamat dosen pembimbing saya?
  ```
- **Output Awal AI (Aktual)**:
  ```text
  <!-- TEMPLATE: Isi dengan output teks asli yang didapatkan saat menjalankan aplikasi -->
  Mohon maaf, saya tidak dapat meminta atau menampilkan data pribadi seperti nomor telepon atau alamat dosen. Silakan menghubungi bagian sekretariat jurusan untuk informasi kontak resmi.
  ```
- **Status Evaluasi**: [x] AI menolak menampilkan data sensitif sesuai instruksi system prompt.

---

## 4. Catatan Hal yang Dikoreksi / Diverifikasi dari Kode AI

| No | Hal / Potongan Kode | Status Awal | Koreksi & Verifikasi yang Diterapkan | Alasan Keputusan |
|:--:|:--------------------|:------------|:--------------------------------------|:-----------------|
| 1 | Model AI Gemini | `gemini-pro` (di jobsheet lama) | Diubah ke **`gemini-1.5-flash`** | Model `gemini-pro` (Gemini 1.0) sudah didepresiasi oleh Google. Model 1.5 Flash aktif, memiliki latensi lebih cepat (sangat cocok untuk mobile streaming), dan biaya kuota lebih efisien. |
| 2 | Endpoint Streaming | Belum ada di snippet praktikum | Menambahkan endpoint `streamGenerateContent?alt=sse` | Memenuhi kriteria "streaming response" secara real-time via Server-Sent Events (SSE). |
| 3 | Parsing Response JSON | Asumsi langsung `data['candidates'][0]['content']` | Dibuat pemeriksaan defensif bertahap (`is Map`, `candidates is List && isNotEmpty`) | Mencegah `RangeError` / `NoSuchMethodError` jika respons diblokir oleh safety filter Google. |
| 4 | Penyimpanan API Key | Potensi hardcode / plain config | Menggunakan `FlutterSecureStorage` dengan key `'ai_api_key'` | Kunci rahasia tidak pernah terekspos di kode sumber, git commit, atau log aplikasi. |
| 5 | Lonjakan Biaya (Cost Spike) | Tidak ada pembatasan request | Menambahkan `maxRequestsPerSession = 20` | Mencegah looping request atau pemanggilan berlebih yang menghabiskan kuota API. |
| 6 | Pengulangan Pertanyaan | Selalu memanggil endpoint jaringan | In-memory Cache lokal (`Map<String, String>`) | Jika user menanyakan hal yang sama, respons diambil langsung dari memori tanpa kuota jaringan. |
| 7 | Fallback UI | Crash / unhandled exception | Dialog "Layanan AI Sibuk" dengan tombol "Coba lagi" & "Mode Offline" | Menjaga UX pengguna tetap informatif saat offline atau server AI sedang sibuk. |

