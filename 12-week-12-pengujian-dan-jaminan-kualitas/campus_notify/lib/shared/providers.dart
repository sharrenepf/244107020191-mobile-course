import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import 'data/api_client.dart';
import 'data/token_store.dart';

/// Satu-satunya tempat wiring infrastruktur lintas fitur.
/// Widget TIDAK boleh new TokenStore(), new AuthRepositoryImpl(), dsb.

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(tokenStoreProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  ),
);
