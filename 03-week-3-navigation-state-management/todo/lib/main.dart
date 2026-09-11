import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/stat_page.dart';
import 'pages/todo_page.dart';

void main() {
  // ProviderScope membungkus root aplikasi sehingga
  // seluruh halaman dapat menggunakan Riverpod.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Konfigurasi GoRouter.
final GoRouter router = GoRouter(
  initialLocation: '/',

  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigation(
          navigationShell: navigationShell,
        );
      },

      branches: [
        // Branch pertama untuk halaman Todo.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return const TodoPage();
              },
            ),
          ],
        ),

        // Branch kedua untuk halaman Statistik.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) {
                return const StatsPage();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

// Widget utama yang menyediakan NavigationBar.
class MainNavigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigation({
    super.key,
    required this.navigationShell,
  });

  // Berpindah ke branch yang dipilih.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,

      // Jika tab yang sama ditekan kembali,
      // halaman akan kembali ke halaman awal branch tersebut.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai route yang sedang aktif.
      body: navigationShell,

      // NavigationBar digunakan untuk berpindah antara
      // halaman Todo dan Statistik.
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist),
            selectedIcon: Icon(Icons.checklist),
            label: 'ToDo',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}

// Root aplikasi.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - ToDo',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),

      // GoRouter digunakan oleh MaterialApp.
      routerConfig: router,
    );
  }
}