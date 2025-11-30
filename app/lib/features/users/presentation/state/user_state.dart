import 'package:app/features/users/application/user_profile_summary.dart';

class UserState {
  final bool isLoading;
  final UserProfileSummary? profile;
  final String? error;

  const UserState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  UserState copyWith({
    bool? isLoading,
    UserProfileSummary? profile,
    String? error,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}


