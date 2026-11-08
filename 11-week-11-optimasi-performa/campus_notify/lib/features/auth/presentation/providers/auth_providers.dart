import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers.dart';
import '../../domain/usecases/login.dart';

/// Wiring use case Login.
final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);

/// State autentikasi global — true bila ada access token tersimpan.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(authRepositoryProvider).hasSession();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final r = await ref
          .read(loginProvider)
          .call(email: email, password: password);
      if (r.failure != null) throw Exception(r.failure!.message);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidateSelf();
  }
}
