import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_service.dart';

/// Model pesan chat (pengguna atau asisten AI).
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

/// State percakapan AI: daftar pesan, status loading, dan pesan error.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider instance AiService (singleton lewat Riverpod).
final aiServiceProvider = Provider<AiService>((ref) => AiService());

/// Provider untuk mengelola state chat dan streaming response dari AI.
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  String? _lastQuestion;

  @override
  ChatState build() => const ChatState();

  /// Mengirim pertanyaan ke AI dan memperbarui pesan secara bertahap via stream.
  Future<void> sendMessage(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    _lastQuestion = trimmed;

    // Tambahkan pesan user dan placeholder untuk AI
    final userMessage = ChatMessage(text: trimmed, isUser: true);
    final aiPlaceholder = ChatMessage(text: '', isUser: false);

    state = state.copyWith(
      messages: [...state.messages, userMessage, aiPlaceholder],
      isLoading: true,
      clearError: true,
    );

    final aiService = ref.read(aiServiceProvider);

    try {
      final stream = aiService.askStream(trimmed);
      final textBuffer = StringBuffer();

      await for (final chunk in stream) {
        textBuffer.write(chunk);
        final current = List<ChatMessage>.from(state.messages);
        if (current.isNotEmpty) {
          current[current.length - 1] = ChatMessage(
            text: textBuffer.toString(),
            isUser: false,
          );
          state = state.copyWith(messages: current);
        }
      }

      // Bila respons selesai tapi buffer kosong
      if (textBuffer.isEmpty) {
        final current = List<ChatMessage>.from(state.messages);
        if (current.isNotEmpty) {
          current[current.length - 1] = ChatMessage(
            text: 'Tidak ada respons dari AI. Coba ajukan pertanyaan lain.',
            isUser: false,
          );
          state = state.copyWith(messages: current);
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Hapus bubble placeholder kosong jika gagal sebelum menerima chunk pertama
      final current = List<ChatMessage>.from(state.messages);
      if (current.isNotEmpty && current.last.text.isEmpty && !current.last.isUser) {
        current.removeLast();
      }

      final errorText = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        messages: current,
        isLoading: false,
        errorMessage: errorText,
      );
    }
  }

  /// Mencoba ulang pertanyaan terakhir yang gagal dikirim.
  void retryLastQuestion() {
    clearError();
    if (_lastQuestion != null && _lastQuestion!.isNotEmpty) {
      sendMessage(_lastQuestion!);
    }
  }

  /// Fallback mode offline: menampilkan pesan bantuan statis dari sistem kampus.
  void useOfflineFallback() {
    clearError();
    final fallbackMsg = ChatMessage(
      text: '[Mode Offline] Layanan AI saat ini tidak tersedia.\n'
          'Informasi Kampus: Jam layanan Senin-Jumat 07.30 - 16.00 WIB. '
          'Untuk pertanyaan administrasi & perkuliahan, silakan hubungi bagian akademik atau baca pengumuman resmi.',
      isUser: false,
    );
    state = state.copyWith(
      messages: [...state.messages, fallbackMsg],
      isLoading: false,
    );
  }

  /// Menghapus pesan error setelah ditampilkan di UI/dialog.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Membersihkan riwayat percakapan.
  void resetChat() {
    _lastQuestion = null;
    ref.read(aiServiceProvider).resetSession();
    state = const ChatState();
  }
}
