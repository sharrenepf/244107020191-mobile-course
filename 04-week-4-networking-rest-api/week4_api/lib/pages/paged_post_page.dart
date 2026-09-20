import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/network_errors.dart';
import '../data/paged_posts.dart';
import '../widgets/post_tile.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    // Memuat halaman pertama ketika halaman pertama kali dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pagedPostsProvider.notifier).loadFirstPage();
    });

    // Memuat halaman berikutnya ketika user hampir sampai
    // di bagian bawah daftar.
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    // =========================
    // LOADING HALAMAN PERTAMA
    // =========================
    if (state.isLoading && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post Explorer'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // =========================
    // ERROR TANPA DATA
    // =========================
    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post Explorer'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  friendlyErrorMessage(state.error!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(pagedPostsProvider.notifier)
                        .loadFirstPage();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // =========================
    // EMPTY STATE
    // =========================
    if (!state.isLoading && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post Explorer'),
        ),
        body: const Center(
          child: Text('Belum ada post.'),
        ),
      );
    }

    // =========================
    // SUCCESS STATE
    // =========================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () {
              ref
                  .read(pagedPostsProvider.notifier)
                  .loadFirstPage();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(pagedPostsProvider.notifier)
              .loadFirstPage();
        },
        child: ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            // =========================
            // FOOTER PAGINATION
            // =========================
            if (index == state.items.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!state.hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Semua data sudah dimuat.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox(height: 20);
            }

            // =========================
            // POST ITEM
            // =========================
            final post = state.items[index];

            return PostTile(
              post: post,
              showBody: true,
              onTap: () {
                context.push('/post/${post.id}');
              },
            );
          },
        ),
      ),
    );
  }
}