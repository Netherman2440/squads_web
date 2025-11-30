import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();

  Future<void> updateUser(User user);
}

