import 'package:supabase_flutter/supabase_flutter.dart';

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

class AuthFailure {
  final String message;
  final String code;

  const AuthFailure({
    required this.message,
    required this.code,
  });

  static const AuthFailure invalidCredentials = AuthFailure(
    message: 'Invalid email or password',
    code: 'invalid_credentials',
  );

  static const AuthFailure emailNotConfirmed = AuthFailure(
    message: 'Please check your email and click the confirmation link',
    code: 'email_not_confirmed',
  );

  static const AuthFailure userAlreadyExists = AuthFailure(
    message: 'An account with this email already exists',
    code: 'user_already_registered',
  );

  static const AuthFailure networkError = AuthFailure(
    message: 'Network connection error. Please try again',
    code: 'network_error',
  );

  static const AuthFailure registrationFailed = AuthFailure(
    message: 'Registration failed. Please try again',
    code: 'registration_failed',
  );

  static const AuthFailure guestLoginFailed = AuthFailure(
    message: 'Guest login failed. Please try again',
    code: 'guest_login_failed',
  );

  static AuthFailure fromSupabaseError(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          if (error.message.contains('Invalid login credentials')) {
            return invalidCredentials;
          } else if (error.message.contains('Email not confirmed')) {
            return emailNotConfirmed;
          }
          break;
        case '409':
          return userAlreadyExists;
        case '422':
          if (error.message.contains('User already registered')) {
            return userAlreadyExists;
          }
          break;
      }
    }
    return AuthFailure(
      message: 'An unexpected error occurred',
      code: 'unknown_error',
    );
  }
}
