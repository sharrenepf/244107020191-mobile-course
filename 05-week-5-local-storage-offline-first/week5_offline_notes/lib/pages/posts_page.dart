import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts (Cache-first)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(postsProvider.notifier).manualRefresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Simulasi Offline (forceOffline)'),
            subtitle: const Text(
              'Aktifkan untuk uji cache tanpa mode pesawat sungguhan',
            ),
            value: forceOffline,
            onChanged: (value) =>
                ref.read(forceOfflineProvider.notifier).toggle(value),
          ),
          const Divider(height: 1),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada cache. Sambungkan internet lalu refresh.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      child: Text(posts[index].id.toString()),
                    ),
                    title: Text(
                      posts[index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      posts[index].body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
