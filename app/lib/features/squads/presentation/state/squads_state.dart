import '../../domain/entities/squad.dart';

class SquadsState {
  final bool isLoading;
  final List<Squad> squads;
  final String? error;

  const SquadsState({
    this.isLoading = false,
    this.squads = const [],
    this.error,
  });

  SquadsState copyWith({
    bool? isLoading,
    List<Squad>? squads,
    String? error,
  }) =>
      SquadsState(
        isLoading: isLoading ?? this.isLoading,
        squads: squads ?? this.squads,
        error: error,
      );
}
