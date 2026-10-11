/// Semua string rute ada di sini.
/// GoRouter dan deep link FCM memakai konstanta yang sama.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const debug = '/debug';
  static const announcement = '/pengumuman/:id';

  static String announcementPath(String id) => '/pengumuman/$id';
}