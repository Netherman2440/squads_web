/// Base class for all failures in the application.
abstract class Failure implements Exception {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

// --- General Failures ---

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

// --- Auth Specific Failures ---

abstract class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid email or password.');
}

class UserNotConfirmedFailure extends AuthFailure {
  const UserNotConfirmedFailure() : super('Email not confirmed. Please check your inbox.');
}

class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure() : super('User with this email already exists.');
}

class GuestLoginFailure extends AuthFailure {
  const GuestLoginFailure() : super('Failed to sign in as guest.');
}

class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure([super.message = 'You do not have permission to access this resource.']);
}
