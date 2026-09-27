import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/note_providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() =>
      Future.value(items.where((n) => n.dirty).length);
}

void main() {
  // ================== UNIT TEST MODEL ==================
  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.colorIndex, 0); // default color kalau field tidak ada
  });

  test('flag dirty dan colorIndex bertahan pada serialisasi', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
      colorIndex: 3,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
    expect(restored.colorIndex, 3);
  });

  test('copyWith hanya mengubah field yang diberikan', () {
    final original = Note(
      title: 'Judul Asli',
      body: 'Isi asli',
      updatedAt: DateTime(2026, 1, 1),
      colorIndex: 1,
    );
    final updated = original.copyWith(title: 'Judul Baru');

    expect(updated.title, 'Judul Baru');
    expect(updated.body, 'Isi asli'); // tidak berubah
    expect(updated.colorIndex, 1); // tidak berubah
  });

  // ================== TEST PROVIDER DENGAN REPOSITORY PALSU ==================
  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: [
            Note(title: 'Tes', updatedAt: DateTime.now(), colorIndex: 2),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
    expect(notes.first.colorIndex, 2);
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
  });

  test('dirtyCountProvider menghitung catatan dirty dengan benar', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: [
            Note(title: 'A', updatedAt: DateTime.now(), dirty: true),
            Note(title: 'B', updatedAt: DateTime.now(), dirty: false),
            Note(title: 'C', updatedAt: DateTime.now(), dirty: true),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final count = await container.read(dirtyCountProvider.future);
    expect(count, 2);
  });
}