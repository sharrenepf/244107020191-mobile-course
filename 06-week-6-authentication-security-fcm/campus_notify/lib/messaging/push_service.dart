import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/api_errors.dart';
import 'route_parser.dart';

final _local = FlutterLocalNotificationsPlugin();

final fcmToken = ValueNotifier<String?>(null);
final permissionStatus = ValueNotifier<String>('Belum diminta');
final syncStatus = ValueNotifier<String>('Belum ada sinkronisasi');
final topicStatus = ValueNotifier<String>('Belum berlangganan');
final lastNotif = ValueNotifier<String>('Belum ada notifikasi');

String shortToken(String t) => t.length <= 12 ? t : '${t.substring(0, 12)}...';

const kTopic = 'pengumuman-kampus';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[BG] pesan diterima, route=${message.data['route']}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

void Function(String route)? _navigate;

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      _navigate?.call(payload);
    },
  );

  const channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    importance: Importance.high,
  );
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    lastNotif.value = '${message.notification?.title ?? '-'}\nRute: $route';
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Pengumuman',
      message.notification?.body ?? '',
      const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final route = routeFromMessage(message.data);
    lastNotif.value = 'Dibuka dari banner\nRute: $route';
    go(route);
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    final route = routeFromMessage(initial.data);
    lastNotif.value = 'Dibuka dari terminated\nRute: $route';
    go(route);
  }
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
  await subscribeTopic();
}

Future<void> subscribeTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic(kTopic);
  topicStatus.value = 'Berlangganan: $kTopic';
}

Future<void> unsubscribeTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic(kTopic);
  topicStatus.value = 'Berhenti berlangganan: $kTopic';
}

Future<void> startPush(Dio dio, void Function(String route) go) async {
  try {
    _navigate = go;

    final granted = await requestNotificationPermission();
    permissionStatus.value = granted ? 'Diizinkan' : 'Ditolak';

    await initLocalNotifications();
    listenForeground(go);

    await initFcmToken(onToken: (token) async {
      fcmToken.value = token;
      try {
        await dio.post('/devices',
            data: {'fcm_token': token, 'platform': 'android'});
        syncStatus.value = 'Terkirim ke backend: ${shortToken(token)}';
      } catch (e) {
        syncStatus.value =
            'Gagal kirim (${friendlyError(e)}): ${shortToken(token)}';
      }
    });

    await handleTerminated(go);
  } catch (e) {
    debugPrint('[Push] error: $e');
  }
}