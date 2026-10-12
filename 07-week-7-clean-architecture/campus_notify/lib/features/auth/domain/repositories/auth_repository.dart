import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

/// Kontrak abstrak yang tinggal di domain.
/// Hanya diketahui presentation; data layer mengimplementasikannya.
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? access, Failure? failure})> refresh(String refreshToken);

  Future<bool> hasSession();

  Future<void> logout();
}
