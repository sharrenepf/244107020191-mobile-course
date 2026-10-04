import 'dart:typed_data';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TokenStore palsu di memori (tanpa secure storage asli).
class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// Adapter palsu: token 'old' -> 401, token lain -> 200.
class _Adapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (options.headers['Authorization'] == 'Bearer old') {
      return ResponseBody.fromString('{}', 401, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
    }
    return ResponseBody.fromString('{"ok":true}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Repository yang refresh-nya selalu gagal.
class _DeadAuth extends AuthRepository {
  @override
  Future<String> refresh(String refreshToken) async =>
      throw Exception('refresh mati');
}

void main() {
  test('routeFromMessage menangani route kosong dan tanpa slash', () {
    expect(routeFromMessage({}), '/');
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
  });

  test('data payload membawa id pengumuman', () {
    const data = {'route': '/pengumuman/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), AppRoutes.announcementPath('3'));
  });

  test('provider auth: login menyimpan token, logout membersihkan', () async {
    final store = FakeTokenStore();
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    expect(await container.read(authStateProvider.future), isFalse);

    await container
        .read(authStateProvider.notifier)
        .login('a@b.com', '123456');
    expect(container.read(authStateProvider).value, isTrue);
    expect(store.access, isNotNull);

    await container.read(authStateProvider.notifier).logout();
    expect(await container.read(authStateProvider.future), isFalse);
    expect(store.access, isNull);
  });

  test('login tidak valid -> error dan token tidak tersimpan', () async {
    final store = FakeTokenStore();
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(authStateProvider.future);
    await container.read(authStateProvider.notifier).login('salah', '1');
    expect(container.read(authStateProvider).hasError, isTrue);
    expect(store.access, isNull);
  });

  test('401 -> refresh sekali -> request diulang dan sukses', () async {
    final store = FakeTokenStore()
      ..access = 'old'
      ..refresh = 'r1';
    final adapter = _Adapter();
    final dio = buildApiClient(store, AuthRepository());
    dio.httpClientAdapter = adapter;

    final res = await dio.get('/profil');
    expect(res.statusCode, 200);
    expect(store.access, startsWith('mock-access-renewed-'));
    expect(adapter.calls, 2); // request awal (401) + ulang (200)
  });

  test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () async {
    final store = FakeTokenStore()
      ..access = 'old'
      ..refresh = 'r1';
    final dio = buildApiClient(store, _DeadAuth());
    dio.httpClientAdapter = _Adapter();

    await expectLater(dio.get('/profil'), throwsA(isA<DioException>()));
    expect(store.access, isNull);
    expect(store.refresh, isNull);
  });

  test('friendlyError memetakan 401 dan offline ke pesan ramah', () {
    final req = RequestOptions(path: '/x');
    final err401 = DioException(
      requestOptions: req,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: req, statusCode: 401),
    );
    expect(friendlyError(err401), 'Sesi berakhir. Silakan login ulang.');

    final offline = DioException(
      requestOptions: req,
      type: DioExceptionType.connectionError,
    );
    expect(friendlyError(offline), 'Tidak ada koneksi internet.');

    final timeout = DioException(
      requestOptions: req,
      type: DioExceptionType.receiveTimeout,
    );
    expect(friendlyError(timeout), 'Koneksi timeout. Coba lagi beberapa saat.');
  });
}