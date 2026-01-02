import 'dart:convert';
import 'dart:html' as html;

import '../../domain/repositories/invite_code_storage.dart';

class InviteCodeStorageImpl implements InviteCodeStorage {
  static const _storageKey = 'squad_invite_code';

  @override
  Future<void> saveCode(String code, Duration ttl) async {
    final expiresAt = DateTime.now().add(ttl).toUtc().toIso8601String();
    final payload = jsonEncode({'code': code, 'expiresAt': expiresAt});
    html.window.sessionStorage[_storageKey] = payload;
  }

  @override
  Future<String?> readCode() async {
    final raw = html.window.sessionStorage[_storageKey];
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
    html.window.sessionStorage.remove(_storageKey);
  }
}
