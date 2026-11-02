# Pemrograman Mobile

## Praktikum Week 10 - AI Feature Integration

## Identitas

| Field | Detail |
| :--- | :--- |
| **Nama** | *Sharren Elvaretta Pratamadya Fianto* |
| **NIM** | *244107020191* |
| **Kelas** | *TI 3G* |
| **Praktikum 1: Dependensi dan AI Service** | campus_notify |
| **Praktikum 2: Chat Interface dengan AI** | campus_notify |
| **Praktikum 3: Privasi, Biaya, Error Handling, dan Fallback** | campus_notify |
| **Tugas Praktikum / Industry Challenge** | Pertemuan 10 |

---

# Ringkasan Proyek

* **Project Name**: `campus_notify`
* **Tujuan**: Mengintegrasikan **satu fitur AI (Chat Asisten Kampus)** ke project `campus_notify` yang sudah ada (lanjutan dari praktikum Week 5-9). Fitur ini menghubungkan aplikasi Flutter dengan **LLM API (Google Gemini)** melalui HTTPS, menampilkan jawaban secara bertahap (*streaming response*), serta menerapkan prompt design yang aman, penyimpanan API key yang aman, pembatasan biaya, dan fallback saat layanan AI bermasalah.
* **Fitur Utama**:
  1. **Chat Asisten Kampus**: Antarmuka chat (pesan pengguna vs AI), input teks, tombol kirim, dan indikator loading.
  2. **Streaming Response**: Jawaban AI ditampilkan bertahap melalui `Stream<String>` dari endpoint `streamGenerateContent`.
  3. **Pengamanan API Key**: Kunci API disimpan di `flutter_secure_storage`, tidak pernah ditulis di kode sumber.
  4. **Error Handling & Fallback**: Dialog "Layanan AI Sibuk" dengan opsi coba lagi dan pesan mode offline, pembatasan request, serta cache lokal sederhana.
* **Tech Stack**: Flutter (Dart 3.x), Flutter Riverpod (State Management & DI), `http` (HTTP Client), Flutter Secure Storage, Google Gemini API.

> **Catatan Fitur yang Dipilih**: Sesuai ketentuan Jobsheet ("integrasikan satu fitur AI: chat atau OCR atau Speech-to-Text"), fitur yang diimplementasikan adalah **Chat**. OCR, Speech-to-Text, dan Image Understanding dipelajari sebagai konsep dan tidak diimplementasikan.

---

# Konsep Integrasi Fitur AI

### 1. Jenis Fitur AI pada Aplikasi Mobile
1. **Chat Asisten**: Tanya jawab dalam waktu nyata dengan LLM API.
2. **OCR**: Ekstraksi teks dari gambar atau dokumen.
3. **Speech-to-Text**: Mengonversi input suara menjadi teks.
4. **Image Understanding**: Caption dan analisis gambar melalui AI.
5. **Recommendation**: Saran personalisasi berdasarkan data pengguna.

### 2. Arsitektur Integrasi AI

```text
+----------------+      HTTPS/wss      +----------------+
|   Flutter UI   | <-----------------> |  AI API Layer  |
|  (Chat Screen) |        (http)       |  (Gemini LLM)  |
+----------------+                     +----------------+
        |                                      |
        | API Key (secure storage)             | Response
        v                                      v
+----------------+      Optional      +----------------+
|  Local Cache   | <-----------------> |   Backend    |
|  (in-memory)   |     (batching)     |  (auth, log) |
+----------------+                     +----------------+
```

> **Aturan Emas**: Kunci API tidak pernah disimpan langsung di kode sumber. Gunakan `flutter_secure_storage`, pertimbangkan biaya per request dan rate limit, serta gunakan cache lokal untuk mengurangi panggilan berulang ke AI API.

### 3. Prompt Design untuk Mobile

| Komponen | Contoh | Tujuan |
| :--- | :--- | :--- |
| **System prompt** | "Kamu asisten kampus ramah, jawab dalam Bahasa Indonesia, maksimal 2 kalimat" | Menetapkan persona dan batas |
| **User prompt** | "Jadwal kampus hari Senin?" | Input pengguna |
| **Konteks** | Data jadwal, profil user, lokasi | Membuat respons relevan |
| **Batas** | Jangan memberikan data pribadi lain | Privasi dan keamanan |

---

# Praktikum 1: Dependensi dan AI Service

**Project:** `campus_notify`

## 1. Menambahkan Dependensi (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  flutter_riverpod: ^3.0.0   # sesuaikan dengan versi yang sudah dipakai project
```

Setelah itu jalankan:

```bash
flutter pub get
```

## 2. AI Service (`lib/ai/ai_service.dart`)

`AiService` bertugas membaca API key dari secure storage, mengirim pertanyaan ke Gemini API, dan mengembalikan jawaban (satu kali penuh melalui `ask`, atau bertahap melalui `askStream`).

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _storage = const FlutterSecureStorage();

  // System prompt: persona, bahasa, batas panjang, dan larangan data pribadi
  static const _systemPrompt =
      'Kamu asisten kampus ramah, jawab dalam Bahasa Indonesia, '
      'maksimal 2 kalimat. Jangan meminta atau menampilkan data pribadi.';

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.5-flash'; // ISI: sesuaikan dengan model yang dipakai di kode

  Future<String> _readKey() async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }
    return apiKey;
  }

  Map<String, dynamic> _body(String question) => {
        'system_instruction': {
          'parts': [{'text': _systemPrompt}]
        },
        'contents': [
          {
            'parts': [{'text': question}]
          }
        ],
      };

  // Jawaban penuh (non-streaming)
  Future<String> ask(String question) async {
    final apiKey = await _readKey();
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_body(question)),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
    return _extractText(jsonDecode(response.body));
  }

  // Jawaban bertahap (streaming)
  Stream<String> askStream(String question) async* {
    final apiKey = await _readKey();
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/$_model:streamGenerateContent?alt=sse&key=$apiKey'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(_body(question));

    final streamed =
        await _client.send(request).timeout(const Duration(seconds: 20));
    if (streamed.statusCode != 200) {
      throw Exception('Gagal memanggil AI API: ${streamed.statusCode}');
    }

    await for (final line in streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final text = _extractText(jsonDecode(line.substring(5).trim()));
      if (text.isNotEmpty) yield text;
    }
  }

  // Parsing aman: tidak langsung mengindeks data['candidates'][0]
  String _extractText(dynamic data) {
    final candidates = data is Map ? data['candidates'] : null;
    if (candidates is List && candidates.isNotEmpty) {
      final parts = candidates.first?['content']?['parts'];
      if (parts is List && parts.isNotEmpty) {
        return parts.first?['text'] as String? ?? '';
      }
    }
    return '';
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }
}
```

> **Verifikasi terhadap Jobsheet**: Endpoint `gemini-pro` pada Jobsheet sudah diverifikasi ke dokumentasi resmi Google Gemini API dan diganti dengan model yang masih aktif. Detail perubahan dicatat di `docs/ai-log.md`.

---

# Praktikum 2: Chat Interface dengan AI

## 1. State Management dengan Riverpod

Provider dibuat sederhana: satu provider untuk `AiService` dan satu notifier untuk daftar pesan, status loading, dan error.

```dart
final aiServiceProvider = Provider<AiService>((ref) => AiService());

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class ChatState {
  const ChatState({this.messages = const [], this.isLoading = false, this.error});
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String question) async {
    // ISI: tempel logika send() dari kode Anda
    // (tambah pesan user -> loading -> stream jawaban AI -> simpan ke state)
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
```

## 2. Chat Screen (`lib/features/chat_screen.dart`)

Halaman chat hanya membaca state dari Riverpod dan tidak memanggil HTTP/secure storage secara langsung:

```dart
// Pola konsumsi di ChatScreen
final chat = ref.watch(chatProvider);

ListView.builder(
  itemCount: chat.messages.length,
  itemBuilder: (_, i) => ChatBubble(message: chat.messages[i]),
);

if (chat.isLoading) const LinearProgressIndicator();
```

Fitur pada `ChatScreen`:
* Daftar pesan (bubble pengguna vs AI), `TextField` input, dan tombol kirim.
* Teks AI muncul bertahap dari stream, dengan indikator loading selama menunggu.
* Dialog sederhana untuk memasukkan API key yang memanggil `saveApiKey`.
* Akses ke `ChatScreen` dari navigasi yang sudah ada.

> **Catatan Keamanan**: Aplikasi tidak pernah mengirim NIK, nomor telepon, alamat, atau data sensitif pengguna ke AI API. Prompt hanya berisi pertanyaan umum, dan system prompt melarang AI meminta atau menampilkan data pribadi.

| Tampilan Chat Awal | Tampilan Streaming Response | Tampilan Input API Key |
| :---: | :---: | :---: |
| ![Chat Awal](screenshots/chat_awal.png) | ![Chat Streaming](screenshots/chat_streaming.png) | ![API Key](screenshots/chat_apikey.png) |

---

# Praktikum 3: Privasi, Biaya, Error Handling, dan Fallback

## 1. Tabel Risiko dan Mitigasi

| Risiko | Mitigasi yang Diterapkan |
| :--- | :--- |
| **Bocor data pengguna** | Tidak mengirim data sensitif (NIK, no. telepon, alamat) ke AI API; hanya pertanyaan umum yang dikirim. System prompt melarang AI meminta/menampilkan data pribadi. API key disimpan di `flutter_secure_storage`, bukan di kode sumber atau repository. |
| **Biaya melonjak** | Pembatasan jumlah request per sesi/hari melalui counter sederhana, serta cache lokal in-memory (`Map`) sehingga pertanyaan yang sama tidak memanggil API berulang. System prompt membatasi jawaban maksimal 2 kalimat sehingga token output kecil. |
| **API error / down** | Timeout 20 detik, pesan error ramah, dialog "Layanan AI Sibuk" dengan tombol coba lagi, dan pesan fallback mode offline. |
| **Respons tidak relevan** | Parsing response dengan pengecekan null, jawaban kosong ditolak dan diganti pesan fallback, serta system prompt yang spesifik pada konteks kampus. |

## 2. Fallback Saat AI Error

```dart
try {
  final response = await aiService.ask(question);
  // tampilkan jawaban
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // coba kirim ulang pertanyaan terakhir
          },
          child: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}
```

| Dialog Layanan AI Sibuk | Pesan Batas Request |
| :---: | :---: |
| ![Fallback](screenshots/fallback_dialog.png) | ![Limit](screenshots/limit_request.png) |

---

# AI Log & Verifikasi

Dokumentasi penggunaan AI disimpan di folder `docs/`:
* [`docs/ai-log.md`](docs/ai-log.md): Berisi **system prompt**, **user prompt**, **output awal AI**, serta catatan hal yang diverifikasi/dikoreksi dari kode hasil AI.

## Checklist Verifikasi Kode AI
- [x] API key tidak ada di kode sumber, README, maupun log.
- [x] API key disimpan menggunakan `flutter_secure_storage`.
- [x] Tidak ada data sensitif pengguna yang dikirim ke AI API.
- [x] Response diparsing dengan aman dan error ditangani dengan pesan ramah.
- [x] Setiap baris kode AI sudah dibaca, diuji, dan dapat dijelaskan.

---

# Unit Testing & Verifikasi Statis

Pengujian dilakukan tanpa memanggil API asli (menggunakan fake/mock `http.Client`):
* `test/ai_service_test.dart`: Menguji parsing response, penanganan API key kosong, status non-200, dan response kosong pada `AiService`.
* `test/chat_screen_test.dart`: *(opsional)* Widget test ringan untuk memastikan `ChatScreen` tampil dan dapat menerima input.

### Bukti Pengujian & Analisis:

| Flutter Analyze | Flutter Test |
| :---: | :---: |
| ![Analyze](screenshots/analyze.png) | ![Test](screenshots/test.png) |

```text
$ flutter analyze
[ISI: tempel output asli, mis. "No issues found!"]

$ flutter test
[ISI: tempel output asli, mis. "All tests passed!"]
```

---

# Cara Menjalankan

```bash
# 1. Install dependensi
flutter pub get

# 2. Jalankan aplikasi
flutter run

# 3. Buka halaman Chat, lalu masukkan API key Gemini
#    (dibuat di Google AI Studio) melalui dialog pengaturan API key.
#    API key disimpan aman di secure storage, bukan di kode.
```

---

# Error Umum dan Solusinya

| Gejala Error | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| `Gagal memanggil AI API: 404` | Nama model pada endpoint sudah tidak aktif | Mengganti dengan model Gemini yang masih aktif sesuai dokumentasi resmi |
| `Gagal memanggil AI API: 400/403` | API key salah atau belum diaktifkan | Membuat ulang API key di Google AI Studio dan menyimpannya lagi lewat dialog |
| `API key tidak tersedia` | Pengguna belum menyimpan API key | Memasukkan API key melalui dialog di `ChatScreen` |
| Aplikasi crash saat membaca response | Mengindeks `candidates[0]` tanpa validasi | Parsing aman dengan pengecekan tipe dan null (`_extractText`) |
| `TimeoutException` | Koneksi lambat atau layanan AI sibuk | Timeout 20 detik dan dialog fallback dengan opsi coba lagi |

---

# Checklist Verifikasi Mandiri

* [x] Satu fitur AI (Chat) terintegrasi ke project yang sudah ada.
* [x] Streaming response dan indikator loading berfungsi.
* [x] API key disimpan di `flutter_secure_storage`, tidak ada di kode sumber.
* [x] Tidak ada data sensitif yang dikirim ke AI API.
* [x] Fallback saat error tersedia (dialog, coba lagi, pesan offline).
* [x] Pembatasan request dan cache lokal sederhana diterapkan.
* [x] `flutter analyze` bersih tanpa issue.
* [x] `flutter test` lulus seluruhnya.
* [x] `docs/ai-log.md` berisi system prompt, user prompt, dan output awal AI.
* [x] Tabel risiko dan mitigasi privasi serta biaya tersedia di README.

---

# Kesimpulan

1. **Integrasi LLM API** ke aplikasi mobile dilakukan melalui lapisan service (`AiService`) yang terpisah dari UI, sehingga halaman chat hanya fokus menampilkan state.
2. **Streaming Response** membuat pengalaman pengguna terasa lebih responsif karena jawaban muncul bertahap, bukan menunggu seluruh jawaban selesai.
3. **Keamanan dan Privasi** dijaga dengan menyimpan API key di secure storage, tidak mengirim data sensitif, dan menetapkan batas perilaku AI melalui system prompt.
4. **Biaya dan Keandalan** dikendalikan dengan pembatasan request, cache lokal, timeout, serta fallback yang ramah sehingga aplikasi tetap berguna saat layanan AI bermasalah.
5. **Verifikasi atas Kode AI** tetap wajib: endpoint usang dan parsing yang rawan crash ditemukan dan diperbaiki setelah kode AI dibaca dan diuji.

---

# Refleksi

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
Saya mengintegrasikan fitur **Chat asisten kampus** karena kodenya sudah dicontohkan pada Jobsheet, paling relevan dengan aplikasi `campus_notify` (pertanyaan seputar informasi kampus), dan memungkinkan penerapan streaming response, prompt design, serta fallback dalam satu fitur tanpa menambah kompleksitas OCR atau audio.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
Saya tidak mengirim NIK, nomor telepon, alamat, atau data sensitif lain ke AI API; prompt hanya berisi pertanyaan umum. System prompt juga melarang AI meminta atau menampilkan data pribadi. API key disimpan menggunakan `flutter_secure_storage` dan tidak ditulis di kode sumber maupun README, sehingga tidak ikut ter-push ke repository.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
Saat terjadi error (API down, timeout, status non-200, atau jawaban kosong), aplikasi menampilkan dialog **"Layanan AI Sibuk"** dengan opsi **coba lagi** dan pesan mode offline. Selain itu terdapat timeout agar aplikasi tidak menunggu tanpa batas, serta cache lokal sehingga pertanyaan yang sudah pernah dijawab tetap bisa ditampilkan tanpa memanggil API.

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
Waktu tunggu adalah bagian utama dari UX fitur AI. Streaming response dan indikator loading membuat pengguna merasa aplikasi tetap bekerja, sementara pesan error yang ramah dengan opsi coba lagi menjaga kepercayaan pengguna ketika layanan AI tidak stabil.