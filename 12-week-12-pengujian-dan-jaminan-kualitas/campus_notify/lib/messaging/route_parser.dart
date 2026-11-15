import '../routes.dart';

/// Payload data FCM -> rute tujuan.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route']?.toString().trim();
  if (raw == null || raw.isEmpty) return AppRoutes.home;
  return raw.startsWith('/') ? raw : '/$raw';
}