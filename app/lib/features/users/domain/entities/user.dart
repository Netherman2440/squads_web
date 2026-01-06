class User {
  final String id;
  final String email;
  final String fullName;

  const User({required this.id, required this.email, required this.fullName});

  User copyWith({String? id, String? email, String? fullName}) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
    );
  }
}
