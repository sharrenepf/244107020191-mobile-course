import 'package:flutter/material.dart';
import '../messaging/push_service.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  Widget _tile(IconData icon, String label, ValueNotifier<String> n) {
    return ValueListenableBuilder<String>(
      valueListenable: n,
      builder: (_, v, _) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontSize: 13)),
          subtitle: Text(v, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug FCM')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(Icons.notifications, 'Permission notifikasi', permissionStatus),
          ValueListenableBuilder<String?>(
            valueListenable: fcmToken,
            builder: (_, t, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('FCM token (dipotong)',
                    style: TextStyle(fontSize: 13)),
                subtitle: Text(t == null ? '-' : shortToken(t),
                    style: const TextStyle(
                        fontSize: 16, fontFamily: 'monospace')),
              ),
            ),
          ),
          _tile(Icons.cloud_upload, 'Sinkronisasi backend', syncStatus),
          _tile(Icons.tag, 'Topik', topicStatus),
          _tile(Icons.mark_email_unread, 'Notifikasi terakhir', lastNotif),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton(
                  onPressed: subscribeTopic, child: const Text('Subscribe')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                  onPressed: unsubscribeTopic,
                  child: const Text('Unsubscribe')),
            ),
          ]),
        ],
      ),
    );
  }
}