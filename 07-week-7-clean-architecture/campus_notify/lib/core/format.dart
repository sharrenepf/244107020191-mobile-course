const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 2026-10-02 -> "2 Okt 2026"
String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Payload data FCM -> rute tujuan.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route']?.toString().trim();
  if (raw == null || raw.isEmpty) return '/';
  return raw.startsWith('/') ? raw : '/$raw';
}

/// Buang prefix "Exception: " agar UI hanya menerima pesan ramah.
String errorMessage(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
