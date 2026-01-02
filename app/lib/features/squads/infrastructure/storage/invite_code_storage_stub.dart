import '../../domain/repositories/invite_code_storage.dart';

class InviteCodeStorageImpl implements InviteCodeStorage {
  String? _code;
  DateTime? _expiresAt;

  @override
  Future<void> saveCode(String code, Duration ttl) async {
    _code = code;
    _expiresAt = DateTime.now().add(ttl);
  }

  @override
  Future<String?> readCode() async {
    if (_code == null || _expiresAt == null) {
      return null;
    }

    if (_expiresAt!.isBefore(DateTime.now())) {
      await clear();
      return null;
    }

    return _code;
  }

  @override
  Future<void> clear() async {
    _code = null;
    _expiresAt = null;
  }
}
