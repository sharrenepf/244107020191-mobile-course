import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Layanan AI untuk berkomunikasi dengan Google Gemini API.
/// Dilengkapi sistem rate limiting, in-memory cache, dan penanganan timeout/offline.
class AiService {
  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;

  // Key penyimpanan aman untuk API key
  static const String apiKeyStorageKey = 'ai_api_key';

  // System prompt pembatas persona & privasi sesuai jobsheet
  static const String systemInstruction =
      'Kamu asisten kampus ramah, jawab dalam Bahasa Indonesia, maksimal 2 kalimat. '
      'Jangan meminta atau menampilkan data pribadi.';

  // Model aktif pengganti gemini-pro (gemini-pro sudah deprecated)
  static const String _model = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Batas request per sesi untuk mitigasi lonjakan biaya
  static const int maxRequestsPerSession = 20;
  int _sessionRequestCount = 0;

  // In-memory cache lokal sederhana untuk pertanyaan yang sama (menghemat kuota & biaya)
  final Map<String, String> _cache = {};

  int get sessionRequestCount => _sessionRequestCount;
  int get cachedItemCount => _cache.length;

  /// Mereset counter kuota dan membersihkan cache sesi.
  void resetSession() {
    _sessionRequestCount = 0;
    _cache.clear();
  }

  /// Membaca API key yang tersimpan di secure storage.
  Future<String?> getApiKey() async {
    return await _storage.read(key: apiKeyStorageKey);
  }

  /// Menyimpan API key ke secure storage agar tidak hardcode di kode.
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: apiKeyStorageKey, value: key.trim());
  }

  /// Menghapus API key dari secure storage bila diperlukan.
  Future<void> clearApiKey() async {
    await _storage.delete(key: apiKeyStorageKey);
  }

  /// Memvalidasi ketersediaan API key sebelum memanggil API.
  Future<String> _requireApiKey() async {
    final key = await getApiKey();
    if (key == null || key.trim().isEmpty) {
      throw Exception(
        'API key belum diatur. Silakan masukkan API key Gemini Anda terlebih dahulu.',
      );
    }
    return key.trim();
  }

  /// Membuat body request standar dengan system instruction dan prompt user.
  Map<String, dynamic> _buildRequestBody(String question) {
    return {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': [
        {
          'parts': [
            {'text': question}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 200,
      }
    };
  }

  /// Mengambil jawaban utuh (non-streaming) dengan dukungan cache & rate limit.
  Future<String> ask(String question) async {
    final cacheKey = question.trim().toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (_sessionRequestCount >= maxRequestsPerSession) {
      throw Exception(
        'Batas request per sesi ($maxRequestsPerSession) telah tercapai. '
        'Gunakan mode offline atau mulai sesi baru.',
      );
    }

    final apiKey = await _requireApiKey();
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

    try {
      _sessionRequestCount++;
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_buildRequestBody(question)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = _extractTextFromResponse(data);
        if (answer.isNotEmpty) {
          _cache[cacheKey] = answer;
        }
        return answer;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } on TimeoutException {
      throw Exception(
        'Koneksi ke AI API waktu habis (timeout). Silakan periksa koneksi internet Anda.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke layanan AI: ${e.message}');
    }
  }

  /// Mengambil jawaban secara bertahap (streaming response) dengan cache & rate limit.
  Stream<String> askStream(String question) async* {
    final cacheKey = question.trim().toLowerCase();

    // 1. Cek cache lokal: jika ada, tidak perlu memanggil API (hemat kuota)
    if (_cache.containsKey(cacheKey)) {
      yield _cache[cacheKey]!;
      return;
    }

    // 2. Cek rate limiting per sesi
    if (_sessionRequestCount >= maxRequestsPerSession) {
      throw Exception(
        'Batas kuota sesi ($maxRequestsPerSession pertanyaan) telah tercapai. '
        'Gunakan mode offline atau reset sesi.',
      );
    }

    final apiKey = await _requireApiKey();
    final url =
        Uri.parse('$_baseUrl/$_model:streamGenerateContent?alt=sse&key=$apiKey');

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(_buildRequestBody(question));

    http.StreamedResponse streamedResponse;
    try {
      _sessionRequestCount++;
      streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Koneksi streaming ke AI API waktu habis (timeout).');
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke layanan AI: ${e.message}');
    }

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw _handleHttpError(streamedResponse.statusCode, errorBody);
    }

    // Parse Server-Sent Events (SSE) baris demi baris
    final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final textAccumulator = StringBuffer();

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data: ')) continue;

      final jsonString = trimmed.substring(6).trim();
      if (jsonString.isEmpty || jsonString == '[DONE]') continue;

      try {
        final data = jsonDecode(jsonString);
        final chunkText = _extractTextFromResponse(data);
        if (chunkText.isNotEmpty) {
          textAccumulator.write(chunkText);
          yield chunkText;
        }
      } catch (_) {
        // Abaikan parse error pada baris data parsial
      }
    }

    // Simpan respons utuh ke cache lokal
    if (textAccumulator.isNotEmpty) {
      _cache[cacheKey] = textAccumulator.toString();
    }
  }

  /// Ekstraksi teks dari response JSON Gemini secara defensif.
  String _extractTextFromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return '';
    }
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return '';
    }
    final firstCandidate = candidates[0];
    if (firstCandidate is! Map<String, dynamic>) {
      return '';
    }
    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return '';
    }
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic> && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    return buffer.toString();
  }

  /// Memetakan status code HTTP ke pesan ramah pengguna.
  Exception _handleHttpError(int statusCode, String responseBody) {
    if (statusCode == 400) {
      return Exception('Permintaan tidak valid atau format API key salah.');
    } else if (statusCode == 403 || statusCode == 401) {
      return Exception('API key tidak valid atau tidak memiliki izin akses.');
    } else if (statusCode == 429) {
      return Exception('Batas kuota panggilan AI telah tercapai. Coba lagi nanti.');
    } else if (statusCode >= 500) {
      return Exception('Server AI sedang mengalami gangguan. Silakan coba lagi nanti.');
    }
    return Exception('Gagal memanggil AI API (Status $statusCode).');
  }
}
