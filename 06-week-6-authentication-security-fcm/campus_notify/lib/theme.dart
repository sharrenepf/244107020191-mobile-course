import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF0F766E),
    scaffoldBackgroundColor: const Color(0xFFF4F7F6),
  );
}

Color categoryColor(String category) {
  switch (category) {
    case 'Akademik':
      return const Color(0xFF2563EB);
    case 'Kegiatan':
      return const Color(0xFFEA580C);
    default:
      return const Color(0xFF0F766E);
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Akademik':
      return Icons.school;
    case 'Kegiatan':
      return Icons.event;
    default:
      return Icons.campaign;
  }
}