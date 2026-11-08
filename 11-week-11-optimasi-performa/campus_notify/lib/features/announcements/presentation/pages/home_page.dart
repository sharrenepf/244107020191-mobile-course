import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../routes.dart';
import '../../../../theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';
import '../../domain/entities/announcement.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Tanya AI',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push(AppRoutes.chat),
          ),
          IconButton(
            tooltip: 'Debug FCM',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => context.push(AppRoutes.debug),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(searchedAnnouncementsProvider);
          await ref.read(searchedAnnouncementsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _GreetingBanner(),
                    const SizedBox(height: 16),
                    _SearchBar(controller: _searchController),
                    const SizedBox(height: 12),
                    const _CategoryFilterBar(),
                  ],
                ),
              ),
            ),
            const _AnnouncementSliverList(),
          ],
        ),
      ),
    );
  }
}

/// Banner ucapan selamat datang statis (dipisah agar tidak ikut rebuild saat search/filter).
class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, const Color(0xFF134E4A)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.waving_hand, color: Colors.white, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Mahasiswa!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ada pengumuman terbaru untuk kamu.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search bar dengan Riverpod select untuk mengisolasi rebuild tombol hapus.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hanya rebuild ketika status keberadaan query berubah (kosong vs tidak kosong).
    final hasQuery = ref.watch(
      searchQueryProvider.select((q) => q.isNotEmpty),
    );

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari judul pengumuman...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (v) =>
          ref.read(searchQueryProvider.notifier).update(v.trim()),
    );
  }
}

/// Baris filter kategori yang terisolasi dari komponen halaman lainnya.
class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();
  static const _categories = ['Semua', 'Akademik', 'Kegiatan', 'Umum'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Wrap(
      spacing: 8,
      children: [
        for (final c in _categories)
          ChoiceChip(
            label: Text(c),
            selected: selectedCategory == c,
            onSelected: (_) =>
                ref.read(selectedCategoryProvider.notifier).select(c),
          ),
      ],
    );
  }
}

/// Daftar pengumuman berbasis lazy-loading yang hanya me-rebuild dirinya sendiri.
class _AnnouncementSliverList extends ConsumerWidget {
  const _AnnouncementSliverList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(searchedAnnouncementsProvider);
    final query = ref.watch(searchQueryProvider);

    return announcementsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(searchedAnnouncementsProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          final emptyText = query.isNotEmpty
              ? 'Tidak ada pengumuman dengan judul\n"$query"'
              : 'Belum ada pengumuman.';
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _AnnouncementCard(item: items[index]),
          ),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item});
  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(item.category);
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.announcementPath(item.id)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon(item.category), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            item.category,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatDate(item.publishedAt),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
