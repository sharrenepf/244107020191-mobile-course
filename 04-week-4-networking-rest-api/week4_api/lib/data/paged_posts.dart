import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  PagedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return PagedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  static const int _limit = 10;

  @override
  PagedPostsState build() {
    return const PagedPostsState();
  }

  Future<void> loadFirstPage() async {
    if (state.isLoading || state.isLoadingMore) {
      return;
    }

    state = state.copyWith(
      items: [],
      page: 0,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final repository = ref.read(postRepositoryProvider);

      final posts = await repository.fetchPostsPage(
        page: 1,
        limit: _limit,
      );

      state = state.copyWith(
        items: posts,
        page: 1,
        hasMore: posts.length == _limit,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      clearError: true,
    );

    try {
      final repository = ref.read(postRepositoryProvider);

      final nextPage = state.page + 1;

      final posts = await repository.fetchPostsPage(
        page: nextPage,
        limit: _limit,
      );

      final allItems = [
        ...state.items,
        ...posts,
      ];

      state = state.copyWith(
        items: allItems,
        page: nextPage,
        hasMore: posts.length == _limit,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error,
      );
    }
  }
}

final pagedPostsProvider =
    NotifierProvider<PagedPostsNotifier, PagedPostsState>(
  PagedPostsNotifier.new,
);