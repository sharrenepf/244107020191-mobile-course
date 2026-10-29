import '../../../../core/failures.dart';
import '../../../../shared/data/token_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi AuthRepository menggunakan TokenStore (shared/data).
/// Semua detail teknis penyimpanan token ada di sini — domain tidak tahu.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._store);
  final TokenStore _store;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Mock: ganti dengan FirebaseAuth.instance.signInWithEmailAndPassword saat siap.
      await Future.delayed(const Duration(milliseconds: 500));
      final session = AuthSession(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
      );
      await _store.save(access: session.access, refresh: session.refresh);
      return (session: session, failure: null);
    } catch (e) {
      return (
        session: null,
        failure: AuthFailure('Gagal login: $e'),
      );
    }
  }

  @override
  Future<({String? access, Failure? failure})> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) {
      return (access: null, failure: const AuthFailure('Refresh token hilang'));
    }
    return (
      access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
      failure: null,
    );
  }

  @override
  Future<bool> hasSession() async => (await _store.readAccess()) != null;

  @override
  Future<void> logout() => _store.clear();
}
