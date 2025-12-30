import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();

  Future<void> updateUser(User user);

  /// Fetch multiple users by their ids.
  Future<List<User>> getUsers(List<String> userIds);

  /// Create or update a public.users entry for the given user.
  Future<void> upsertUser(User user);
}
