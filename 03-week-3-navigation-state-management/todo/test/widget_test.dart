import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo/main.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    // Menjalankan aplikasi dengan ProviderScope
    // agar provider Riverpod dapat digunakan.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Kondisi awal harus menampilkan pesan
    // bahwa belum ada tugas.
    expect(
      find.text('Belum ada tugas'),
      findsOneWidget,
    );

    // Menekan tombol tambah.
    await tester.tap(
      find.byIcon(Icons.add),
    );

    await tester.pumpAndSettle();

    // Memasukkan nama tugas.
    await tester.enterText(
      find.byType(TextField),
      'Kerjakan PR minggu 3',
    );

    // Menekan tombol Tambah.
    await tester.tap(
      find.text('Tambah'),
    );

    await tester.pump();

    // Memastikan tugas berhasil ditampilkan.
    expect(
      find.text('Kerjakan PR minggu 3'),
      findsOneWidget,
    );
  });
}