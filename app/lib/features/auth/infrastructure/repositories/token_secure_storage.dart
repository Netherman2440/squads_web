import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/token_repository.dart';


class TokenSecureStorage implements TokenRepository {
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger('TokenSecureStorage');
  static const String _key = 'auth_entity';

  TokenSecureStorage(this._storage);

  @override
  Future<void> setTokens({
    String? accessToken,
    String? refreshToken,
    String? userId,
    bool? isAnonymous,
    String? email,
  }) async {
    try {
      final entity = AuthEntity(
        accessToken: accessToken ?? '',
        refreshToken: refreshToken ?? '',
        userId: userId ?? '',
        isAnonymous: isAnonymous ?? false,
        email: email ?? '',
      );

      final jsonString = jsonEncode(entity.toJson());
      await _storage.write(key: _key, value: jsonString);
      _logger.info('Tokens stored successfully for user: $userId');
    } catch (e) {
      _logger.severe('Failed to store tokens: $e');
      rethrow;
    }
  }
  @override
  Future<void> setTokensFromEntity(AuthEntity entity) async {
    await setTokens(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      userId: entity.userId,
      isAnonymous: entity.isAnonymous,
      email: entity.email,
    );
  }

  @override
  Future<AuthEntity?> getTokens() async {
    try {
      final jsonString = await _storage.read(key: _key);
      if (jsonString == null) {
        _logger.info('No stored tokens found');
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final entity = AuthEntity.fromJson(jsonMap);
      _logger.info('Tokens retrieved successfully for user: ${entity.userId}');
      return entity;
    } catch (e) {
      _logger.severe('Failed to retrieve tokens: $e');
      // Clear corrupted data
      await clearTokens();
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _key);
      _logger.info('Tokens cleared successfully');
    } catch (e) {
      _logger.severe('Failed to clear tokens: $e');
    }
  }
}

final tokenSecureStorageProvider = Provider<TokenSecureStorage>((ref) {
  final storage = FlutterSecureStorage();
  return TokenSecureStorage(storage);
});