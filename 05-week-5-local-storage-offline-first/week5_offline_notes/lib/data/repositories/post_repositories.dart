import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio, {Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  /// Ambil data langsung dari API (butuh internet).
  Future<List<Post>> fetchFromNetwork() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  /// Baca cache lokal dari tabel cached_posts (selalu berhasil walau offline).
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(payload);
    }).toList();
  }

  /// Timpa seluruh cache dengan data terbaru dari network.
  Future<void> cachePosts(List<Post> posts) async {
    final db = await _openDb();
    final batch = db.batch();
    batch.delete('cached_posts');
    final now = DateTime.now().toIso8601String();
    for (final post in posts) {
      batch.insert('cached_posts', {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }
}