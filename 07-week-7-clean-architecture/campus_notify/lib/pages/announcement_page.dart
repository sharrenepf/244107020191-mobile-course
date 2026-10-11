import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/announcements.dart';
import '../routes.dart';
import '../theme.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final item = findAnnouncement(id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman #$id'),
        // Jika dibuka dari notifikasi, tidak ada halaman sebelumnya.
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => context.go(AppRoutes.home),
              ),
      ),
      body: item == null
          ? const Center(child: Text('Pengumuman tidak ditemukan.'))
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: categoryColor(item.category),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        avatar: Icon(categoryIcon(item.category), size: 16),
                        label: Text(item.category),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(item.date,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    item.body,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ],
            ),
    );
  }
}