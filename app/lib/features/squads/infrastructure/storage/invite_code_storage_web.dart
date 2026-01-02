import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/invite_code_storage.dart';

class InviteCodeStorageImpl implements InviteCodeStorage {
  static const _storageKey = 'squad_invite_code';

  @override
  Future<void> saveCode(String code, Duration ttl) async {
    final expiresAt = DateTime.now().toUtc().add(ttl).toIso8601String();
    final payload = jsonEncode({'code': code, 'expiresAt': expiresAt});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, payload);
  }

  @override
  Future<String?> readCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return null;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.tryParse(data['expiresAt'] as String? ?? '');
      final code = data['code'] as String?;

      if (code == null || expiresAt == null) {
        await clear();
        return null;
      }

      if (expiresAt.isBefore(DateTime.now().toUtc())) {
        await clear();
        return null;
      }

      return code;
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
