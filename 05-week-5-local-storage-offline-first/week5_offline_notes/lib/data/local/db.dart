import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 3,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0,
          color_index INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      await _createIndexes(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createIndexes(db);
      }
      if (oldVersion < 3) {
        await db.execute(
          'ALTER TABLE notes ADD COLUMN color_index INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
  );
}

Future<void> _createIndexes(Database db) async {
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_notes_updated_at
    ON notes(updated_at DESC)
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_notes_dirty
    ON notes(dirty)
  ''');
}