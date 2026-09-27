import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';
import '../data/note_providers.dart';
import '../data/sync.dart';
import '../widgets/note_card.dart';
import '../widgets/note_colors.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  void _openEditor(BuildContext context, WidgetRef ref, {Note? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    int selectedColor = existing?.colorIndex ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kNoteColors[selectedColor],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Judul',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: bodyController,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tulis catatan...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kNoteColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = index == selectedColor;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: kNoteColors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty &&
                              bodyController.text.trim().isEmpty) {
                            Navigator.pop(context);
                            return;
                          }
                          if (existing == null) {
                            ref.read(notesProvider.notifier).addNote(
                                  titleController.text.trim(),
                                  bodyController.text.trim(),
                                  colorIndex: selectedColor,
                                );
                          } else {
                            ref.read(notesProvider.notifier).updateNote(
                                  existing.copyWith(
                                    title: titleController.text.trim(),
                                    body: bodyController.text.trim(),
                                    colorIndex: selectedColor,
                                  ),
                                );
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final syncState = ref.watch(syncNotesProvider);

    ref.listen<AsyncValue<int?>>(syncNotesProvider, (prev, next) {
      next.whenData((count) {
        if (count != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count catatan berhasil disinkronkan.')),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: dirtyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (count) => Chip(
                  label: Text('Dirty: $count'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      count > 0 ? Colors.amber.shade800 : Colors.teal.shade800,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: syncState.isLoading
                ? null
                : () => ref.read(syncNotesProvider.notifier).runSync(),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Terjadi error: $err')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Text(
                'Belum ada catatan.\nTekan + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => context.push('/note/${note.id}'),
                onDelete: () =>
                    ref.read(notesProvider.notifier).deleteNote(note.id!),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}