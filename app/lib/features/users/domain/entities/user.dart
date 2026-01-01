class User {
  final String id;
  final String email;

  const User({required this.id, required this.email});

  User copyWith({String? id, String? email}) {
    return User(id: id ?? this.id, email: email ?? this.email);
  }
}
