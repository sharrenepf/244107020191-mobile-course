import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case Login: validasi email/password adalah aturan bisnis,
/// bukan tanggung jawab repository atau widget.
class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    if (!email.contains('@') || password.length < 6) {
      return Future.value((
        session: null,
        failure: const AuthFailure('Email atau kata sandi tidak valid'),
      ));
    }
    return _repository.login(email: email, password: password);
  }
}
