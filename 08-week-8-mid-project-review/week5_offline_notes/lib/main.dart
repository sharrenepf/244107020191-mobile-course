import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/notes_page.dart';
import 'pages/posts_page.dart';
import 'pages/note_detail_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeTabs(),
      routes: [
        GoRoute(
          path: 'note/:id',
          builder: (context, state) => NoteDetailPage(
            noteId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Catat waktu buka aplikasi (bagian dari tugas: waktu terakhir dibuka).
    Future.microtask(() {
      ref.read(prefsRepositoryProvider).markOpenedNow();
    });
  }

  static const _lightScheme = ColorScheme.light();

  @override
  Widget build(BuildContext context) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final isDark = darkModeAsync.value ?? true; // default dark saat masih loading

    return MaterialApp.router(
      title: 'Offline Notes',
      routerConfig: _router,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme.copyWith(primary: Colors.teal),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF161616),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF232323),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          indicatorColor: Colors.tealAccent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;
  final _pages = const [NotesPage(), PostsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_outlined), label: 'Catatan'),
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Posts'),
        ],
      ),
    );
  }
}