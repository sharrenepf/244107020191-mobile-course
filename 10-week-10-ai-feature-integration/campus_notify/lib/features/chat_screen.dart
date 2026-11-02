import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_provider.dart';

/// Halaman Chat Assistant AI Kampus dengan streaming response & fallback handling.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Menampilkan AlertDialog "Layanan AI Sibuk" sesuai spesifikasi jobsheet.
  void _showAiBusyDialog(BuildContext context, String errorMessage) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Layanan AI Sibuk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coba lagi nanti atau gunakan mode offline.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Penyebab: $errorMessage',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatProvider.notifier).clearError();
            },
            child: const Text('Tutup'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatProvider.notifier).useOfflineFallback();
            },
            child: const Text('Mode Offline'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(chatProvider.notifier).retryLastQuestion();
            },
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog konfigurasi API key ke FlutterSecureStorage.
  Future<void> _showApiKeyDialog(BuildContext context) async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pengaturan API Key Gemini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci disimpan secara aman di secure storage.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Statistik Sesi: ${aiService.sessionRequestCount} request • ${aiService.cachedItemCount} cache',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                await aiService.saveApiKey(newKey);
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key berhasil disimpan!')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final scheme = Theme.of(context).colorScheme;

    // Listener otomatis: scroll saat ada pesan baru, dan tampilkan dialog bila error
    ref.listen(chatProvider, (prev, next) {
      if (next.messages.isNotEmpty) {
        _scrollToBottom();
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        _showAiBusyDialog(context, next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanya AI Kampus'),
        actions: [
          IconButton(
            tooltip: 'Atur API Key',
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            tooltip: 'Hapus Percakapan & Sesi',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref.read(chatProvider.notifier).resetChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner privasi singkat sesuai jobsheet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Colors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privasi: Jangan kirim NIK, telepon, atau data sensitif.',
                    style: TextStyle(fontSize: 12, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          // Daftar bubble pesan
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 56,
                            color: scheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Halo! Saya asisten AI kampus.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tanyakan informasi seputar perkuliahan, jadwal, atau pengumuman.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isLastAndLoading = chatState.isLoading &&
                          index == chatState.messages.length - 1 &&
                          !msg.isUser &&
                          msg.text.isEmpty;

                      return _ChatBubble(
                        message: msg,
                        isLoading: isLastAndLoading,
                      );
                    },
                  ),
          ),
          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: chatState.isLoading ? null : _handleSend,
                    icon: chatState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget bubble chat untuk pengguna dan respons AI / Offline.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isLoading,
  });

  final ChatMessage message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final isOffline = message.text.startsWith('[Mode Offline]');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isOffline
                  ? Colors.amber.shade100
                  : scheme.primaryContainer,
              child: Icon(
                isOffline ? Icons.offline_bolt_outlined : Icons.auto_awesome,
                size: 16,
                color: isOffline ? Colors.amber.shade900 : scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? scheme.primary
                    : (isOffline
                        ? Colors.amber.shade50
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.6)),
                border: isOffline ? Border.all(color: Colors.amber.shade200) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sedang mengetik...',
                          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  : SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : (isOffline ? Colors.black87 : scheme.onSurface),
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
