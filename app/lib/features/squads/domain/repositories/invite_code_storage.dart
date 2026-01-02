abstract class InviteCodeStorage {
  Future<void> saveCode(String code, Duration ttl);

  /// Returns a stored code if it has not expired. Expired codes are cleared.
  Future<String?> readCode();

  Future<void> clear();
}
