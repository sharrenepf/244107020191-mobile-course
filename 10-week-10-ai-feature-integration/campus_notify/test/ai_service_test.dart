import 'dart:convert';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService Unit Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Melempar Exception bila API key belum diatur', () async {
      final service = AiService();
      expect(
        () => service.ask('Halo'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API key belum diatur'),
        )),
      );
    });

    test('ask() berhasil mem-parse JSON response dari Gemini API', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'fake-key-123'});

      final mockResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Kuliah dimulai pukul 07.30 WIB.'}
              ]
            }
          }
        ]
      });

      final client = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'fake-key-123');
        return http.Response(mockResponse, 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = AiService(client: client);
      final answer = await service.ask('Jam berapa kuliah dimulai?');
      expect(answer, 'Kuliah dimulai pukul 07.30 WIB.');
    });

    test('askStream() mengalirkan potongan teks SSE secara bertahap', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'fake-key-123'});

      final sseBody = [
        'data: {"candidates":[{"content":{"parts":[{"text":"Kuliah "}]}}]}',
        '',
        'data: {"candidates":[{"content":{"parts":[{"text":"dimulai jam 08.00."}]}}]}',
        '',
        'data: [DONE]',
        '',
      ].join('\n');

      final client = MockClient.streaming((request, bodyStream) async {
        final stream = Stream.value(utf8.encode(sseBody));
        return http.StreamedResponse(stream, 200);
      });

      final service = AiService(client: client);
      final chunks = <String>[];
      await for (final chunk in service.askStream('Jadwal kuliah?')) {
        chunks.add(chunk);
      }

      expect(chunks, ['Kuliah ', 'dimulai jam 08.00.']);
    });

    test('Memetakan HTTP 429 ke pesan kuota habis', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'fake-key-123'});

      final client = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = AiService(client: client);
      expect(
        () => service.ask('Pertanyaan beruntun?'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Batas kuota'),
        )),
      );
    });

    test('In-memory cache mengembalikan jawaban tanpa memanggil API ulang', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'fake-key-123'});
      int callCount = 0;

      final mockResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Jawaban pertama.'}
              ]
            }
          }
        ]
      });

      final client = MockClient((request) async {
        callCount++;
        return http.Response(mockResponse, 200);
      });

      final service = AiService(client: client);
      final first = await service.ask('Info beasiswa?');
      final second = await service.ask('Info beasiswa?');

      expect(first, 'Jawaban pertama.');
      expect(second, 'Jawaban pertama.');
      expect(callCount, 1); // Hanya 1 request jaringan yang dilakukan!
      expect(service.cachedItemCount, 1);
    });

    test('Rate limiting per sesi melempar exception saat melampaui batas maks', () async {
      FlutterSecureStorage.setMockInitialValues({'ai_api_key': 'fake-key-123'});

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'ok'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service = AiService(client: client);
      // Panggil sampai batas maksimal (20 kali dengan pertanyaan berbeda)
      for (int i = 0; i < AiService.maxRequestsPerSession; i++) {
        await service.ask('Pertanyaan unik ke-$i');
      }

      expect(service.sessionRequestCount, AiService.maxRequestsPerSession);

      // Panggilan ke-21 harus melempar error rate limit
      expect(
        () => service.ask('Pertanyaan ke-21'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Batas request per sesi'),
        )),
      );
    });
  });

  group('ChatScreen Widget Tests', () {
    testWidgets('Merender tampilan awal ChatScreen dengan banner privasi dan input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      // Verifikasi judul AppBar
      expect(find.text('Tanya AI Kampus'), findsOneWidget);

      // Verifikasi banner privasi
      expect(find.textContaining('Privasi: Jangan kirim NIK'), findsOneWidget);

      // Verifikasi greeting awal
      expect(find.text('Halo! Saya asisten AI kampus.'), findsOneWidget);

      // Verifikasi TextField input dan tombol kirim
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('Menampilkan bubble pesan pengguna setelah dikirim', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Kapan libur semester?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('Kapan libur semester?'), findsOneWidget);
    });
  });
}
