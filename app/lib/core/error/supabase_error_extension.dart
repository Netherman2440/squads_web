import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

extension SupabaseErrorExtension on Object {
  /// Converts Supabase/Network exceptions into Domain Failures
  Failure toFailure() {
    final error = this;

    if (error is AuthException) {
      // Map Supabase Auth Status Codes
      // Reference: https://supabase.com/docs/guides/auth/errors

      final message = error.message.toLowerCase();

      if (error is AuthRetryableFetchException ||
          message.contains('failed to fetch') ||
          message.contains('clientexception')) {
        return const NetworkFailure(
          'Unable to reach the authentication server. Please check your connection.',
        );
      }

      if (error.message.contains('Invalid login credentials')) {
        return const InvalidCredentialsFailure();
      }

      if (error.message.contains('Email not confirmed')) {
        return const UserNotConfirmedFailure();
      }

      // 400 often covers multiple cases, relying on message check above is safer for Auth
      // 422 or 409 usually means user already exists in sign-up context
      if (error.statusCode == '422' ||
          error.statusCode == '409' ||
          error.message.contains('User already registered')) {
        return const UserAlreadyExistsFailure();
      }

      return ServerFailure(error.message, error.statusCode);
    }

    if (error is PostgrestException) {
      // PGRST116: JSON object requested, multiple (or no) rows returned
      // Often happens on .single() when no record is found.
      // We treat this as a ServerFailure with specific message, or could add NotFoundFailure.
      if (error.code == 'PGRST116') {
        return const ServerFailure('Resource not found.', 'PGRST116');
      }

      // 42501: RLS Violation
      if (error.code == '42501') {
        return const UnauthorizedFailure();
      }

      return ServerFailure(error.message, error.code);
    }

    if (error is SocketException) {
      return const NetworkFailure();
    }

    // Fallback for unknown errors
    return const UnknownFailure();
  }
}
