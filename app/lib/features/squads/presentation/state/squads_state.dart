import '../../domain/entities/squad.dart';

class SquadsState {
  final bool isLoading;
  final List<Squad> squads;
  final String? error;

  static const Object _undefined = Object();

  const SquadsState({
    this.isLoading = false,
    this.squads = const [],
    this.error,
  });

  SquadsState copyWith({
    bool? isLoading,
    List<Squad>? squads,
    Object? error = _undefined,
  }) =>
      SquadsState(
        isLoading: isLoading ?? this.isLoading,
        squads: squads ?? this.squads,
        error: identical(error, _undefined) ? this.error : error as String?,
      );
}
