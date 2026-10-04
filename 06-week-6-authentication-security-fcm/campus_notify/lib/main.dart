import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/debug_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';
import 'theme.dart';

final container = ProviderContainer();
final _refresh = ValueNotifier<int>(0);
bool _pushStarted = false;

final router = GoRouter(
  refreshListenable: _refresh,
  redirect: (context, state) {
    final loggedIn = container.read(authStateProvider).value ?? false;
    final goingLogin = state.matchedLocation == AppRoutes.login;
    if (!loggedIn && !goingLogin) return AppRoutes.login;
    if (loggedIn && goingLogin) return AppRoutes.home;
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
    GoRoute(path: AppRoutes.debug, builder: (_, _) => const DebugPage()),
    GoRoute(
      path: AppRoutes.announcement,
      builder: (_, s) => AnnouncementPage(id: s.pathParameters['id'] ?? ''),
    ),
  ],
);

/// Navigasi dari notifikasi (foreground/background/terminated).
void goTo(String route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.push(route);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerBackgroundHandler(); // wajib sebelum runApp

  container.listen(authStateProvider, (_, next) {
    _refresh.value++;
    if (next.value == true && !_pushStarted) {
      _pushStarted = true;
      startPush(container.read(dioProvider), goTo);
    }
  });

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}