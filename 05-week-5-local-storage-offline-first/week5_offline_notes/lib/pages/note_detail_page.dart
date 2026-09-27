import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/note_providers.dart';
import '../widgets/note_colors.dart';

/// Provider terpisah yang fetch 1 note langsung dari repository by id,
/// tidak bergantung pada state notesProvider (list) yang mungkin belum ter-load.
final noteByIdProvider =
    FutureProvider.family<Note?, int>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  final notes = await repo.fetchNotes();
  try {
    return notes.firstWhere((n) => n.id == id);
  } catch (_) {
    return null;
  }
});

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(noteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat: $err')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan.'));
          }
          return Container(
            width: double.infinity,
            color: kNoteColors[note.colorIndex % kNoteColors.length],
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? '(Tanpa judul)' : note.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (note.dirty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Belum sync',
                          style: TextStyle(
                              color: Colors.black, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Diperbarui: ${note.updatedAt}',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                const Divider(color: Colors.white24, height: 32),
                Text(
                  note.body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(notesProvider.notifier)
                          .deleteNote(note.id!);
                      ref.invalidate(noteByIdProvider(noteId));
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Catatan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}