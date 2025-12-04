class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final bool isAnonymous;
  final String email;

  AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.isAnonymous,
    required this.email,
  });

  AuthEntity copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    bool? isAnonymous,
    String? email,
  }) => AuthEntity(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    userId: userId ?? this.userId,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    email: email ?? this.email,
  );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'isAnonymous': isAnonymous,
        'email': email,
      };

  factory AuthEntity.fromJson(Map<String, dynamic> json) => AuthEntity(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userId: json['userId'] as String,
        isAnonymous: json['isAnonymous'] as bool,
        email: json['email'] as String,
      );

}

