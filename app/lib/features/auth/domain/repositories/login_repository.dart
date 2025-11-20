import '../entities/auth_entity.dart';

abstract class LoginRepository {
  Future<AuthEntity?> login(String email, String password);
  Future<AuthEntity?> register(String email, String password);
  Future<AuthEntity?> guestLogin();
  Future<AuthEntity?> refreshSession(String? refreshToken);
}
