import '../entities/auth_entity.dart';

abstract class TokenRepository {
  Future<void> setTokens({
    String? accessToken,
    String? refreshToken,
    String? userId,
    bool? isAnonymous,
    String? email,
  });

  Future<void> setTokensFromEntity(AuthEntity entity);

  Future<AuthEntity?> getTokens();

  Future<void> clearTokens();
}
